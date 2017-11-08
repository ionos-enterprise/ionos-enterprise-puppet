Puppet::Type.newtype(:location) do
  @doc = 'Type representing a ProfitBricks location.'

  newparam(:name, namevar: true) do
    desc 'The name of the location.'
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the location.'

    def insync?(is)
      true
    end
  end

  newproperty(:features, array_matching: :all) do
    desc 'A list of features available at the location.'

    def insync?(is)
      true
    end
  end

  newproperty(:image_aliases, array_matching: :all) do
    desc 'A list of image aliases available at the location.'

    def insync?(is)
      true
    end
  end
end
