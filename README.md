## Table of Contents

* [Overview](#overview)
* [Description](#description)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Full Server Example](#full-server-example)
* [Remove Resources](#remove-resources)
* [Reference](#reference)
    * [Data Center Resource](#data-center-resource)
    * [LAN Resource](#lan-resource)
    * [Server Resource](#server-resource)
    * [Volume Resource](#volume-resource)
    * [NIC Resource](#nic-resource)
    * [Firewall Rule Resource](#firewall-rule-resource)
* [Contributing](#contributing)
* [Documentation and Support](#documentation-and-support)

## Overview

The ProfitBricks Puppet module allows a ProfitBricks multi-server cloud environment to be deployed automatically from a Puppet manifest file.

## Description

The ProfitBricks Puppet module utilizes the ProfitBricks REST API to manage resources within a ProfitBricks virtual data center. A Puppet manifest file can then be used to describe a desired infrastructure including networks, servers, CPU cores, memory, and their relationships as well as states. That infrastructure can then be easily and automatically deployed using Puppet.

## Requirements

* Puppet 4.2.x or greater
* Ruby 2.0 or greater
* ProfitBricks Ruby SDK (profitbricks-sdk-ruby)
* ProfitBricks account

## Installation

1. Install the ProfitBricks Ruby SDK gem.

    `gem install profitbricks-sdk-ruby`

2. Install the module.

    `puppet module install profitbricks-profitbricks`

3. Set the environment variables for authentication.

    `export PROFITBRICKS_USERNAME="user@example.com"`<br>
    `export PROFITBRICKS_PASSWORD="secretpassword"`

  Setting the ProfitBricks API URL is optional.

    `export PROFITBRICKS_API_URL="https://api.profitbricks.com/cloudapi/v3"`

## Usage

The Puppet manifest files use a domain specific language, or DSL. This language allows resources and their states to be declared. Puppet will then build the resources and set the states as described in the manifest file. The following snippet describes a simple LAN resource.

    lan { 'public':
      ensure => present,
      public => true,
      datacenter_id => '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    }

A LAN named `public` will have public Internet access enabled and will reside in the defined data center.

To provide a data center ID, you can create a data center within the module as follows:

    datacenter { 'myDataCenter' :
      ensure      => present,
      location    => 'de/fra',
      description => 'test data center'
    }

Afterwards, get the data center ID using the puppet resource command:

    puppet resource datacenter [myDataCenter]

More convenient than using an ID, a data center name can be used instead. Refer to the next section for an example.

If you have already created your data center, LAN and server resources, you may connect them with a new NIC resource using their names or IDs.

    $datacenter_name = 'testdc1'
    $server_name = 'worker1'
    $lan_name = 'public1'

    nic { 'testnic':
      datacenter_name   => $datacenter_name,
      server_name => $server_name,
      nat => false,
      dhcp => true,
      lan => $lan_name,
      ips => ['78.137.103.102', '78.137.103.103', '78.137.103.104'],
      firewall_active => true,
      firewall_rules => [
        { 
          name => 'SSH',
          protocol => 'TCP',
          port_range_start => 22,
          port_range_end => 22
        }
      ]
    }

**Note**:

Using the ProfitBricks Puppet module to manage your ProfitBricks resources ensures uniqueness of the managed instances.
However, the ProfitBricks API generally allows, for example, to create multiple data centers having the same name.
If you manage LAN and server resources using data center names, the module will throw an error when more than one data center
with the same name is detected. Similarly, removing data centers by non-unique names is not allowed.

## Full Server Example

The following example will describe a full server with public Internet access and allow inbound SSH connections.

    $datacenter_id = '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    
    lan { 'public':
      ensure => present,
      public => true,
      datacenter_id => $datacenter_id
    }
    
    server { 'frontend':
      ensure => running,
      datacenter_id => $datacenter_id,
      cores => 2,
      cpu_family => 'INTEL_XEON',
      ram => 4096,
      volumes => [
        {
          name => 'system',
          size => 5,
          bus => 'VIRTIO',
          volume_type => 'SSD'
          image_id => 'e87692f2-3587-11e5-9b0d-52540066fee9',
          image_password => 'mysecretpassword',
          availability_zone => 'AUTO'
        }
      ],
      nics => [
        {
          name => 'nic0',
          dhcp => true,
          lan => 'public',
          nat => false,
          firewall_rules => [
            {
              name => 'SSH',
              protocol => 'TCP',
              port_range_start => 22,
              port_range_end => 22
            }
          ]
        }
      ]
    }

Alternatively, instead of providing a data center ID, you can create a data center along with LAN and server resources in a single manifest by using the data center name as input parameter.

    $datacenter_name = 'MyDataCenter'

    datacenter { $datacenter_name :
      ensure      => present,
      location    => 'de/fkb',
      description => 'my data center desc.'
    } ->

    lan { 'public' :
      ensure => present,
      public => true,
      datacenter_name => $datacenter_name
    } ->

    server { 'worker1' :
      ensure => present,
      cores => 2,
      datacenter_name => $datacenter_name,
      ram => 1024,
      volumes => [
        {
          name => 'system',
          size => 50,
          bus => 'VIRTIO',
          volume_type => 'SSD',
          image_id => '7412cec6-e83c-11e6-a994-525400f64d8d',
          ssh_keys => [ 'ssh-rsa AAAAB3NzaC1yc2EAA...' ],
          availability_zone => 'AUTO'
        }
      ],
      nics => [
        {
          name => 'public',
          dhcp => true,
          lan => 'public',
          nat => false,
          firewall_rules => [
            { 
              name => 'SSH',
              protocol => 'TCP',
              port_range_start => 22,
              port_range_end => 22
            }
          ]
        }
      ]
    }

## Remove Resources

The following example sets the above resource states to `absent`. This will cause the server named `frontend` along with the associated `public` LAN to be removed.

    $datacenter_id = '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    
    server { 'frontend':
      ensure => absent,
      datacenter_id => $datacenter_id
    } ~>
    lan { 'public':
      ensure => absent,
      datacenter_id => $datacenter_id
    }

By default, the volumes attached to the server resources will remain available when the server is removed. If you prefer to have the volumes removed along with the server, then the `purge_volumes` property will need to be set to `true` for the server resource:

    server { 'frontend' :
      ensure => absent,
      purge_volumes => true,
      datacenter_id => '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    }

**Note:** Volume removal is permanent. Be sure to perform a snapshot if you wish to retain the volume data.

**Note:** You may use `datacenter_name` instead of `datacenter_id` when removing LANs and servers.

## Reference

### Data Center Resource

Required

* **name**: The name of the data center.
* **ensure**: The desired state of the data center must be `present` or `absent`.
* **location**: The location of the data center.

Optional

* **description**: The data center description.

You can update `description` property after the data center is created.

### LAN Resource

Required

* **name**: The name of the LAN.
* **ensure**: The desired state of the LAN must be `present` or `absent`.
* **datacenter_id**: The UUID of an existing data center where the LAN will reside. Optional, if `datacenter_name` is specified.
* **datacenter_name**: The name of the data center where the LAN will reside. Optional, if `datacenter_id` is specified.

Optional

* **public**: Determines whether the LAN will have public Internet access. Can be `true` or `false`, defaults to `false`.

The LAN resource allows `public` property to be updated if necessary.

### Server Resource

Server resources provide the following properties.

**Required**

* **name**: The name of the server.
* **ensure**: The desired server state which can be `present`, `absent`, `running`, or `stopped`.
* **datacenter_id**: The UUID of an existing data center where the server will reside. Optional, if `datacenter_name` is specified.
* **datacenter_name**: The name of the data center where the server will reside. Optional, if `datacenter_id` is specified.
* **cores**: The number of CPU cores assigned to the server.
* **ram**:  The amount of RAM assigned to the server MB (must be a multiple of 256).

**Optional**

* **cpu_family**: The CPU family which can be `AMD_OPTERON` or `INTEL_XEON`, defaults to `AMD_OPTERON`.
* **availability_zone**: Availability zone of the server, defaults to `AUTO`.
* **licence_type**: If undefined the OS type will be inherited from the boot image or boot volume.
* **boot_volume**: The boot volume name, if more than one volume it attached to the server.
* **purge_volumes**: Set to `true` to purge all attached volumes on server delete, defaults to `false`.
* **volumes**: An array of volumes that will be built and attached to the server.
* **nics**: An array of NICs that will be connected to the server.

`availability_zone`, `boot_volume`, `cores`, `cpu_family` and `ram` are mutable properties.
The values of these properties can be updated after the server has been created.

### Volume Resource

Volume resources can be managed independently within a data center or as a nested array defined within the server resource.

**Required**

* **name**: Name of the volume.
* **size**: Size of the volume in GB.
* **volume_type**: The volume type can be `HDD` or `SSD`.

When managed independently, the data center ID or name is required too.

* **datacenter_id**: The UUID of an existing data center where the volume is or will be created.
* **datacenter_name**: The name of the data center where the volume is or will be created.

**Optional**

* **image_id**: UUID of the image to assign to the volume.
* **licence_type**: The licence type of the volume including `LINUX`, `WINDOWS`, `UNKNOWN`, and `OTHER`.
* **image_password**: One-time password is set on the Image for the appropriate account.
* **bus**: The bus type of volume, can be `VIRTIO` or `IDE`, defaults to `VIRTIO`.
* **ssh_keys**: A list of public SSH keys to add to supported image.
* **availability_zone**: Direct a storage volume to be created in one of three zones per data center. This allows for the deployment of enhanced high-availability configurations. Valid values for `availability_zone` are: `AUTO`, `ZONE_1`, `ZONE_2`, or `ZONE_3`.

The volume `size` can be increased after the volume is created.

**Note**: Either `image_id` or `licence_type` must be defined.

### NIC Resource

NICs can be created and managed separately as other resources such as LANs, or nested under the server resource.

* **name**: Name of the NIC.
* **ips**: An array of IP addresses to assign the NIC.
* **dhcp**: Set DHCP on the NIC with `true` or `false`, defaults to `true`.
* **lan**: Name of the LAN to connect the NIC.
* **firewall_rules**: An array of firewall rules to assign the NIC.
* **nat**: A boolean which indicates if the NIC will perform Network Address Translation. There are a few requirements:
 - The NIC this is being activated on must belong to a private LAN.
 - The NIC must not belong to a load balancer.
 - NAT cannot be activated in a private LAN that contains an IPv4 address ending with ".1".
 - NAT should not be enabled in a Virtual Data Center with an active ProfitBricks firewall.

If NICs are not nested, some of the following parameters are required as well.

* **datacenter_id**: The UUID of an existing data center where the NIC will reside. Optional, if `datacenter_name` is specified.
* **datacenter_name**: The name of the data center where the NIC will reside. Optional, if `datacenter_id` is specified.
* **server_id**: The UUID of an existing server where the NIC will reside. Optional, if `server_name` is specified.
* **server_name**: The name of the server where the NIC will reside. Optional, if `server_id` is specified.
* **firewall_active**: Indicates the firewall is active. Default value is false.

`ips`, `dhcp`, `lan` and `nat` are mutable properties.

### Firewall Rule Resource

Firewall rules are usually nested within `nics` under the server resource.

* **name**: Name of the firewall rule.
* **protocol**: Allow traffic protocols including `TCP`, `UDP`, `ICMP`, and `ANY`.
* **source_mac**: Allow traffic from the source MAC address.
* **source_ip**: Allow traffic originating from the source IP address.
* **target_ip**: Allow traffic destined to the target IP address.
* **port_range_start**: Defines the start range of the allowed port (from 1 to 65534) if protocol TCP or UDP is chosen.
* **port_range_end**: Defines the end range of the allowed port (from 1 to 65534) if the protocol TCP or UDP is chosen.
* **icmp_type**: Defines the allowed type (from 0 to 254) if the protocol ICMP is chosen.
* **icmp_code**: Defines the allowed code (from 0 to 254) if protocol ICMP is chosen.

If firewall rules are managed as independent resources, the data center, server and NIC informations are required.

* **datacenter_id**: The UUID of an existing data center where the server and NIC will reside. Optional, if `datacenter_name` is specified.
* **datacenter_name**: The name of the data center where the server and NIC will reside. Optional, if `datacenter_id` is specified.
* **server_id**: The UUID of an existing server where the server and NIC will reside. Optional, if `server_name` is specified.
* **server_name**: The name of the server where the server and NIC will reside. Optional, if `server_id` is specified.
* **nic**: The name of the NIC the firewall rule will be added to.

`source_mac`, `source_ip`, `target_ip`, `port_range_start`, `port_range_end`, `icmp_type` and `icmp_code` are mutable properties.

## Contributing

1. Fork it (`https://github.com/[my-github-username]/profitbricks-puppet/fork`).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new Pull Request.

## Build and Install Module

Run the following from the repository directory.

    cd profitbricks-puppet
    puppet module build
    puppet module install -f pkg/profitbricks-profitbricks-[version].tar.gz

Notes: [version] should be replaced with the module version built. For example, 1.2.0.

## Documentation and Support

* [ProfitBricks REST API](https://devops.profitbricks.com/api/rest/) documentation.
* Ask a question or discuss at [ProfitBricks DevOps Central](https://devops.profitbricks.com/community).
* Report an [issue here](https://github.com/profitbricks/profitbricks-puppet/issues).
