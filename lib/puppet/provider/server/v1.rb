require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:server).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    PuppetX::Profitbricks::Helper::profitbricks_config(3)
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config(3)

    Datacenter.list.map do |datacenter|
      servers = []
      # Ignore data center if name is not defined.
      unless datacenter.properties['name'].nil? || datacenter.properties['name'].empty?
        Server.list(datacenter.id).each do |server|
          hash = instance_to_hash(server, datacenter)
          servers << new(hash)
        end
      end
      servers
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(instance, datacenter)
    volumes = instance.list_volumes.map do |mapping|
      { :name => mapping.properties['name'] }
    end

    nics = instance.list_nics.map do |mapping|
      { :name => mapping.properties['name'] }
    end

    instance_state = instance.properties['vmState']
    if ['SHUTOFF', 'SHUTDOWN', 'CRASHED'].include?(instance_state)
      state = :stopped
    else
      state = :present
    end

    boot_volume_name = ''
    unless instance.properties['bootVolume'].nil?
      boot_volume_id = instance.properties['bootVolume']['id']
      instance.entities['volumes']['items'].map do |volume|
        boot_volume_name = volume['properties']['name'] if volume['id'] == boot_volume_id
      end
    end

    config = {
      :id => instance.id,
      :datacenter_id => instance.datacenterId,
      :datacenter_name => datacenter.properties['name'],
      :name => instance.properties['name'],
      :cores => instance.properties['cores'],
      :cpu_family => instance.properties['cpuFamily'],
      :ram => instance.properties['ram'],
      :availability_zone => instance.properties['availabilityZone'],
      :boot_volume => boot_volume_name,
      :ensure => state
    }
    config[:volumes] = volumes unless volumes.empty?
    config[:nics] = nics unless nics.empty?
    config
  end

  def cores=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', cores.")
    server.update(cores: value)
    server.wait_for { ready? }
  end

  def cpu_family=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', CPU family.")
    server.update(cpuFamily: value, allowReboot: true)
    server.wait_for { ready? }
  end

  def ram=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', RAM.")
    server.update(ram: value)
    server.wait_for { ready? }
  end

  def availability_zone=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', availability zone.")
    server.update(availabilityZone: value)
    server.wait_for { ready? }
  end

  def boot_volume=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    volume = server.list_volumes.find { |volume| volume.properties['name'] == value }

    Puppet.info("Updating server '#{name}', boot volume.")
    server.update(bootVolume: { id: volume.id })
    server.wait_for { ready? }
  end

  def config_with_volumes(volumes)
    mappings = volumes.map do |volume|
      config = {
        :name => volume['name'],
        :size => volume['size'],
        :bus => volume['bus'],
        :type => volume['volume_type'] || 'HDD',
        :imagePassword => volume['image_password'],
        :availabilityZone => volume['availability_zone']
      }
      assign_ssh_keys(config, volume)
      assign_image_or_licence(config, volume)
    end
    mappings unless mappings.empty?
  end

  def config_with_fwrules(fwrules)
    mappings = fwrules.map do |fwrule|
      {
        :name => fwrule['name'],
        :protocol => fwrule['protocol'],
        :sourceMac => fwrule['source_mac'],
        :sourceIp => fwrule['source_ip'],
        :targetIp => fwrule['target_ip'],
        :portRangeStart => fwrule['port_range_start'],
        :portRangeEnd => fwrule['port_range_end'],
        :icmpType => fwrule['icmp_type'],
        :icmpCode => fwrule['icmp_code']
      }
    end
    mappings unless mappings.empty?
  end

  def config_with_nics(nics)
    mappings = nics.map do |nic|
      if nic.key?('firewall_rules')
        fwrules = config_with_fwrules(nic['firewall_rules'])
      end
      if nic.key?('lan')
        lan = PuppetX::Profitbricks::Helper::lan_from_name(nic['lan'],
          PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))
      end
      {
        :name => nic['name'],
        :ips => nic['ips'],
        :dhcp => nic['dhcp'],
        :lan => lan.id,
        :firewallrules => fwrules,
        :nat => nic['nat']
      }
    end
    mappings unless mappings.empty?
  end

  def exists?
    Puppet.info("Checking if server #{name} exists")
    running? || stopped?
  end

  def running?
    Puppet.info("Checking if server #{name} is running")
    [:present, :pending, :running].include? @property_hash[:ensure]
  end

  def stopped?
    Puppet.info("Checking if server #{name} is stopped")
    [:stopping, :stopped].include? @property_hash[:ensure]
  end

  def create
    Puppet.info("Creating a new server called #{name}.")
    if stopped?
      restart
    else
      if resource.propertydefined?(:volumes)
        volumes = config_with_volumes(
          resource[:volumes]
        )
      end

      if resource.propertydefined?(:nics)
        nics = config_with_nics(
          resource[:nics]
        )
      end

      server = Server.create(
        PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]),
        {:name => name,
        :cores => resource[:cores],
        :cpuFamily => resource[:cpu_family],
        :ram => resource[:ram],
        :availabilityZone => resource[:availability_zone],
        :volumes => volumes,
        :nics => nics}
      )

      begin
        server.wait_for { ready? }
      rescue StandardError
        request = request_error(server)
        if request['status'] == 'FAILED'
          fail "Failed to create server: #{request['message']}"
        end
      end

      Puppet.info("Server '#{name}' has been created.")
      @property_hash[:ensure] = :present

      unless resource[:boot_volume].nil? 
        volumes = server.list_volumes
        if volumes.length > 1
          boot_volume = volumes.find { |volume| volume.properties['name'] == resource[:boot_volume] }
          Puppet.info("Setting boot volume for the server.")
          server.update(bootVolume: { id: boot_volume.id })
          server.wait_for { ready? }
        end
      end

      @property_hash[:id] = server.id
    end
  end

  def restart
    Puppet.info("Restarting server #{name}")
    PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])).reboot
    @property_hash[:ensure] = :present
  end

  def stop
    create unless exists?
    Puppet.info("Stopping server #{name}")
    PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])).stop
    @property_hash[:ensure] = :stopped
  end

  def destroy
    server = PuppetX::Profitbricks::Helper::server_from_name(resource[:name],
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))
    destroy_volumes(server.list_volumes) if !resource[:purge_volumes].nil? && resource[:purge_volumes].to_s == 'true'
    Puppet.info("Deleting server #{name}.")
    server.delete
    server.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  def destroy_volumes(volumes)
    volumes.each do |volume|
      Puppet.info("Deleting volume #{volume.properties['name']}")
      volume.delete
      volume.wait_for { ready? }
    end
  end

  private

  def request_error(server)
    Request.get(server.requestId).status.metadata if server.requestId
  end

  def assign_ssh_keys(config, volume)
    if volume.key?('ssh_keys')
      ssh_keys = volume['ssh_keys']
      ssh_keys = ssh_keys.is_a?(Array) ? ssh_keys : [ssh_keys]
      config.merge!(sshKeys: ssh_keys)
    end
  end

  def assign_image_or_licence(config, volume)
    if volume.key?('image_id')
      config[:image] = volume['image_id']
    elsif volume.key?('image_alias')
      config[:imageAlias] = volume['image_alias']
    elsif volume.key?('licence_type')
      config[:licenceType] = volume['licence_type']
    else
      fail('Volume must have either image_id, image_alias or licence_type defined.')
    end

    if volume.key?('image_password')
      config[:imagePassword] = volume['image_password']
    end
    config
  end
end
