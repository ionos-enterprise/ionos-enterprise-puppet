require 'spec_helper'

provider_class = Puppet::Type.type(:lan).provider(:v1)

describe provider_class do
  context 'LAN operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:lan).new(
        datacenter_name: 'Puppet Module Test',
        name: 'Puppet Module Test'
      )
      @provider1 = provider_class.new(@resource1)

      @resource2 = Puppet::Type.type(:lan).new(
        datacenter_name: 'Puppet Module Test',
        name: 'Puppet Module Test 2',
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
        expect(@provider1.name).to eq('Puppet Module Test')
      end
    end

    it 'should create ProfitBricks LAN with all params' do
      VCR.use_cassette('lan_create_all') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq('Puppet Module Test 2')
      end
    end

    it 'should list LAN instances' do
      VCR.use_cassette('lan_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Lan::ProviderV1
      end
    end

    it 'should update public property of the LAN' do
      VCR.use_cassette('lan_update') do
        @provider2.public = false
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test 2'
        end
        expect(updated_instance.public).to eq(false)
      end
    end

    it 'should delete LAN' do
      VCR.use_cassette('lan_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
