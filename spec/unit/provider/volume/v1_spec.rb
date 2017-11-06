require 'spec_helper'

provider_class = Puppet::Type.type(:volume).provider(:v1)

describe provider_class do
  context 'volume operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:volume).new(
        name: 'Puppet Module Test',
        size: 2,
        image_alias: 'ubuntu:latest',
        availability_zone: 'ZONE_3',
        ssh_keys: ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...'],
        datacenter_name: 'Puppet Module Test'
      )
      @provider1 = provider_class.new(@resource1)

      @resource2 = Puppet::Type.type(:volume).new(
        name: 'Puppet Module Test 2',
        size: 100,
        licence_type: 'WINDOWS2016',
        volume_type: 'SSD',
        availability_zone: 'AUTO',
        datacenter_name: 'Puppet Module Test'
      )
      @provider2 = provider_class.new(@resource2)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Volume::ProviderV1
      expect(@provider1.name).to eq('Puppet Module Test')
      expect(@provider2).to be_an_instance_of Puppet::Type::Volume::ProviderV1
    end

    it 'should create ProfitBricks HDD volume' do
      VCR.use_cassette('volume_create_hdd') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq('Puppet Module Test')
      end
    end

    it 'should create ProfitBricks SSD volume' do
      VCR.use_cassette('volume_create_ssd') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq('Puppet Module Test 2')
      end
    end

    it 'should list volume instances' do
      VCR.use_cassette('volume_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Volume::ProviderV1
      end
    end

    it 'should update volume size' do
      VCR.use_cassette('volume_update') do
        @provider1.size = 5
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.size).to eq(5)
      end
    end

    it 'should delete volume' do
      VCR.use_cassette('volume_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
