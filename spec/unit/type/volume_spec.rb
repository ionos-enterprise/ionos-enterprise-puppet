require 'spec_helper'

type_class = Puppet::Type.type(:volume)

describe type_class do
  let :params do
    [
      :name,
      :image_password,
      :image_alias,
      :ssh_keys
    ]
  end

  let :properties do
    [
      :ensure,
      :datacenter_id,
      :datacenter_name,
      :size,
      :image_id,
      :availability_zone,
      :bus,
      :volume_type,
      :licence_type
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

  it 'should default volume availability_zone to AUTO' do
    volume = type_class.new(:name => 'test')
    expect(volume[:availability_zone]).to eq('AUTO')
  end

  it 'should default volume bus to VIRTIO' do
    volume = type_class.new(:name => 'test')
    expect(volume[:bus]).to eq(:VIRTIO)
  end

  it 'should default volume_type to HDD' do
    volume = type_class.new(:name => 'test')
    expect(volume[:volume_type]).to eq(:HDD)
  end

  it 'should validate length of image_password' do
    expect {
      type_class.new(:name => 'test', :image_password => 'test123')
    }.to raise_error(Puppet::Error,'Parameter image_password failed on Volume[test]:'\
      ' The image password must contain at least 8 and no more than 50 characters.')
  end

  it 'should detect invalid characters in image_password' do
    expect {
      type_class.new(:name => 'test', :image_password => 'test,123.')
    }.to raise_error(Puppet::Error,'Parameter image_password failed on Volume[test]:'\
      ' Only [a-z][A-Z][0-9] characters are allowed for the image password.')
  end

  it 'should require an array of SSH keys' do
    expect {
      type_class.new(:name => 'test', :ssh_keys => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB')
    }.to raise_error(Puppet::Error,'Parameter ssh_keys failed on Volume[test]:'\
      ' The SSH keys should be an Array.')
  end
end
