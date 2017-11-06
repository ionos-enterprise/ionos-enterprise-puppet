require 'puppet/parameter/boolean'

Puppet::Type.newtype(:profitbricks_group) do
  @doc = 'Type representing a ProfitBricks group.'

  ensurable

  newparam(:name, namevar: true) do
    desc "The group name."
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:create_datacenter) do
    desc 'Indicates if the group is allowed to create virtual data centers.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:create_snapshot) do
    desc 'Indicates if the group is allowed to create snapshots.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:reserve_ip) do
    desc 'Indicates if the group is allowed to reserve IP addresses.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:access_activity_log) do
    desc 'Indicates if the group is allowed to access the activity log.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:members, array_matching: :all) do
    desc 'The profitbricks users associated with the group.'

    def insync?(is)
      if is.is_a? Array
        return is.sort == should.sort
      else
        return is == should
      end
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The group ID.'

    def insync?(is)
      true
    end
  end
end
