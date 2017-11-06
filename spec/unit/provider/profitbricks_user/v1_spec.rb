require 'spec_helper'

provider_class = Puppet::Type.type(:profitbricks_user).provider(:v1)

describe provider_class do
  context 'profitbricks_user operations' do
    before(:all) do
      @resource = Puppet::Type.type(:profitbricks_user).new(
        firstname: 'John',
        lastname: 'Doe',
        email: 'john.doe_002@example.com',
        password: 'Secrete.Password.001',
        administrator: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Profitbricks_user::ProviderV1
      expect(@provider.name).to eq('john.doe_002@example.com')
    end

    it 'should create profitbricks_user' do
      VCR.use_cassette('profitbricks_user_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('john.doe_002@example.com')
      end
    end

    it 'should list profitbricks_user instances' do
      VCR.use_cassette('profitbricks_user_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Profitbricks_user::ProviderV1
      end
    end

    it 'should update profitbricks_user' do
      VCR.use_cassette('profitbricks_user_update') do
        @provider.administrator = false
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == 'john.doe_002@example.com'
        end
        expect(updated_instance.administrator).to eq(false)
      end
    end

    it 'should add profitbricks_user to group' do
      VCR.use_cassette('profitbricks_user_add_to_group') do
        @provider.groups = ['Puppet Module Test']
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == 'john.doe_002@example.com'
        end
        expect(updated_instance.groups).to eq(['Puppet Module Test'])
      end
    end

    it 'should remove profitbricks_user from group' do
      VCR.use_cassette('profitbricks_user_remove_from_group') do
        @provider.groups = []
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == 'john.doe_002@example.com'
        end
        expect(updated_instance.groups).to eq([])
      end
    end

    it 'should delete profitbricks_user' do
      VCR.use_cassette('profitbricks_user_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
