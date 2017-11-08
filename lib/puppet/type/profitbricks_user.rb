require 'puppet/parameter/boolean'

Puppet::Type.newtype(:profitbricks_user) do
  @doc = 'Type representing a ProfitBricks user.'

  ensurable

  newparam(:email, namevar: true) do
    desc "The user's e-mail address."
    validate do |value|
      raise ArgumentError, 'The email should be a String.' unless value.is_a?(String)
    end
  end

  newparam(:password) do
    desc 'A password for the user.'
    validate do |value|
      raise ArgumentError, 'The password should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:firstname) do
    desc "The user's first name."
    validate do |value|
      raise ArgumentError, 'The firstname should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:lastname) do
    desc "The user's last name."
    validate do |value|
      raise ArgumentError, 'The lastname should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:administrator) do
    desc 'Indicates whether or not the user have administrative rights.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:force_sec_auth) do
    desc 'Indicates if secure (two-factor) authentication should be forced for the user.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:groups, array_matching: :all) do
    desc 'The profitbricks groups the user is assigned to.'

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
    desc 'The user ID.'

    def insync?(is)
      true
    end
  end

  newproperty(:sec_auth_active) do
    desc 'Indicates if secure (two-factor) authentication is active for the user.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end
end
