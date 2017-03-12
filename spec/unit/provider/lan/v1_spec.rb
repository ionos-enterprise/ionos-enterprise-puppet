require 'spec_helper'

provider_class = Puppet::Type.type(:lan).provider(:v1)

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:lan).new(
        datacenter_name: 'dummydc',
        name: 'lan1'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Lan::ProviderV1
    end

    context 'create' do
      it 'should create ProfitBricks LAN' do
        VCR.use_cassette('lan_create') do
          expect(@provider.create).to be_truthy
          expect(@provider.exists?).to be true
        end
      end
    end
  end
end
