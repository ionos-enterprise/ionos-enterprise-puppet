require 'spec_helper'

provider_class = Puppet::Type.type(:server).provider(:v1)

ENV['PROFITBRICKS_USERNAME'] = 'username'
ENV['PROFITBRICKS_PASSWORD'] = 'password'

describe provider_class do

  context 'with the minimum params' do
    before(:all) do
      @rest_url = 'https://username:password@api.profitbricks.com/rest'
      @headers = { Authorization: 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=' }

      @resource = Puppet::Type.type(:server).new(
        datacenter_id: '12345',
        name: 'server1',
        cores: 1,
        ram: 1024
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Server::ProviderV1
    end

    context 'exists?' do
      it 'should correctly report non-existent servers' do
        stub_request(:get, "#{@rest_url}/datacenters/12345/servers?depth=1")
          .to_return(body: '{items[{"properties":{"name":"server2"}}]}')
        expect(@provider.exists?).to be false
      end
    end

    context 'create' do
      it 'should send a request to the ProfitBricks API to create server' do
        stub_request(:post, "#{@rest_url}/datacenters/12345/servers?depth=1").
          with(
            body: '{"properties":{"name":"server1","cores":1,"ram":1024,"availabilityZone":"AUTO","bootVolume":null,"bootCdrom":null},"entities":{"volumes":null,"nics":null}}',
            headers: @headers
          ).
          to_return(
            status: 202,
            body: '{"id":"54321","href":"https://api.profitbricks.com/rest/datacenters/12345/servers","properties":{"name":"server1","cores":1,"ram":1024,"availabilityZone":"AUTO","bootVolume":null,"bootCdrom":null,"entities":{"volumes":null,"nics":null}}}',
            headers: {Location: "https://api.profitbricks.com/rest/requests/123/status"}
          )
        stub_wait_for(@rest_url, @headers)
        @provider.create
      end
    end
  end
end
