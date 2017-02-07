
Puppet::Type.newtype(:datacenter) do
  @doc = 'Type representing a ProfitBricks virtual data center.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the virtual data center where the server will reside.'
    validate do |value|
      raise('The name should be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:id) do
    desc 'The data center ID.'
  end

  newproperty(:description) do
    desc 'The data center description.'
  end

  newproperty(:location) do
    desc 'The data center location.'
    validate do |value|
      fail('Data center location must be set') if value == ''
      fail('Data center location must be a String') unless value.is_a?(String)
    end
  end
end