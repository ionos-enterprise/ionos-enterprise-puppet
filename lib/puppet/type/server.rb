require 'puppet/parameter/boolean'

Puppet::Type.newtype(:server) do
  @doc = 'Type representing a ProfitBricks server.'

  newproperty(:ensure) do
    newvalue(:present) do
      provider.create unless provider.running?
    end

    newvalue(:absent) do
      provider.destroy if provider.exists?
    end

    newvalue(:running) do
      provider.create unless provider.running?
    end

    newvalue(:stopped) do
      provider.stop unless provider.stopped?
    end

    def change_to_s(current, desired)
      current = :running if current == :present
      desired = :running if desired == :present
      current == desired ? current : "changed #{current} to #{desired}"
    end

    def insync?(is)
      is = :present if is == :running
      is = :stopped if is == :stopping
      is.to_s == should.to_s
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the server.'
    validate do |value|
      fail('Server must have a name') if value == ''
      fail('Name should be a String') unless value.is_a?(String)
    end
  end

  newproperty(:datacenter_id) do
    desc 'The virtual data center where the server will reside.'
    validate do |value|
      fail('Data center UUID must be set') if value == ''
      fail('Data center UUID must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:cores) do
    desc 'The number of CPU cores assigned to the server.' 
    validate do |value|
      fail('Server must have cores assigned') if value == ''
      fail('Cores must be a integer') unless value.is_a?(Integer)
    end
  end

  newproperty(:cpu_family) do
    desc 'The CPU family of the server.' 
    defaultto 'AMD_OPTERON'
    validate do |value|
      unless ['AMD_OPTERON', 'INTEL_XEON'].include?(value)
        fail('CPU family must be either "AMD_OPTERON" or "INTEL_XEON"')
      end
      fail('CPU family must be a string') unless value.is_a?(String)
    end
  end

  newproperty(:ram) do
    desc 'The amount of RAM in MB assigned to the server.' 
    validate do |value|
      fail('Server must have ram assigned') if value == ''
      fail('RAM must be a multiple of 256 MB') unless (value % 256) == 0
    end
  end

  newproperty(:availability_zone) do
    desc 'The availability zone of where the server will reside.' 
    defaultto 'AUTO'
  end

  newproperty(:licence_type) do
    desc 'The OS type of the server.' 
  end

  newproperty(:nat) do
    desc 'A boolean which indicates if the NIC will perform Network Address Translation.'
    defaultto :false
  end

  newproperty(:volumes, :array_matching => :all) do
    desc 'A list of volumes to associate with the server.'
    validate do |value|
      volumes = value.is_a?(Array) ? value : [value]
      fail('A single volume is supported at this time') unless volumes.count <= 1
      volumes.each do |volume|
        ['name', 'size', 'volume_type'].each do |key|
          fail("Volume must include #{key}") unless value.keys.include?(key)
        end
      end
    end

    def insync?(is)
      existing_volumes = is.collect { |volume| volume[:name] } 
      specified_volumes = should.collect { |volume| volume['name'] }
      existing_volumes.to_set == specified_volumes.to_set
    end
  end

  newproperty(:purge_volumes) do
    desc 'Sets whether attached volumes are removed when server is removed.'
    defaultto :false
    newvalues(:true, :'false')
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:nics, :array_matching => :all) do
    desc 'A list of network interfaces asociated with the server.' 
    validate do |value|
      nics = value.is_a?(Array) ? value : [value]
      nics.each do |nic|
        ['name', 'dhcp', 'lan'].each do |key|
          fail("NIC must include #{key}") unless value.keys.include?(key)
        end
        if nic.key?('ips')
          fail('NIC "ips" must be an Array') unless nic['ips'].is_a?(Array)
        end
      end
    end

    def insync?(is)
      existing_nics = is.collect { |nic| nic[:name] }
      specified_nics = should.collect { |nic| nic['name'] }
      existing_nics.to_set == specified_nics.to_set
    end
  end

  autorequire(:lan) do
    self[:datacenter_id]
  end
end
