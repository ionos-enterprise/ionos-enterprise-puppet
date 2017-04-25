require 'spec_helper'

provider_class = Puppet::Type.type(:volume).provider(:v1)

describe provider_class do
  context 'volume operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:volume).new(
        name: 'testvolume',
        size: 50,
        licence_type: 'LINUX',
        datacenter_name: 'dummydc'
      )
      @provider1 = provider_class.new(@resource1)

      @resource2 = Puppet::Type.type(:volume).new(
        name: 'testvolume2',
        size: 100,
        licence_type: 'WINDOWS2016',
        volume_type: 'SSD',
        availability_zone: 'AUTO',
        datacenter_name: 'dummydc'
      )
      @provider2 = provider_class.new(@resource2)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Volume::ProviderV1
      expect(@provider2).to be_an_instance_of Puppet::Type::Volume::ProviderV1
    end

    it 'should create ProfitBricks HDD volume' do
      VCR.use_cassette('volume_create_hdd') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
      end
    end

    it 'should create ProfitBricks SSD volume' do
      VCR.use_cassette('volume_create_ssd') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
      end
    end

    it 'should list volume instances' do
      VCR.use_cassette('volume_list') do
        expect(provider_class.instances.length).to eq(2)
      end
    end

    it 'should update volume size' do
      VCR.use_cassette('volume_update') do
        @provider2.size = 150
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'testvolume2'
        end
        expect(updated_instance.size).to eq(150)
      end
    end

    it 'should delete volume' do
      VCR.use_cassette('volume_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
        expect(provider_class.instances.length).to eq(1)
      end
    end
  end
end
