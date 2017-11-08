require 'spec_helper'

provider_class = Puppet::Type.type(:firewall_rule).provider(:v1)

describe provider_class do
  context 'firewall rule operations' do
    before(:all) do
      @resource = Puppet::Type.type(:firewall_rule).new(
        name: 'SSH',
        nic: 'Puppet Module Test',
        datacenter_name: 'Puppet Module Test',
        server_name: 'Puppet Module Test',
        protocol: 'TCP',
        source_mac: '01:23:45:67:89:00',
        port_range_start: 22,
        port_range_end: 22
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
        expect(@provider.name).to eq('SSH')
      end
    end

    it 'should list firewall rules' do
      VCR.use_cassette('firewall_rule_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Firewall_rule::ProviderV1
      end
    end

    it 'should update firewall rule' do
      VCR.use_cassette('firewall_rule_update') do
        @provider.target_ip = '10.81.12.124'
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'SSH'
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
