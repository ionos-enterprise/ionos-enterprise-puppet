require 'spec_helper'

provider_class = Puppet::Type.type(:server).provider(:v1)

describe provider_class do
  context 'server operations' do
    before(:all) do
      @resource1 = Puppet::Type.type(:server).new(
        name: 'Puppet Module Test',
        cores: 1,
        ram: 1024,
        availability_zone: 'ZONE_1',
        datacenter_name: 'Puppet Module Test'
      )
      @provider1 = provider_class.new(@resource1)

      vol1 = Hash.new
      vol1['name'] = 'Puppet Module Test'
      vol1['size'] = 100
      vol1['bus'] = 'VIRTIO'
      vol1['volume_type'] = 'SSD'
      vol1['availability_zone'] = 'AUTO'
      # Ubuntu-16.04-LTS-server-2017-10-01
      vol1['image_id'] = '1871dd47-a671-11e7-90a7-525400f64d8d'
      vol1['image_password'] = 'ghGhghgHGGghgh7GHjjuuyt655656hvvh67hg7gt'
      vol1['ssh_keys'] = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...'

      vol2 = Hash.new
      vol2['name'] = 'Puppet Module Test 2'
      vol2['size'] = 10
      vol2['bus'] = 'VIRTIO'
      vol2['volume_type'] = 'HDD'
      vol2['availability_zone'] = 'ZONE_3'
      # CentOS-7-server-2017-10-01
      vol2['image_id'] = '34e8ad2e-a65e-11e7-90a7-525400f64d8d'
      vol2['image_password'] = 'ghGhghgHGGghgh7GHjjuuyt655656hvvh67hg7gt'
      vol1['ssh_keys'] = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...'

      firewall = Hash.new
      firewall['name'] = 'SSH'
      firewall['protocol'] = 'TCP'
      firewall['source_mac'] = '01:23:45:67:89:00'
      firewall['port_range_start'] = 22
      firewall['port_range_end'] = 22

      nic = Hash.new
      nic['name'] = 'Puppet Module Test'
      nic['dhcp'] = true
      nic['lan'] = 'Puppet Module Test'
      nic['nat'] = false
      nic['firewall_rules'] = [firewall]

      @resource2 = Puppet::Type.type(:server).new(
        name: 'Puppet Module Test 2',
        cores: 1,
        cpu_family: 'INTEL_XEON',
        ram: 1024,
        volumes: [vol1, vol2],
        purge_volumes: true,
        nics: [nic],
        datacenter_name: 'Puppet Module Test'
      )
      @provider2 = provider_class.new(@resource2)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Server::ProviderV1
      expect(@provider2).to be_an_instance_of Puppet::Type::Server::ProviderV1
    end

     it 'should create ProfitBricks server with minimum params' do
      VCR.use_cassette('server_create_min') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq('Puppet Module Test')
      end
    end

     it 'should create composite server' do
      VCR.use_cassette('server_create_composite') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq('Puppet Module Test 2')
      end
    end

    it 'should list server instances' do
      VCR.use_cassette('server_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Server::ProviderV1
      end
    end

    it 'should update boot volume' do
      VCR.use_cassette('server_update_boot_volume') do
        @provider2.boot_volume = 'Puppet Module Test 2'
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test 2'
        end
        expect(updated_instance.boot_volume).to eq('Puppet Module Test 2')
      end
    end

    it 'should update RAM' do
      VCR.use_cassette('server_update_ram') do
        @provider2.ram = 2048
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test 2'
        end
        expect(updated_instance.ram).to eq(2048)
      end
    end

    it 'should update cores' do
      VCR.use_cassette('server_update_cores') do
        @provider2.cores = 2
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test 2'
        end
        expect(updated_instance.cores).to eq(2)
      end
    end

    it 'should update CPU family' do
      VCR.use_cassette('server_update_cpu_family') do
        @provider2.cpu_family = 'AMD_OPTERON'
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test 2'
        end
        expect(updated_instance.cpu_family).to eq('AMD_OPTERON')
      end
    end

    it 'should update availability zone' do
      VCR.use_cassette('server_update_availabilty_zone') do
        @provider1.availability_zone = 'AUTO'
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.availability_zone).to eq('AUTO')
      end
    end

    it 'should stop server' do
      VCR.use_cassette('server_stop') do
        expect(@provider2.running?).to be true
        expect(@provider2.stop).to be_truthy
        expect(@provider2.stopped?).to be true
      end
    end

    it 'should start server' do
      VCR.use_cassette('server_start') do
        expect(@provider2.running?).to be false
        expect(@provider2.create).to be_truthy
        expect(@provider2.running?).to be true
      end
    end

    it 'should restart server' do
      VCR.use_cassette('server_restart') do
        expect(@provider2.running?).to be true
        expect(@provider2.restart).to be_truthy
        expect(@provider2.running?).to be true
      end
    end

    it 'should delete server' do
      VCR.use_cassette('server_delete') do
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
