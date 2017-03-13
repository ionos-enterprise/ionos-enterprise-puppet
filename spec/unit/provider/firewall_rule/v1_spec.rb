require 'spec_helper'

provider_class = Puppet::Type.type(:firewall_rule).provider(:v1)

describe provider_class do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:firewall_rule).new(
        name: 'testrule',
        nic: 'testnic',
        datacenter_name: 'dummydc',
        server_name: 'testserver',
        protocol: 'TCP',
        port_range_start: 80,
        port_range_end: 80
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Firewall_rule::ProviderV1
    end

    context 'create' do
      it 'should create ProfitBricks firewall rule' do
        VCR.use_cassette('firewall_rule_create') do
          expect(@provider.create).to be_truthy
          expect(@provider.exists?).to be true
        end
      end
    end
  end
end
