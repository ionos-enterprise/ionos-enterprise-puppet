require 'spec_helper'

provider_class = Puppet::Type.type(:image).provider(:v1)

describe provider_class do
  context 'image operations' do
    it 'should list image instances' do
      VCR.use_cassette('image_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Image::ProviderV1
      end
    end
  end
end
