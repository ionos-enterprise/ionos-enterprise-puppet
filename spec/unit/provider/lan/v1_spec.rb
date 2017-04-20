require 'spec_helper'

provider_class = Puppet::Type.type(:lan).provider(:v1)

describe provider_class do
  context 'LAN operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:lan).new(
        datacenter_name: 'dummydc',
        name: 'lan1'
      )
      @provider1 = provider_class.new(@resource1)

      @resource2 = Puppet::Type.type(:lan).new(
        datacenter_name: 'dummydc',
        name: 'lan2',
        public: true
      )
      @provider2 = provider_class.new(@resource2)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Lan::ProviderV1
      expect(@provider2).to be_an_instance_of Puppet::Type::Lan::ProviderV1
    end

    it 'should create ProfitBricks LAN with minimum params' do
      VCR.use_cassette('lan_create_min') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
      end
    end

    it 'should create ProfitBricks LAN with all params' do
      VCR.use_cassette('lan_create_all') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
      end
    end

    it 'should list LAN instances' do
      VCR.use_cassette('lan_list') do
        expect(provider_class.instances.length).to eq(2)
      end
    end

    it 'should update public property of the LAN' do
      VCR.use_cassette('lan_update') do
        @provider2.public = false
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'lan2'
        end
        expect(updated_instance.public).to eq(false)
      end
    end

    it 'should delete LAN' do
      VCR.use_cassette('lan_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
        expect(provider_class.instances.length).to eq(1)
      end
    end
  end
end
