require 'spec_helper'

provider_class = Puppet::Type.type(:location).provider(:v1)

describe provider_class do
  context 'location operations' do
    it 'should list location instances' do
      VCR.use_cassette('location_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Location::ProviderV1
        expect(instances.find { |l| l.id == 'us/las' }).to be_truthy
      end
    end
  end
end
