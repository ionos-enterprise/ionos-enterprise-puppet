Puppet::Type.newtype(:image) do
  @doc = 'Type representing a ProfitBricks image.'

  newparam(:name, namevar: true) do
    desc 'The name of the image.'
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the image.'

    def insync?(is)
      true
    end
  end

  newproperty(:description) do
    desc "The image's description."

    def insync?(is)
      true
    end
  end

  newproperty(:location) do
    desc "The image's location."

    def insync?(is)
      true
    end
  end

  newproperty(:size) do
    desc 'The size of the image in GB.'

    def insync?(is)
      true
    end
  end

  newproperty(:cpu_hot_plug) do
    desc 'Indicates CPU hot plug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:cpu_hot_unplug) do
    desc 'Indicates CPU hot unplug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:ram_hot_plug) do
    desc 'Indicates memory hot plug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:ram_hot_unplug) do
    desc 'Indicates memory hot unplug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:nic_hot_plug) do
    desc 'Indicates NIC hot plug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:nic_hot_unplug) do
    desc 'Indicates NIC hot unplug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:disc_virtio_hot_plug) do
    desc 'Indicates VirtIO drive hot plug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:disc_virtio_hot_unplug) do
    desc 'Indicates VirtIO drive hot unplug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:disc_scsi_hot_plug) do
    desc 'Indicates SCSI drive hot plug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:disc_scsi_hot_unplug) do
    desc 'Indicates SCSI drive hot unplug capability.'

    def insync?(is)
      true
    end
  end

  newproperty(:public) do
    desc 'Indicates if the image is part of the public repository.'

    def insync?(is)
      true
    end
  end

  newproperty(:image_type) do
    desc 'The type of image.'

    def insync?(is)
      true
    end
  end

  newproperty(:licence_type) do
    desc 'The license type of the image.'

    def insync?(is)
      true
    end
  end

  newproperty(:image_aliases, array_matching: :all) do
    desc 'A list of image aliases available at the image.'

    def insync?(is)
      true
    end
  end
end
