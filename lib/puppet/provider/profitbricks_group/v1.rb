require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:profitbricks_group).provide(:v1) do
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

    groups = []
    Group.list.each do |group|
      hash = instance_to_hash(group)
      groups << new(hash)
    end
    groups.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    gu = []
    instance.entities['users']['items'].map do |user|
      gu << user['properties']['email']
    end
    config = {
      id: instance.id,
      name: instance.properties['name'],
      create_datacenter: instance.properties['createDataCenter'],
      create_snapshot: instance.properties['createSnapshot'],
      reserve_ip: instance.properties['reserveIp'],
      access_activity_log: instance.properties['accessActivityLog'],
      members: gu,
      ensure: :present
    }
    config
  end

  def create_datacenter=(value)
    group = Group.get(id)
    Puppet.info("Updating create_datacenter privilege of group #{name}.")
    group.update(
      name: resource[:name],
      createDataCenter: value
    )
  end

  def create_snapshot=(value)
    group = Group.get(id)
    Puppet.info("Updating create_snapshot privilege of group #{name}.")
    group.update(
      name: resource[:name],
      createSnapshot: value
    )
  end

  def reserve_ip=(value)
    group = Group.get(id)
    Puppet.info("Updating reserve_ip privilege of group #{name}.")
    group.update(
      name: resource[:name],
      reserveIp: value
    )
  end

  def access_activity_log=(value)
    group = Group.get(id)
    Puppet.info("Updating access_activity_log privilege of group #{name}.")
    group.update(
      name: resource[:name],
      accessActivityLog: value
    )
  end

  def members=(value)
    gu = Hash.new
    User.list(group_id: id).each do |u|
      gu[u.properties['email']] = u.id
    end

    value.each do |v|
      unless gu.has_key?(v)
        user = PuppetX::Profitbricks::Helper::user_from_name(v)
        Puppet.info("Adding profitbricks user #{v} to group #{name}.")
        user = User.add_to_group(id, user.id)
        user.wait_for { ready? }
      end
    end

    gu.each do |key, val|
      unless value.include?(key)
        Puppet.info("Removing profitbricks user #{key} from group #{name}.")
        User.remove_from_group(id, val)
      end
    end
  end

  def exists?
    Puppet.info("Checking if profitbricks group #{name} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    group = Group.create(
      name: resource[:name],
      createDataCenter: resource[:create_datacenter],
      createSnapshot: resource[:create_snapshot],
      reserveIp: resource[:reserve_ip],
      accessActivityLog: resource[:access_activity_log]
    )

    group.wait_for { ready? }

    Puppet.info("Created new profitbricks group #{name}.")
    @property_hash[:ensure] = :present

    unless resource[:members].nil? || resource[:members].empty?
      resource[:members].each do |email|
        user = PuppetX::Profitbricks::Helper::user_from_name(email)
        Puppet.info("Adding profitbricks user #{email} to group #{name}.")
        user = User.add_to_group(group.id, user.id)
        user.wait_for { ready? }
      end
    end
    @property_hash[:id] = group.id
  end

  def destroy
    Puppet.info("Deleting group #{name}...")
    group = Group.get(id)
    group.delete
    group.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end
end
