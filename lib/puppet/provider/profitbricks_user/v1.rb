require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:profitbricks_user).provide(:v1) do
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

    users = []
    User.list.each do |user|
      hash = instance_to_hash(user)
      users << new(hash)
    end
    users.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    ug = []
    instance.entities['groups']['items'].map do |group|
      ug << group['properties']['name']
    end
    config = {
      id: instance.id,
      name: instance.properties['email'],
      email: instance.properties['email'],
      firstname: instance.properties['firstname'],
      lastname: instance.properties['lastname'],
      administrator: instance.properties['administrator'],
      force_sec_auth: instance.properties['forceSecAuth'],
      sec_auth_active: instance.properties['secAuthActive'],
      groups: ug,
      ensure: :present
    }
    config
  end

  def firstname=(value)
    user = User.get(id)
    Puppet.info("Updating first name of user #{name}.")
    user.update(
      firstname: value,
      lastname: resource[:lastname],
      email: resource[:email],
      administrator: resource[:administrator],
      forceSecAuth: resource[:force_sec_auth]
    )
  end

  def lastname=(value)
    user = User.get(id)
    Puppet.info("Updating last name of user #{name}.")
    user.update(
      firstname: resource[:firstname],
      lastname: value,
      email: resource[:email],
      administrator: resource[:administrator],
      forceSecAuth: resource[:force_sec_auth]
    )
  end

  def administrator=(value)
    user = User.get(id)
    Puppet.info("Updating administrator rights for user #{name}.")
    user.update(
      firstname: resource[:firstname],
      lastname: resource[:lastname],
      email: resource[:email],
      administrator: value,
      forceSecAuth: resource[:force_sec_auth]
    )
  end

  def force_sec_auth=(value)
    user = User.get(id)
    Puppet.info("Updating force secure authentication for user #{name}.")
    user.update(
      firstname: resource[:firstname],
      lastname: resource[:lastname],
      email: resource[:email],
      administrator: resource[:administrator],
      forceSecAuth: value
    )
  end

  def groups=(value)
    user = User.get(id)
    ug = Hash.new
    user.entities['groups']['items'].map do |i|
      ug[i['properties']['name']] = i['id']
    end

    value.each do |v|
      unless ug.has_key?(v)
        group = PuppetX::Profitbricks::Helper::group_from_name(v)
        Puppet.info("Adding profitbricks user #{name} to group #{v}.")
        user = User.add_to_group(group.id, id)
        user.wait_for { ready? }
      end
    end

    ug.each do |key, val|
      unless value.include?(key)
        Puppet.info("Removing profitbricks user #{name} from group #{key}.")
        User.remove_from_group(val, id)
      end
    end
  end

  def exists?
    Puppet.info("Checking if profitbricks user #{name} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    user = User.create(
      firstname: resource[:firstname],
      lastname: resource[:lastname],
      email: resource[:email],
      password: resource[:password],
      administrator: resource[:administrator],
      forceSecAuth: resource[:force_sec_auth]
    )

    user.wait_for { ready? }

    Puppet.info("Created new profitbricks user #{name}.")
    @property_hash[:ensure] = :present

    unless resource[:groups].nil? || resource[:groups].empty?
      resource[:groups].each do |g|
        group = PuppetX::Profitbricks::Helper::group_from_name(g)
        Puppet.info("Adding profitbricks user #{resource[:email]} to group #{g}.")
        user = User.add_to_group(group.id, user.id)
        user.wait_for { ready? }
      end
    end
    @property_hash[:id] = user.id
  end

  def destroy
    user = User.get(id)
    Puppet.info("Deleting user #{name}...")
    user.delete
    user.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end
end
