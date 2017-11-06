require 'spec_helper'

provider_class = Puppet::Type.type(:datacenter).provider(:v1)

describe provider_class do
  context 'data center operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:datacenter).new(
        name: 'Puppet Module Test',
        location: 'us/las'
      )
      @provider1 = provider_class.new(@resource1)

      @resource2 = Puppet::Type.type(:datacenter).new(
        name: 'Puppet Module Test 2',
        location: 'us/las',
        description: 'Puppet Module test description'
      )
      @provider2 = provider_class.new(@resource2)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Datacenter::ProviderV1
      expect(@provider2).to be_an_instance_of Puppet::Type::Datacenter::ProviderV1
    end

    it 'should create ProfitBricks data center with minimum params' do
      VCR.use_cassette('datacenter_create_min') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq('Puppet Module Test')
      end
    end

    it 'should create ProfitBricks data center with all params' do
      VCR.use_cassette('datacenter_create_all') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq('Puppet Module Test 2')
      end
    end

    it 'should list data center instances' do
      VCR.use_cassette('datacenter_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Datacenter::ProviderV1
      end
    end

    it 'should update data center description' do
      VCR.use_cassette('datacenter_update') do
        new_desc = 'Puppet Module Test - RENAME'
        @provider2.description = new_desc
        updated_instance = nil
        provider_class.instances.each do |dc|
          updated_instance = dc if dc.name == 'Puppet Module Test 2'
        end
        expect(updated_instance.description).to eq(new_desc)
      end
    end

    it 'should delete data center' do
      VCR.use_cassette('datacenter_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
