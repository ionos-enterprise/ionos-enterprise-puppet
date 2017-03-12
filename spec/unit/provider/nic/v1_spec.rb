require 'spec_helper'

provider_class = Puppet::Type.type(:nic).provider(:v1)

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:nic).new(
        name: 'testnic',
        lan: 'lan1',
        datacenter_name: 'dummydc',
        server_name: 'testserver',
        firewall_active: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Nic::ProviderV1
    end

    context 'create' do
      it 'should create ProfitBricks NIC' do
        VCR.use_cassette('nic_create') do
          expect(@provider.create).to be_truthy
          expect(@provider.exists?).to be true
        end
      end
    end
  end
end
