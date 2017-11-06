require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:lan).provide(:v1) do
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
      lans = []
      # Ignore data center if name is not defined.
      unless datacenter.properties['name'].nil? || datacenter.properties['name'].empty?
        LAN.list(datacenter.id).each do |lan|
          # Ignore LAN if name is not defined.
          unless lan.properties['name'].nil? || lan.properties['name'].empty?
            hash = instance_to_hash(lan, datacenter)
            lans << new(hash)
          end
        end
      end
      lans
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
      ip_failover: instance.properties['ipFailover'],
      public: instance.properties['public'],
      ensure: :present
    }
    config
  end

  def public=(value)
    lan = lan_from_name(
      name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    )

    Puppet.info("Updating LAN '#{name}' public property.")
    lan.update(public: value.to_s == 'true' ? true : false)
    lan.wait_for { ready? }
  end

  def ip_failover=(value)
    lan = lan_from_name(
      name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    )

    ip_fo = value.map do |g|
      {
        ip: g['ip'],
        nicUuid: g['nic_uuid']
      }
    end

    Puppet.info("Updating LAN '#{name}' IP failover group.")
    lan.update(ipFailover: ip_fo)
    lan.wait_for { ready? }
  end

  def exists?
    Puppet.info("Checking if LAN #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    lan = LAN.create(
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]),
      name: name,
      public: resource[:public] || false
    )

    begin
      lan.wait_for(3).wait_for { ready? }
    rescue StandardError
      request = request_error(lan)
      if request['status'] == 'FAILED'
        fail "Failed to create LAN: #{request['message']}"
      end
    end

    Puppet.info("Creating a new LAN called #{name}.")
    @property_hash[:ensure] = :present
  end

  def destroy
    lan = lan_from_name(resource[:name],
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))
    Puppet.info("Deleting LAN #{name}.")
    lan.delete
    lan.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def request_error(lan)
    Request.get(lan.requestId).status.metadata if lan.requestId
  end

  def lan_from_name(name, datacenter_id)
    LAN.list(datacenter_id).find { |lan| lan.properties['name'] == name }
  end
end
