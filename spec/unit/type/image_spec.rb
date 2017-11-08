require 'spec_helper'

type_class = Puppet::Type.type(:image)

describe type_class do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :description,
      :location,
      :id,
      :size,
      :cpu_hot_plug,
      :cpu_hot_unplug,
      :ram_hot_plug,
      :ram_hot_unplug,
      :nic_hot_plug,
      :nic_hot_unplug,
      :disc_virtio_hot_plug,
      :disc_virtio_hot_unplug,
      :disc_scsi_hot_plug,
      :disc_scsi_hot_unplug,
      :public,
      :image_type,
      :image_aliases,
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
end
