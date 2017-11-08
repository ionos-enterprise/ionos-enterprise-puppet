require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:snapshot).provide(:v1) do
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

    snapshots = []
    Snapshot.list.each do |snapshot|
      hash = instance_to_hash(snapshot)
      snapshots << new(hash)
    end
    snapshots.flatten
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
      size: instance.properties['size'],
      location: instance.properties['location'],
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
      licence_type: instance.properties['licenceType'],
      ensure: :present
    }
    config
  end

  def restore=(value)
    # restore setter is only invoked on restore => true
    vol = get_volume()
    Puppet.info("Restoring snapshot '#{name}' onto volume '#{resource[:volume]}'...")
    vol.restore_snapshot(id)
  end

  def description=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating description property of snapshot '#{name}'...")
    snapshot.update(description: value)
    snapshot.wait_for { ready? }
  end

  def cpu_hot_plug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating cpuHotPlug property of snapshot '#{name}'...")
    snapshot.update(cpuHotPlug: value)
    snapshot.wait_for { ready? }
  end

  def cpu_hot_unplug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating cpuHotUnplug property of snapshot '#{name}'...")
    snapshot.update(cpuHotUnplug: value)
    snapshot.wait_for { ready? }
  end

  def ram_hot_plug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating ramHotPlug property of snapshot '#{name}'...")
    snapshot.update(ramHotPlug: value)
    snapshot.wait_for { ready? }
  end

  def ram_hot_unplug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating ramHotUnplug property of snapshot '#{name}'...")
    snapshot.update(ramHotUnplug: value)
    snapshot.wait_for { ready? }
  end

  def nic_hot_plug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating nicHotPlug property of snapshot '#{name}'...")
    snapshot.update(nicHotPlug: value)
    snapshot.wait_for { ready? }
  end

  def nic_hot_unplug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating nicHotUnplug property of snapshot '#{name}'...")
    snapshot.update(nicHotUnplug: value)
    snapshot.wait_for { ready? }
  end

  def disc_virtio_hot_plug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating discVirtioHotPlug property of snapshot '#{name}'...")
    snapshot.update(discVirtioHotPlug: value)
    snapshot.wait_for { ready? }
  end

  def disc_virtio_hot_unplug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating discVirtioHotUnplug property of snapshot '#{name}'...")
    snapshot.update(discVirtioHotUnplug: value)
    snapshot.wait_for { ready? }
  end

  def disc_scsi_hot_plug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating discScsiHotPlug property of snapshot '#{name}'...")
    snapshot.update(discScsiHotPlug: value)
    snapshot.wait_for { ready? }
  end

  def disc_scsi_hot_unplug=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating discScsiHotUnplug property of snapshot '#{name}'...")
    snapshot.update(discScsiHotUnplug: value)
    snapshot.wait_for { ready? }
  end

  def licence_type=(value)
    snapshot = Snapshot.get(id)
    Puppet.info("Updating licenceType property of snapshot '#{name}'...")
    snapshot.update(licenceType: value)
    snapshot.wait_for { ready? }
  end

  def exists?
    Puppet.info("Checking if snapshot '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    volume = get_volume()

    snapshot = volume.create_snapshot(
      name: resource[:name],
      description: resource[:description]
    )

    snapshot.wait_for { ready? }

    Puppet.info("Created new snapshot '#{name}'.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = snapshot.id
  end

  def destroy
    snapshot = Snapshot.get(id)
    Puppet.info("Deleting snapshot '#{name}'...")
    snapshot.delete
    snapshot.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def get_volume()
    fail "Data center ID or name must be provided." if resource[:datacenter].nil?
    fail "Volume ID or name must be provided." if resource[:volume].nil?

    reg = Regexp.new('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')

    if reg.match(resource[:datacenter])
      dc_id = resource[:datacenter]
      begin
        Datacenter.get(dc_id)
      rescue StandardError
        dc_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(nil, resource[:datacenter])
      end
    else
      dc_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(nil, resource[:datacenter])
    end

    if reg.match(resource[:volume])
      volume = Volume.get(dc_id, resource[:volume])
      begin
        volume = Volume.get(dc_id, resource[:volume])
      rescue StandardError
        volume = Volume.list(dc_id).find { |volume| volume.properties['name'] == resource[:volume] }
      end
    else
      volume = Volume.list(dc_id).find { |volume| volume.properties['name'] == resource[:volume] }
    end
    unless volume
      fail "No volume with ID/name '#{resource[:volume]}'  was found in '#{resource[:datacenter]}' data center."
    end
    volume
  end
end
