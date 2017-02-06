require 'puppet/parameter/boolean'

Puppet::Type.newtype(:lan) do
  @doc = 'Type representing a ProfitBricks LAN.'

  newproperty(:ensure) do
    newvalue(:present) do
      provider.create unless provider.exists?
    end

    newvalue(:absent) do
      provider.destroy if provider.exists?
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the LAN.'
    validate do |value|
      fail('The name should be a String') unless value.is_a?(String)
    end
  end

  newproperty(:public) do
    desc 'Set whether LAN will face the public Internet or not.'
    defaultto :false
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:datacenter_id) do
    desc 'The ID of the virtual data center where the LAN will reside.'
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the LAN will reside.'
  end

  autorequire(:datacenter) do
    self[:datacenter_name]
  end
end
