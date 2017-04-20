require 'spec_helper'

provider_class = Puppet::Type.type(:nic).provider(:v1)

describe provider_class do
  context 'NIC operations' do
    before(:all) do
      @resource = Puppet::Type.type(:nic).new(
        name: 'testnic',
        lan: 'lan1',
        dhcp: true,
        datacenter_name: 'dummydc',
        server_name: 'testserver',
        firewall_active: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Nic::ProviderV1
    end

    it 'should create ProfitBricks NIC' do
      VCR.use_cassette('nic_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
      end
    end

    it 'should list NIC instances' do
      VCR.use_cassette('nic_list') do
        expect(provider_class.instances.length).to eq(1)
      end
    end

    it 'should update NIC' do
      VCR.use_cassette('nic_update') do
        @provider.dhcp = false
        @provider.lan = 'lan2'
        @provider.ips = ['208.94.36.74', '208.94.36.121']
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'testnic'
        end
        expect(updated_instance.dhcp).to eq(false)
        expect(updated_instance.lan).to eq('lan2')
        expect(updated_instance.ips.length).to eq(2)
        expect(updated_instance.ips).to include('208.94.36.74', '208.94.36.121')
      end
    end

    it 'should delete NIC' do
      VCR.use_cassette('nic_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
