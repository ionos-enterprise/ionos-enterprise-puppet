require 'profitbricks'

Puppet::Type.type(:server).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    ProfitBricks.configure do |config|
      config.username = ENV['PROFITBRICKS_USERNAME']
      config.password = ENV['PROFITBRICKS_PASSWORD']
      config.timeout = 300
    end
  end

  def self.instances
    Datacenter.list.map do |datacenter|
      servers = []
      Server.list(datacenter.id).each do |server|
        hash = instance_to_hash(server)
        servers << new(hash)
      end
      servers
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:datacenter_id] == prov.datacenter_id
      end
    end
  end

  def self.instance_to_hash(instance)
    volumes = instance.list_volumes.map do |mapping|
      { name: mapping.properties['name'] }
    end

    nics = instance.list_nics.map do |mapping|
      { name: mapping.properties['name'] }
    end

    instance_state = instance.properties['vmState']
    if ['SHUTOFF', 'SHUTDOWN', 'CRASHED'].include?(instance_state)
      state = :stopped
    else
      state = :present
    end

    config = {
      id: instance.id,
      datacenter_id: instance.datacenterId,
      name: instance.properties['name'],
      ensure: state
    }
    config[:volumes] = volumes unless volumes.empty?
    config[:nics] = nics unless nics.empty?
    config
  end

  def config_with_volumes(volumes)
    mappings = volumes.map do |volume|
      config = {
        name: volume['name'],
        size: volume['size'],
        bus: volume['bus'],
        type: volume['type'] || 'HDD',
        imagePassword: volume['image_password']
      }
      assign_ssh_keys(config, volume)
      assign_image_or_licence(config, volume)
    end
    mappings unless mappings.empty?
  end

  def config_with_fwrules(fwrules)
    mappings = fwrules.map do |fwrule|
      {
        name: fwrule['name'],
        protocol: fwrule['protocol'],
        sourceMac: fwrule['source_mac'],
        sourceIp: fwrule['source_ip'],
        targetIp: fwrule['target_ip'],
        portRangeStart: fwrule['port_range_start'],
        portRangeEnd: fwrule['port_range_end'],
        icmpType: fwrule['icmp_type'],
        icmpCode: fwrule['icmp_code']
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
        lan = lan_from_name(nic['lan'], resource[:datacenter_id])
      end
      {
        name: nic['name'],
        ips: nic['ips'],
        dhcp: nic['dhcp'],
        lan: lan.id,
        firewallrules: fwrules
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
        resource[:datacenter_id],
        name: name,
        cores: resource[:cores],
        ram: resource[:ram],
        availabilityZone: resource[:availability_zone],
        volumes: volumes,
        nics: nics
      )

      begin
        server.wait_for(3).wait_for { ready? }
      rescue StandardError
        request = request_error(server)
        if request['status'] == 'FAILED'
          fail "Failed to create server: #{request['message']}"
        end
      end

      Puppet.info("Creating a new server called #{name}.")
      @property_hash[:id] = server.id
      @property_hash[:ensure] = :present
    end
  end

  def restart
    Puppet.info("Restarting server #{name}")
    server_from_name(name, resource[:datacenter_id]).reboot
    @property_hash[:ensure] = :present
  end

  def stop
    create unless exists?
    Puppet.info("Stopping server #{name}")
    server_from_name(name, resource[:datacenter_id]).stop
    @property_hash[:ensure] = :stopped
  end

  def destroy
    server = server_from_name(resource[:name], resource[:datacenter_id])
    destroy_volumes(server.list_volumes) if resource[:purge_volumes]
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

  def server_from_name(name, datacenter_id)
    Server.list(datacenter_id).find do |server|
      server.properties['name'] == name
    end
  end

  def lan_from_name(name, datacenter_id)
    LAN.list(datacenter_id).find { |lan| lan.properties['name'] == name }
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
    elsif volume.key?('licence_type')
      config[:licenceType] = volume['licence_type']
    else
      fail('Volume must have either image_id or licence_type defined.')
    end

    if volume.key?('image_password')
      config[:imagePassword] = volume['image_password']
    end
    config
  end
end
