require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:image).provide(:v1) do
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

    images = []
    Image.list.each do |i|
      hash = instance_to_hash(i)
      images << new(hash)
    end
    images.flatten
  end

  def self.instance_to_hash(instance)
    config = {
      id: instance.id,
      name: instance.properties['name'],
      description: instance.properties['description'],
      location: instance.properties['location'],
      size: instance.properties['size'],
      cpu_hot_plug: instance.properties['cpuHotPlug'],
      cpu_hot_unplug: instance.properties['cpuHotUnplug'],
      ram_hot_plug: instance.properties['ramHotPlug'],
      ram_hot_unplug: instance.properties['ramHotUnplug'],
      nic_hot_plug: instance.properties['nicHotPlug'],
      nic_hot_unplug: instance.properties['nicHotUnplug'],
      disc_virtio_hot_plug: instance.properties['discVirtioHotPlug'],
      disc_virtio_hot_unplug: instance.properties['discVirtioHotUnplug'],
      disc_scsi_hot_plug: instance.properties['discScsiHotPlug'],
      disc_scsi_hot_unplug: instance.properties['discScsiHotUnplug'],
      public: instance.properties['public'],
      image_type: instance.properties['imageType'],
      licence_type: instance.properties['licenceType'],
      image_aliases: instance.properties['imageAliases']
    }
    config
  end
end
