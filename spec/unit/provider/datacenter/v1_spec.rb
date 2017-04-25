require 'spec_helper'

provider_class = Puppet::Type.type(:datacenter).provider(:v1)

describe provider_class do
  context 'data center operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:datacenter).new(
        name: 'dummydc',
        location: 'us/las'
      )
      @provider1 = provider_class.new(@resource1)

      @resource2 = Puppet::Type.type(:datacenter).new(
        name: 'dummydc2',
        location: 'de/fkb',
        description: 'test desc'
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
      end
    end

    it 'should create ProfitBricks data center all params' do
      VCR.use_cassette('datacenter_create_all') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
      end
    end

    it 'should list data center instances' do
      VCR.use_cassette('datacenter_list') do
        expect(provider_class.instances.length).to eq(2)
      end
    end

    it 'should update data center description' do
      VCR.use_cassette('datacenter_update') do
        new_desc = 'new description'
        @provider2.description = new_desc
        updated_instance = nil
        provider_class.instances.each do |dc|
          updated_instance = dc if dc.name == 'dummydc2'
        end
        expect(updated_instance.description).to eq(new_desc)
      end
    end

    it 'should delete data center' do
      VCR.use_cassette('datacenter_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
        expect(provider_class.instances.length).to eq(1)
      end
    end
  end
end
