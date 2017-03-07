require 'spec_helper'

type_class = Puppet::Type.type(:server)

describe type_class do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :ensure,
      :boot_volume,
      :datacenter_id,
      :datacenter_name,
      :cpu_family,
      :cores,
      :ram,
      :availability_zone,
      :licence_type,
      :volumes,
      :purge_volumes,
      :nics,
      :nat
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

  it 'should support :running as a value to :ensure' do
    type_class.new(:name => 'sample', :ensure => :running)
  end

  it 'should support :stopped as a value to :ensure' do
    type_class.new(:name => 'sample', :ensure => :stopped)
  end

  it 'should default availability_zone to AUTO' do
    server = type_class.new(:name => 'sample')
    expect(server[:availability_zone]).to eq(:AUTO)
  end

  it 'should default purge_volumes to false' do
    server = type_class.new(:name => 'sample')
    expect(server[:purge_volumes]).to eq(:false)
  end

  it 'if volumes included must include a volume name' do
    expect {
      type_class.new({:name => 'sample', :volumes => [
        { 'size' => 1 }
      ]})
    }.to raise_error(Puppet::Error, /Volume must include name/)
  end

  it 'if volumes included must include a volume size' do
    expect {
      type_class.new({:name => 'sample', :volumes => [
        { 'name' => 'sample' }
      ]})
    }.to raise_error(Puppet::Error, /Volume must include size/)
  end

  it 'if nics included must include a nic name' do
    expect {
      type_class.new({:name => 'sample', :nics => [{
        'dhcp' => true,
        'lan' => 'sample'
      }]})
    }.to raise_error(Puppet::Error, /NIC must include name/)
  end

  it 'if nics included must include dhcp' do
    expect {
      type_class.new({:name => 'sample', :nics => [{
        'name' => 'sample',
        'lan' => 'sample' 
      }]})
    }.to raise_error(Puppet::Error, /NIC must include dhcp/)
  end

  it 'if nics included must include a nic lan name' do
    expect {
      type_class.new({:name => 'sample', :nics => [{
        'name' => 'sample',
        'dhcp' => true
      }]})
    }.to raise_error(Puppet::Error, /NIC must include lan/)
  end
end
