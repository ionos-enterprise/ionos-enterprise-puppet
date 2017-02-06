require 'profitbricks'

Puppet::Type.type(:lan).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    profitbricks_config
  end

  def self.instances
    profitbricks_config
    Datacenter.list.map do |datacenter|
      lans = []
      # Ignore data center if name is not defined.
      unless datacenter.properties['name'].nil? || datacenter.properties['name'].empty?
        LAN.list(datacenter.id).each do |lan|
          # Ignore LAN if name is not defined.
          unless lan.properties['name'].nil? || lan.properties['name'].empty?
            hash = instance_to_hash(lan, datacenter)
            lans << new(hash)
          end
        end
      end
      lans
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
    config = {
      id: instance.id,
      datacenter_id: instance.datacenterId,
      datacenter_name: datacenter.properties['name'],
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
      resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]),
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
    lan = lan_from_name(resource[:name],
      resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))
    lan.delete
    lan.wait_for { ready? }
    @property_hash[:ensure] = :absent
  end

  private

  def self.profitbricks_config
    ProfitBricks.configure do |config|
      config.username = ENV['PROFITBRICKS_USERNAME']
      config.password = ENV['PROFITBRICKS_PASSWORD']
      config.timeout = 300

      url = ENV['PROFITBRICKS_API_URL']
      config.url = url unless url.nil? || url.empty?

      config.headers = Hash.new
      config.headers['User-Agent'] = "Puppet/#{Puppet.version}"
    end
  end

  def request_error(lan)
    Request.get(lan.requestId).status.metadata if lan.requestId
  end

  def lan_from_name(name, datacenter_id)
    LAN.list(datacenter_id).find { |lan| lan.properties['name'] == name }
  end

  def resolve_datacenter_id(dc_id, dc_name)
    return dc_id unless dc_id.nil? || dc_id.empty?
    unless dc_name.nil? || dc_name.empty?
      Datacenter.list.each do |dc|
        return dc.id if dc_name.casecmp(dc.properties['name']) == 0
      end
      raise "Data center named '#{dc_name}' cannot be found."
    end
    raise "Data center ID or name must be provided."
  end
end
