require 'profitbricks'

module PuppetX
  module Profitbricks
    class Helper
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

      def self.count_by_name(res_name, items)
        count = 0
        unless items.empty?
          name_key = res_name.strip.downcase
          items.each do |item|
            unless item.properties['name'].nil? || item.properties['name'].empty?
              item_name = item.properties['name'].strip.downcase
              count += 1 if item_name == name_key
            end
          end
        end
        count
      end

      def self.resolve_datacenter_id(dc_id, dc_name)
        return dc_id unless dc_id.nil? || dc_id.empty?
        unless dc_name.nil? || dc_name.empty?
          datacenters = Datacenter.list

          Puppet.info("Validating if data center name is unique.")
          if count_by_name(dc_name, datacenters) > 1
            fail "Data center named '#{dc_name}' already exists."
          end

          datacenters.each do |dc|
            return dc.id if dc_name.casecmp(dc.properties['name']) == 0
          end
          raise "Data center named '#{dc_name}' cannot be found."
        end
        raise "Data center ID or name must be provided."
      end
    end
  end
end
