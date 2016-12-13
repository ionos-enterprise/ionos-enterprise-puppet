## Table of Contents

* [Overview](#overview)
* [Description](#description)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Full Server Example](#full-server-example)
* [Remove Resources](#remove-resources)
* [Reference](#reference)
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

    `puppet module install profitbricks-puppet`

3. Set the environment variables for authentication.

    `export PROFITBRICKS_USERNAME="user@example.com"`<br>
    `export PROFITBRICKS_PASSWORD="secretpassword"`

## Usage

The Puppet manifest files use a domain specific language, or DSL. This language allows resources and their states to be declared. Puppet will then build the resources and set the states as described in the manifest file. The following snippet describes a simple LAN resource.

    lan { 'public':
      ensure => present,
      public => true,
      datacenter_id => '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    }

A LAN named `public` will have public Internet access enabled and will reside in the defined data center.

**Note**: It is important that resource names be unique within the manifest file. This includes both similar and different resource types. For example, a LAN resource named `public` will conflict with a server resource named `public`.

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

## Reference

### LAN Resource

Required

* **ensure**: The desired state of the LAN must be `present` or `absent`.
* **datacenter_id**: The data center where the server will reside. This must be provisioned beforehand.

Optional

* **public**: Determines whether the LAN will have public Internet access. Can be `true` or `false`, defaults to `false`.

### Server Resource

Server resources provide the following properties.

**Required**

* **ensure**: The desired server state which can be `present`, `absent`, `running`, or `stopped`.
* **datacenter_id**: The UUID of an existing data center where the server will reside.
* **cores**: The number of CPU cores assigned to the server.
* **ram**:  The amount of RAM assigned to the server MB (must be a multiple of 256).

**Optional**

* **cpu_family**: The CPU family which can be `AMD_OPTERON` or `INTEL_XEON`, defaults to `AMD_OPTERON`.
* **availability_zone**: Availability zone of the server, defaults to `AUTO`.
* **licence_type**: If undefined the OS type will be inherited from the boot image or boot volume.
* **boot_volume**: The UUID of an existing volume from which to boot.
* **boot_cdrom**: The UUID of an existing CDROM/ISO image from which to boot.
* **purge_volumes**: Set to `true` to purge all attached volumes on server delete, defaults to `false`
* **volumes**: An array of volumes that will be built and attached to the server.
* **nics**: An array of NICs that will be connected to the server.

### Volume Resource

Volumes are a nested array defined within the server resource.

**Required**

* **name**: Name of the volume.
* **size**: Size of the volume in GB.
* **volume_type**: The volume type can be `HDD` or `SSD`.

**Optional**

* **image_id**: UUID of the image to assign to the volume.
* **licence_type**: The licence type of the volume including `LINUX`, `WINDOWS`, `UNKNOWN`, and `OTHER`.
* **image_password**: One-time password is set on the Image for the appropriate account.
* **bus**: The bus type of volume, can be `VIRTIO` or `IDE`, defaults to `VIRTIO`.
* **ssh_keys**: A list of public SSH keys to add to supported image.
* **availability_zone**: Direct a storage volume to be created in one of three zones per data center. This allows for the deployment of enhanced high-availability configurations. Valid values for `availability_zone` are: `AUTO`, `ZONE_1`, `ZONE_2`, or `ZONE_3`.

**Note**: Either `image_id` or `licence_type` must be defined.

### NIC Resource

NICs nested under the server resource.

* **name**: Name of the NIC.
* **ips**: An array of IP addresses to assign the NIC.
* **dhcp**: Set DHCP on the NIC with `true` or `false`, defaults to `true`.
* **lan**: Name of the LAN to connect the NIC.
* **firewallrules**: An array of firewall rules to assign the NIC.
* **nat**: A boolean which indicates if the NIC will perform Network Address Translation. There are a few requirements:
 - The NIC this is being activated on must belong to a private LAN.
 - The NIC must not belong to a load balancer.
 - NAT cannot be activated in a private LAN that contains an IPv4 address ending with ".1".
 - NAT should not be enabled in a Virtual Data Center with an active ProfitBricks firewall.

### Firewall Rule Resource

Firewall rules are nested within `nics` under the server resource.

* **name**: Name of the firewall rule.
* **protocol**: Allow traffic protocols including `TCP`, `UDP`, `ICMP`, and `ANY`.
* **source_mac**: Allow traffic from the source MAC address.
* **source_ip**: Allow traffic originating from the source IP address.
* **target_ip**: Allow traffic destined to the target IP address.
* **port_range_start**: Defines the start range of the allowed port (from 1 to 65534) if protocol TCP or UDP is chosen.
* **port_range_end**: Defines the end range of the allowed port (from 1 to 65534) if the protocol TCP or UDP is chosen.
* **icmp_type**: Defines the allowed type (from 0 to 254) if the protocol ICMP is chosen.
* **icmp_code**: Defines the allowed code (from 0 to 254) if protocol ICMP is chosen.

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
    puppet module install -f pkg/profitbricks-puppet-[version].tar.gz

Notes: [version] should be replaced with the module version built. For example, 1.2.0.

## Documentation and Support

* [ProfitBricks REST API](https://devops.profitbricks.com/api/rest/) documentation.
* Ask a question or discuss at [ProfitBricks DevOps Central](https://devops.profitbricks.com/community).
* Report an [issue here](https://github.com/profitbricks/profitbricks-puppet/issues).
