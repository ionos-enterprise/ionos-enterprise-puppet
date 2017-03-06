require 'spec_helper'

provider_class = Puppet::Type.type(:firewall_rule).provider(:v1)

ENV['PROFITBRICKS_USERNAME'] = 'username'
ENV['PROFITBRICKS_PASSWORD'] = 'password'

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @rest_url = 'https://username:password@api.profitbricks.com/rest'
      @headers = { Authorization: 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=' }

      @resource = Puppet::Type.type(:firewall_rule).new(
        name: 'testrule',
        nic: 'testnic'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Firewall_rule::ProviderV1
    end
  end
end
