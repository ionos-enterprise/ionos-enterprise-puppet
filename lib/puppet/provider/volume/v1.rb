require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:volume).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    PuppetX::Profitbricks::Helper::profitbricks_config
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config

    Datacenter.list.map do |datacenter|
      volumes = []
      # Ignore data center if name is not defined.
      unless datacenter.properties['name'].nil? || datacenter.properties['name'].empty?
        Volume.list(datacenter.id).each do |vol|
          unless vol.properties['name'].nil? || vol.properties['name'].empty?
            hash = instance_to_hash(vol, datacenter)
            volumes << new(hash)
          end
        end
      end
      volumes
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(instance, datacenter)
    config = {
      id: instance.id,
      datacenter_id: instance.datacenterId,
      datacenter_name: datacenter.properties['name'],
      name: instance.properties['name'],
      size: instance.properties['size'],
      volume_type: instance.properties['type'],
      bus: instance.properties['bus'],
      image_id: instance.properties['image'],
      licence_type: instance.properties['licenceType'],
      availability_zone: instance.properties['availabilityZone'],
      ensure: :present
    }
    config
  end

  def exists?
    Puppet.info("Checking if volume #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def size=(value)
    if @property_hash[:size] > value
      fail "Decreasing size of the volume is not allowed."
    else
      volume = volume_from_name(resource[:name],
        PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

      Puppet.info("Resizing volume #{name}.")
      volume.update(size: value)
      volume.wait_for { ready? }

      @property_hash[:size] = value
    end
  end

  def create
    volume = Volume.create(
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]),
      name: name,
      availabilityZone: resource[:availability_zone],
      image: resource[:image_id],
      imageAlias: resource[:image_alias],
      bus: resource[:bus],
      type: resource[:volume_type],
      size: resource[:size],
      licenceType: resource[:licence_type],
      imagePassword: resource[:image_password],
      sshKeys: resource[:ssh_keys]
    )

    begin
      volume.wait_for { ready? }
    rescue StandardError
      request = request_error(volume)
      if request['status'] == 'FAILED'
        fail "Failed to create volume: #{request['message']}"
      end
    end

    Puppet.info("Created a new volume named #{name}.")
    @property_hash[:ensure] = :present
    @property_hash[:size] = resource[:size]
  end

  def destroy
    volume = volume_from_name(resource[:name],
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Deleting volume #{name}.")
    volume.delete
    volume.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def request_error(instance)
    Request.get(instance.requestId).status.metadata if instance.requestId
  end

  def volume_from_name(name, datacenter_id)
    Volume.list(datacenter_id).find { |volume| volume.properties['name'] == name }
  end
end
