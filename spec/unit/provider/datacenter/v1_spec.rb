require 'spec_helper'

provider_class = Puppet::Type.type(:datacenter).provider(:v1)

ENV['PROFITBRICKS_USERNAME'] = 'username'
ENV['PROFITBRICKS_PASSWORD'] = 'password'

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @rest_url = 'https://username:password@api.profitbricks.com/rest'
      @headers = { Authorization: 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=' }

      @resource = Puppet::Type.type(:datacenter).new(
        name: 'dummydc',
        location: 'xyz'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Datacenter::ProviderV1
    end

    context 'exists?' do
      it 'should correctly report non-existent data center' do
        stub_request(:get, "#{@rest_url}/datacenters?depth=1")
          .to_return(body: '{items[{"properties":{"name":"abcdc"}}]}')
        expect(@provider.exists?).to be false
      end
    end
  end
end
