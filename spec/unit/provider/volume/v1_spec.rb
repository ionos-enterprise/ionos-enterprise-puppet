require 'spec_helper'

provider_class = Puppet::Type.type(:volume).provider(:v1)

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:volume).new(
        name: 'testvolume',
        size: 50,
        licence_type: 'LINUX',
        datacenter_name: 'dummydc'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Volume::ProviderV1
    end

    context 'create' do
      it 'should create ProfitBricks volume' do
        VCR.use_cassette('volume_create') do
          expect(@provider.create).to be_truthy
          expect(@provider.exists?).to be true
        end
      end
    end
  end
end
