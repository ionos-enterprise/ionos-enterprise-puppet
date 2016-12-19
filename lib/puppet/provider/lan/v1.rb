require 'profitbricks'

Puppet::Type.type(:lan).provide(:v1) do
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

      config.headers = Hash.new
      config.headers['User-Agent'] = 'profitbricks-puppet-1.3.1'
    end
  end

  def self.instances
    Datacenter.list.map do |datacenter|
      lans = []
      LAN.list(datacenter.id).each do |lan|
        # Ignore LAN if name is not defined.
        if lan.properties['name'] != nil
          hash = instance_to_hash(lan)
          lans << new(hash)
        end
      end
      lans
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
    config = {
      id: instance.id,
      datacenter_id: instance.datacenterId,
      name: instance.properties['name'],
      ensure: :present
    }
    config
  end

  def exists?
    Puppet.info("Checking if LAN #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    lan = LAN.create(
      resource[:datacenter_id],
      name: name,
      public: resource[:public] || false
    )

    begin
      lan.wait_for(3).wait_for { ready? }
    rescue StandardError
      request = request_error(lan)
      if request['status'] == 'FAILED'
        fail "Failed to create LAN: #{request['message']}"
      end
    end

    Puppet.info("Creating a new LAN called #{name}.")
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.info("Deleting LAN #{name}.")
    lan = lan_from_name(resource[:name], resource[:datacenter_id])
    lan.delete
    lan.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def request_error(lan)
    Request.get(lan.requestId).status.metadata if lan.requestId
  end

  def lan_from_name(name, datacenter_id)
    LAN.list(datacenter_id).find { |lan| lan.properties['name'] == name }
  end
end
