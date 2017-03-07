require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:datacenter).provide(:v1) do
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

    datacenters = []
    Datacenter.list.each do |dc|
      # Ignore data centers if name is not defined.
      unless dc.properties['name'].nil? || dc.properties['name'].empty?
        hash = instance_to_hash(dc)
        datacenters << new(hash)
      end
    end
    datacenters.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    config = {
      id: instance.id,
      name: instance.properties['name'],
      description: instance.properties['description'],
      location: instance.properties['location'],
      ensure: :present
    }
    config
  end

  def description=(value)
    datacenter = datacenter_from_name(name)
    Puppet.info("Updating data center '#{name}' description.")
    datacenter.update(description: value)
  end

  def exists?
    Puppet.info("Checking if data center #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    datacenter = Datacenter.create(
      name: name,
      description: resource[:description],
      location: resource[:location]
    )

    begin
      datacenter.wait_for(3).wait_for { ready? }
    rescue StandardError
      request = request_error(datacenter)
      if request['status'] == 'FAILED'
        fail "Failed to create data center: #{request['message']}"
      end
    end

    Puppet.info("Creating a new data center named #{name}.")
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.info("Deleting data center #{name}.")
    datacenter = datacenter_from_name(resource[:name])
    datacenter.delete
    datacenter.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def request_error(datacenter)
    Request.get(datacenter.requestId).status.metadata if datacenter.requestId
  end

  def datacenter_from_name(dc_name)
    datacenters = Datacenter.list
    dc_count = PuppetX::Profitbricks::Helper.count_by_name(dc_name, datacenters)

    fail "Found more than one data center named '#{dc_name}'." if dc_count > 1
    fail "Data center named '#{dc_name}' cannot be found." if dc_count == 0

    datacenters.find { |dc| dc.properties['name'] == dc_name }
  end
end
