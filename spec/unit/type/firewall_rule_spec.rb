require 'spec_helper'

type_class = Puppet::Type.type(:firewall_rule)

describe type_class do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :nic,
      :icmp_type,
      :icmp_code,
      :port_range_start,
      :port_range_end,
      :protocol,
      :source_mac,
      :source_ip,
      :target_ip,
      :server_id,
      :server_name,
      :datacenter_id,
      :datacenter_name
    ]
  end

  it 'should have expected properties' do
    properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'should require a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should support :present as a value to :ensure' do
    type_class.new(:name => 'sample', :ensure => :present)
  end

  it 'should support :absent as a value to :ensure' do
    type_class.new(:name => 'sample', :ensure => :absent)
  end
end
