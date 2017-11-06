require 'spec_helper'

provider_class = Puppet::Type.type(:snapshot).provider(:v1)

describe provider_class do
  context 'snapshot operations' do
    before(:all) do
      @resource = Puppet::Type.type(:snapshot).new(
        name: 'Puppet Module Test',
        description: 'Puppet Module test snapshot',
        volume: 'Puppet Module Test',
        datacenter: 'Puppet Module Test'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Snapshot::ProviderV1
      expect(@provider.name).to eq('Puppet Module Test')
    end

    it 'should create snapshot' do
      VCR.use_cassette('snapshot_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('Puppet Module Test')
      end
    end

    it 'should list snapshot instances' do
      VCR.use_cassette('snapshot_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Snapshot::ProviderV1
      end
    end

    it 'should update snapshot' do
      VCR.use_cassette('snapshot_update') do
        new_desc = 'Puppet Module test snapshot - RENAME'
        @provider.description = new_desc
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.description).to eq(new_desc)
      end
    end

    it 'should restore snapshot' do
      VCR.use_cassette('snapshot_restore') do
        expect(@provider.restore = true).to be_truthy
      end
    end

    it 'should delete snapshot' do
      VCR.use_cassette('snapshot_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
