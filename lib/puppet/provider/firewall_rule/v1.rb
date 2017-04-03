require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:firewall_rule).provide(:v1) do
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
      rules = []
      unless datacenter.properties['name'].nil? || datacenter.properties['name'].empty?
        Server.list(datacenter.id).map do |server|
          unless server.properties['name'].nil? || server.properties['name'].empty?
            server.entities['nics']['items'].map do |nic|
              unless nic['properties']['name'].nil? || nic['properties']['name'].empty?
                nic['entities']['firewallrules']['items'].map do |rule|
                  unless rule['properties']['name'].nil? || rule['properties']['name'].empty?
                    hash = instance_to_hash(rule, nic, server, datacenter)
                    rules << new(hash)
                  end
                end
              end
            end
          end
        end
      end
      rules
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if (resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name) &&
           (resource[:server_id] == prov.server_id || resource[:server_name] == prov.server_name) &&
           resource[:nic] == prov.nic
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(rule, nic, server, datacenter)
    config = {
      id: rule['id'],
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties['name'],
      server_id: server.id,
      server_name: server.properties['name'],
      nic: nic['properties']['name'],
      source_mac: rule['properties']['sourceMac'],
      source_ip: rule['properties']['sourceIp'],
      target_ip: rule['properties']['targetIp'],
      port_range_start: rule['properties']['portRangeStart'],
      port_range_end: rule['properties']['portRangeEnd'],
      icmp_type: rule['properties']['icmpType'],
      icmp_code: rule['properties']['icmpCode'],
      protocol: rule['properties']['protocol'],
      name: rule['properties']['name'],
      ensure: :present
    }
    config
  end

  def exists?
    Puppet.info("Checking if firewall rule #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def icmp_code=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: resource[:source_mac],
      sourceIp: resource[:source_ip],
      targetIp: resource[:target_ip],
      portRangeStart: resource[:port_range_start],
      portRangeEnd: resource[:port_range_end],
      icmpType: resource[:icmp_type],
      icmpCode: value
    )
    Puppet.info("Updating icmp code for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def icmp_type=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: resource[:source_mac],
      sourceIp: resource[:source_ip],
      targetIp: resource[:target_ip],
      portRangeStart: resource[:port_range_start],
      portRangeEnd: resource[:port_range_end],
      icmpType: value,
      icmpCode: resource[:icmp_code]
    )
    Puppet.info("Updating icmp type for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def port_range_start=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: resource[:source_mac],
      sourceIp: resource[:source_ip],
      targetIp: resource[:target_ip],
      portRangeStart: value,
      portRangeEnd: resource[:port_range_end],
      icmpType: resource[:icmp_type],
      icmpCode: resource[:icmp_code]
    )
    Puppet.info("Updating port range start for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def port_range_end=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: resource[:source_mac],
      sourceIp: resource[:source_ip],
      targetIp: resource[:target_ip],
      portRangeStart: resource[:port_range_start],
      portRangeEnd: value,
      icmpType: resource[:icmp_type],
      icmpCode: resource[:icmp_code]
    )
    Puppet.info("Updating port range end for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def source_mac=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: value,
      sourceIp: resource[:source_ip],
      targetIp: resource[:target_ip],
      portRangeStart: resource[:port_range_start],
      portRangeEnd: resource[:port_range_end],
      icmpType: resource[:icmp_type],
      icmpCode: resource[:icmp_code]
    )
    Puppet.info("Updating source mac for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def source_ip=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: resource[:source_mac],
      sourceIp: value,
      targetIp: resource[:target_ip],
      portRangeStart: resource[:port_range_start],
      portRangeEnd: resource[:port_range_end],
      icmpType: resource[:icmp_type],
      icmpCode: resource[:icmp_code]
    )
    Puppet.info("Updating source IP for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def target_ip=(value)
    fwrule = resolve_fwrule(resource[:name], resource[:nic])
    fwrule.update(
      sourceMac: resource[:source_mac],
      sourceIp: resource[:source_ip],
      targetIp: value,
      portRangeStart: resource[:port_range_start],
      portRangeEnd: resource[:port_range_end],
      icmpType: resource[:icmp_type],
      icmpCode: resource[:icmp_code]
    )
    Puppet.info("Updating target IP for firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
  end

  def create
    dc_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])

    server_id = resource[:server_id]
    unless server_id
      server_id = PuppetX::Profitbricks::Helper::server_from_name(resource[:server_name], dc_id).id
    end

    nic = NIC.list(dc_id, server_id).find { |nic| nic.properties['name'] == resource[:nic] }

    fwrule = nic.create_firewall_rule(
      name: name,
      protocol: resource[:protocol],
      sourceMac: resource[:source_mac],
      sourceIp: resource[:source_ip],
      targetIp: resource[:target_ip],
      portRangeStart: resource[:port_range_start],
      portRangeEnd: resource[:port_range_end],
      icmpType: resource[:icmp_type],
      icmpCode: resource[:icmp_code]
    )

    Puppet.info("Creating firewall rule '#{name}'.")
    fwrule.wait_for { ready? }
    @property_hash[:ensure] = :present
  end

  def destroy
    fwrule = resolve_fwrule(resource[:name], resource[:nic])

    Puppet.info("Deleting firewall rule #{name}.")
    fwrule.delete
    fwrule.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def resolve_fwrule(fw_name, nic_name)
    dc_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = resource[:server_id]
    unless server_id
      server_id = PuppetX::Profitbricks::Helper::server_from_name(resource[:server_name], dc_id).id
    end

    nic = NIC.list(dc_id, server_id).find { |nic| nic.properties['name'] == nic_name }
    Firewall.list(dc_id, server_id, nic.id).find { |rule| rule.properties['name'] == fw_name }
  end
end
