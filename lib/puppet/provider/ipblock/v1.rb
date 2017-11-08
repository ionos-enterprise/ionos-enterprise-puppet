require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:ipblock).provide(:v1) do
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

    ipblocks = []
    IPBlock.list.each do |ipblock|
      hash = instance_to_hash(ipblock)
      ipblocks << new(hash)
    end
    ipblocks.flatten
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
      created_by: instance.metadata['createdBy'],
      name: instance.properties['name'],
      size: instance.properties['size'],
      location: instance.properties['location'],
      ips: instance.properties['ips'],
      ensure: :present
    }
    config
  end

  def exists?
    Puppet.info("Checking if ipblock '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    ipblock = IPBlock.create(
      name: resource[:name],
      size: resource[:size],
      location: resource[:location]
    )

    ipblock.wait_for { ready? }

    Puppet.info("Created new ipblock '#{name}'.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = ipblock.id
  end

  def destroy
    ipblock = IPBlock.get(id)
    Puppet.info("Deleting ipblock '#{name}'...")
    ipblock.delete
    @property_hash[:ensure] = :absent
  end
end
