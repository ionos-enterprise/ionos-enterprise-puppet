require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:location).provide(:v1) do
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

    locations = []
    Location.list.each do |l|
      hash = instance_to_hash(l)
      locations << new(hash)
    end
    locations.flatten
  end

  def self.instance_to_hash(instance)
    config = {
      id: instance.id,
      name: instance.properties['name'],
      features: instance.properties['features'],
      image_aliases: instance.properties['imageAliases']
    }
    config
  end
end
