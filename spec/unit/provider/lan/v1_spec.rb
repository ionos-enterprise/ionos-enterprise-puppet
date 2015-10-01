require 'spec_helper'

provider_class = Puppet::Type.type(:lan).provider(:v1)

ENV['PROFITBRICKS_USERNAME'] = 'username'
ENV['PROFITBRICKS_PASSWORD'] = 'password'

describe provider_class do

  context 'with the minimum params' do
    before(:all) do
      @rest_url = 'https://username:password@api.profitbricks.com/rest'
      @headers = { Authorization: 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=' }

      @resource = Puppet::Type.type(:lan).new(
        datacenter_id: '12345',
        name: 'lan1'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Lan::ProviderV1
    end

    context 'exists?' do
      it 'should correctly report non-existent servers' do
        stub_request(:get, "#{@rest_url}/datacenters/12345/lans?depth=1")
          .to_return(body: '{items[{"id":99999}]}')
        expect(@provider.exists?).to be false
      end
    end

    context 'create' do
      it 'should send a request to the ProfitBricks API to create LAN' do
        stub_request(:post, "#{@rest_url}/datacenters/12345/lans?depth=1").
          with(
            body: '{"properties":{"name":"lan1","public":"false"}}',
            headers: @headers
          ).
          to_return(
            status: 202,
            body: '{"href":"https://api.profitbricks.com/rest/datacenters/12345/lans","properties":{"name":"test"}}',
            headers: {Location: "https://api.profitbricks.com/rest/requests/123/status"}
          )
        stub_wait_for(@rest_url, @headers)
        @provider.create
      end
    end
  end
end
