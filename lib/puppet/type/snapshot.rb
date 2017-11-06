require 'puppet/parameter/boolean'

Puppet::Type.newtype(:snapshot) do
  @doc = 'Type representing a ProfitBricks Snapshot.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the snapshot.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:restore) do
    desc 'If true, restore the snapshot onto the volume specified be the volume property.'
    newvalues(:true, :false)
    def insync?(is)
      should.to_s != 'true'
    end
  end

  newproperty(:datacenter) do
    desc 'The ID or name of the virtual data center where the volume resides.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, 'The data center ID/name should be a String.'
      end
    end
  end

  newproperty(:volume) do
    desc 'The ID or name of the volume used to create/restore the snapshot.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, 'The volume ID/name should be a String.'
      end
    end
  end

  newproperty(:description) do
    desc "The snapshot's description."
  end

  newproperty(:cpu_hot_plug) do
    desc 'Indicates CPU hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:cpu_hot_unplug) do
    desc 'Indicates CPU hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:ram_hot_plug) do
    desc 'Indicates memory hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:ram_hot_unplug) do
    desc 'Indicates memory hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:nic_hot_plug) do
    desc 'Indicates NIC hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:nic_hot_unplug) do
    desc 'Indicates NIC hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_virtio_hot_plug) do
    desc 'Indicates VirtIO drive hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_virtio_hot_unplug) do
    desc 'Indicates VirtIO drive hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_scsi_hot_plug) do
    desc 'Indicates SCSI drive hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_scsi_hot_unplug) do
    desc 'Indicates SCSI drive hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:licence_type) do
    desc 'The license type of the snapshot.'
  end

  # read-only properties

  newproperty(:id) do
    desc "The snapshot's ID."

    def insync?(is)
      true
    end
  end

  newproperty(:location) do
    desc "The snapshot's location."

    def insync?(is)
      true
    end
  end

  newproperty(:size) do
    desc 'The size of the snapshot in GB.'

    def insync?(is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter]
  end
  autorequire(:volume) do
    self[:volume]
  end
end
