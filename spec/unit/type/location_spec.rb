require 'spec_helper'

type_class = Puppet::Type.type(:location)

describe type_class do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :features,
      :image_aliases,
      :id
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
