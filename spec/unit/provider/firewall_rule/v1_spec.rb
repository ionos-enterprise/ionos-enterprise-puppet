require 'spec_helper'

provider_class = Puppet::Type.type(:firewall_rule).provider(:v1)

describe provider_class do
  context 'firewall rule operations' do
    before(:all) do
      @resource = Puppet::Type.type(:firewall_rule).new(
        name: 'testrule',
        nic: 'testnic',
        datacenter_name: 'dummydc',
        server_name: 'testserver',
        protocol: 'TCP',
        port_range_start: 80,
        port_range_end: 82
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Firewall_rule::ProviderV1
    end

    it 'should create ProfitBricks firewall rule' do
      VCR.use_cassette('firewall_rule_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
      end
    end

    it 'should list firewall rules' do
      VCR.use_cassette('firewall_rule_list') do
        expect(provider_class.instances.length).to eq(1)
      end
    end

    it 'should update firewall rule' do
      VCR.use_cassette('firewall_rule_update') do
        @provider.target_ip = '10.81.12.124'
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'testrule'
        end
        expect(updated_instance.target_ip).to eq('10.81.12.124')
      end
    end

    it 'should delete firewall rule' do
      VCR.use_cassette('firewall_rule_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
