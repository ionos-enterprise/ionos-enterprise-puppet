require 'spec_helper'

provider_class = Puppet::Type.type(:profitbricks_group).provider(:v1)

describe provider_class do
  context 'profitbricks_group operations' do
    before(:all) do
      @resource = Puppet::Type.type(:profitbricks_group).new(
        name: 'Puppet Module Test',
        create_datacenter: true,
        create_snapshot: true,
        reserve_ip: true,
        access_activity_log: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Profitbricks_group::ProviderV1
      expect(@provider.name).to eq('Puppet Module Test')
    end

    it 'should create profitbricks_group' do
      VCR.use_cassette('profitbricks_group_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('Puppet Module Test')
      end
    end

    it 'should list profitbricks_group instances' do
      VCR.use_cassette('profitbricks_group_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Profitbricks_group::ProviderV1
      end
    end

    it 'should update profitbricks_group' do
      VCR.use_cassette('profitbricks_group_update') do
        @provider.create_datacenter = false
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.create_datacenter).to eq(false)
      end
    end

    it 'should delete profitbricks_group' do
      VCR.use_cassette('profitbricks_group_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
