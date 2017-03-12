require 'spec_helper'

provider_class = Puppet::Type.type(:server).provider(:v1)

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:server).new(
        name: 'testserver',
        cores: 1,
        ram: 1024,
        datacenter_name: 'dummydc'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Server::ProviderV1
    end

    context 'create' do
      it 'should create ProfitBricks server' do
        VCR.use_cassette('server_create') do
          expect(@provider.create).to be_truthy
          expect(@provider.exists?).to be true
        end
      end
    end
  end
end
