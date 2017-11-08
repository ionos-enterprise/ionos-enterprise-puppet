require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:share).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    PuppetX::Profitbricks::Helper::profitbricks_config(2)
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config(2)

    Group.list.map do |group|
      shares = []
      sh = Hash.new
      group.entities['resources']['items'].map do |r|
        sh[r['id']] = r['type']
      end
      unless sh.empty?
        Share.list(group.id).map do |share|
          hash = instance_to_hash(share, group, sh)
          shares << new(hash)
        end
      end
      shares
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if resource[:group_id] == prov.group_id || resource[:group_name] == prov.group_name
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(share, group, res)
    config = {
      name: share.id,
      type: res[share.id],
      group_id: group.id,
      group_name: group.properties['name'],
      edit_privilege: share.properties['editPrivilege'],
      share_privilege: share.properties['sharePrivilege'],
      ensure: :present
    }
    config
  end

  def edit_privilege=(value)
    grp_id = PuppetX::Profitbricks::Helper::resolve_group_id(resource[:group_id], resource[:group_name])

    Puppet.info("Updating edit privilege of #{name} share.")
    Share.update(grp_id, name, editPrivilege: value)
  end

  def share_privilege=(value)
    grp_id = PuppetX::Profitbricks::Helper::resolve_group_id(resource[:group_id], resource[:group_name])

    Puppet.info("Updating share privilege of #{name} share.")
    Share.update(grp_id, name, sharePrivilege: value)
  end

  def exists?
    Puppet.info("Checking if share #{name} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    sh = {
      editPrivilege: resource[:edit_privilege],
      sharePrivilege: resource[:share_privilege]
    }
    share = Share.create(
      PuppetX::Profitbricks::Helper::resolve_group_id(resource[:group_id], resource[:group_name]),
      resource[:name],
      sh
    )

    share.wait_for { ready? }

    Puppet.info("Added share #{share.id}.")
    @property_hash[:ensure] = :present
  end

  def destroy
    grp_id = PuppetX::Profitbricks::Helper::resolve_group_id(resource[:group_id], resource[:group_name])
    Share.delete(grp_id, resource[:name])
    Puppet.info("Removing share #{name}.")
    @property_hash[:ensure] = :absent
  end
end
