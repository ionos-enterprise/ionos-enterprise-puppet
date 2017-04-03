require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:nic).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    PuppetX::Profitbricks::Helper::profitbricks_config(5)
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config(5)

    Datacenter.list.map do |datacenter|
      nics = []
      unless datacenter.properties['name'].nil? || datacenter.properties['name'].empty?
        lans = Hash.new

        LAN.list(datacenter.id).map { |lan| lans[lan.id] = lan.properties['name'] }

        unless lans.empty?
          Server.list(datacenter.id).map do |server|
            unless server.properties['name'].nil? || server.properties['name'].empty?
              server.entities['nics']['items'].map do |nic|
                unless nic['properties']['name'].nil? || nic['properties']['name'].empty?
                  hash = instance_to_hash(nic, lans, server, datacenter)
                  nics << new(hash)
                end
              end
            end
          end
        end
      end
      nics
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if (resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name) &&
           (resource[:server_id] == prov.server_id || resource[:server_name] == prov.server_name)
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(instance, lans, server, datacenter)
    config = {
      id: instance['id'],
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties['name'],
      server_id: server.id,
      server_name: server.properties['name'],
      lan: lans[instance['properties']['lan'].to_s],
      dhcp: instance['properties']['dhcp'],
      nat: instance['properties']['nat'],
      ips: instance['properties']['ips'],
      firewall_active: instance['properties']['firewallActive'],
      name: instance['properties']['name'],
      ensure: :present
    }
    config
  end

  def exists?
    Puppet.info("Checking if NIC #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def ips=(value)
    nic = nic_from_name(resource[:name])

    Puppet.info("Updating NIC '#{name}' IPs.")
    nic.update(ips: value)
    nic.wait_for { ready? }
  end

  def lan=(value)
    nic = nic_from_name(resource[:name])

    lan_id = PuppetX::Profitbricks::Helper::lan_from_name(value, nic.datacenterId).id

    Puppet.info("Updating NIC '#{name}' LAN.")
    nic.update(lan: lan_id)
    nic.wait_for { ready? }
  end

  def nat=(value)
    nic = nic_from_name(resource[:name])

    Puppet.info("Updating NIC '#{name}' NAT.")
    nic.update(nat: value)
    nic.wait_for { ready? }
  end

  def dhcp=(value)
    nic = nic_from_name(resource[:name])

    Puppet.info("Updating NIC '#{name}' DHCP.")
    nic.update(dhcp: value)
    nic.wait_for { ready? }
  end

  def create
    dc_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    lan_id = PuppetX::Profitbricks::Helper::lan_from_name(resource[:lan], dc_id).id

    server_id = resource[:server_id]
    unless server_id
      server_id = PuppetX::Profitbricks::Helper::server_from_name(resource[:server_name], dc_id).id
    end

    is_nat = false
    if !resource[:nat].nil? && resource[:nat].to_s == 'true'
      is_nat = true
    end

    nic = NIC.create(
      dc_id,
      server_id, 
      name: name,
      nat: is_nat,
      dhcp: resource[:dhcp],
      lan: lan_id,
      ips: resource[:ips],
      firewallActive: resource[:firewall_active]
    )

    Puppet.info("Creating a new NIC named #{name}.")

    nic.wait_for { ready? }

    unless resource[:firewall_rules].nil? || resource[:firewall_rules].empty?
      Puppet.info("Adding firewall rules to NIC #{name}.")
      resource[:firewall_rules].each do |rule|
        fwrule = nic.create_firewall_rule(
          name: rule['name'],
          protocol: rule['protocol'],
          sourceMac: rule['source_mac'],
          sourceIp: rule['source_ip'],
          targetIp: rule['target_ip'],
          portRangeStart: rule['port_range_start'],
          portRangeEnd: rule['port_range_end'],
          icmpType: rule['icmp_type'],
          icmpCode: rule['icmp_code']
        )

        fwrule.wait_for { ready? }
      end
    end

    @property_hash[:ensure] = :present
  end

  def destroy
    nic = nic_from_name(resource[:name])

    Puppet.info("Deleting NIC #{name}.")
    nic.delete
    nic.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def nic_from_name(name)
    dc_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = resource[:server_id]
    unless server_id
      server_id = PuppetX::Profitbricks::Helper::server_from_name(resource[:server_name], dc_id).id
    end

    NIC.list(dc_id, server_id).find { |nic| nic.properties['name'] == name }
  end
end
