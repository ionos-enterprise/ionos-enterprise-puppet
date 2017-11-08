require 'spec_helper'

provider_class = Puppet::Type.type(:share).provider(:v1)

describe provider_class do
  context 'share operations' do
    before(:all) do
      @resource = Puppet::Type.type(:share).new(
        name: 'b9c6cb26-6100-4ba3-803a-caf75267068a',
        group_id: 'b903838d-6384-4b81-b682-695068e50e48',
        edit_privilege: true,
        share_privilege: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Share::ProviderV1
      expect(@provider.name).to eq('b9c6cb26-6100-4ba3-803a-caf75267068a')
    end

    it 'should add share' do
      VCR.use_cassette('share_add') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('b9c6cb26-6100-4ba3-803a-caf75267068a')
      end
    end

    it 'should list share instances' do
      VCR.use_cassette('share_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Share::ProviderV1
      end
    end

    it 'should update share' do
      VCR.use_cassette('share_update') do
        @provider.edit_privilege = false
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'b9c6cb26-6100-4ba3-803a-caf75267068a'
        end
        expect(updated_instance.edit_privilege).to eq(false)
      end
    end

    it 'should remove share' do
      VCR.use_cassette('share_remove') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
