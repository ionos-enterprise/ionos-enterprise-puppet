require 'profitbricks'

module PuppetX
  module Profitbricks
    class Helper
      def self.profitbricks_config(depth = nil)
        ProfitBricks.configure do |config|
          config.username = ENV['PROFITBRICKS_USERNAME']
          config.password = ENV['PROFITBRICKS_PASSWORD']
          config.timeout = 600

          config.depth = depth unless depth.nil?

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
            fail "Found more than one data center named '#{dc_name}'."
          end

          datacenters.each do |dc|
            return dc.id if dc_name.casecmp(dc.properties['name']) == 0
          end
          fail "Data center named '#{dc_name}' cannot be found."
        end
        fail "Data center ID or name must be provided."
      end

      def self.lan_from_name(lan_name, datacenter_id)
        lan = LAN.list(datacenter_id).find { |lan| lan.properties['name'] == lan_name }
        fail "LAN named '#{lan_name}' cannot be found." unless lan
        lan
      end

      def self.server_from_name(server_name, datacenter_id)
        server = Server.list(datacenter_id).find { |server| server.properties['name'] == server_name }
        fail "Server named '#{server_name}' cannot be found." unless server
        server
      end

      def self.group_from_name(group_name)
        group = Group.list.find { |group| group.properties['name'] == group_name }
        fail "Group named '#{group_name}' cannot be found." unless group
        group
      end

      def self.resolve_group_id(group_id, group_name)
        return group_id unless group_id.nil? || group_id.empty?
        return group_from_name(group_name).id
      end

      def self.user_from_name(user_email)
        user = User.list.find { |user| user.properties['email'] == user_email }
        fail "User with email '#{user_email}' cannot be found." unless user
        user
      end
    end
  end
end
