require 'spec_helper'

type_class = Puppet::Type.type(:ipblock)

describe type_class do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :ensure,
      :location,
      :id,
      :size,
      :created_by,
      :ips
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
    type_class.new(:name => 'test', :location => 'us/las', :size => 1, :ensure => :present)
  end

  it 'should support :absent as a value to :ensure' do
    type_class.new(:name => 'test', :location => 'us/las', :size => 1, :ensure => :absent)
  end

  it 'should require a location' do
    expect {
      type_class.new(:name => 'test', :location => '', :size => 1,)
    }.to raise_error(Puppet::ResourceError, /IP block location must be set/)
  end

  it 'should require a size' do
    expect {
      type_class.new(:name => 'test', :location => 'us/las', :size => 0)
    }.to raise_error(Puppet::ResourceError, /The size of the IP block must be an integer greater than zero./)
  end
end
