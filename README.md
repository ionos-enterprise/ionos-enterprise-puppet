## Puppet Module

Version: profitbricks-puppet v1.6.0

## Table of Contents

* [Description](#description)
* [Getting Started](#getting-started)
    * [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
    * [Verification](#verification)
* [Examples](#examples)
    * [Full Server Example](#full-server-example)
    * [Remove Resources](#remove-resources)
* [Reference](#reference)
    * [Data Center Resource](#data-center-resource)
    * [LAN Resource](#lan-resource)
    * [Server Resource](#server-resource)
    * [Volume Resource](#volume-resource)
    * [NIC Resource](#nic-resource)
    * [Firewall Rule Resource](#firewall-rule-resource)
    * [IP Block Resource](#ip-block-resource)
    * [Snapshot Resource](#snapshot-resource)
    * [ProfitBricks Group Resource](#profitbricks-group-resource)
    * [ProfitBricks User Resource](#profitbricks-user-resource)
    * [Share Resource](#share-resource)
    * [Image Resource](#image-resource)
    * [Location Resource](#location-resource)
* [Support](#support)
* [Testing](#testing)
* [Build and Install the Module](#build-and-install-the-module)
* [Contributing](#contributing)

## Description

The ProfitBricks Puppet module allows a multi-server cloud environment using ProfitBricks resources to be deployed automatically from a Puppet manifest file.

This module utilizes the ProfitBricks [Cloud API](https://devops.profitbricks.com/api/cloud/) via the [ProfitBricks Ruby SDK](https://devops.profitbricks.com/libraries/ruby/) to manage resources within a virtual data center. A Puppet manifest file can be used to describe the desired infrastructure configuration including networks, servers, CPU cores, memory, and their relationships as well as states. That infrastructure can then be easily and automatically deployed using Puppet.

## Getting Started

Before you begin you will need to have [signed-up for a ProfitBricks account](https://devops.profitbricks.com/signup). The credentials you establish during sign-up will be used to authenticate against the ProfitBricks Cloud API.

### Requirements

* Puppet 4.2.x or greater
* Ruby 2.0 or greater
* ProfitBricks Ruby SDK (profitbricks-sdk-ruby)
* ProfitBricks account

## Installation

There are multiple ways that Puppet and Ruby can be installed on an operating system (OS).

For users who already have a system with Puppet and Ruby installed, the following three easy steps should get the ProfitBricks Puppet module working. **Note:** You may need to prefix `sudo` to the commands in steps one and two.

1. Install the ProfitBricks Ruby SDK using `gem`.

        gem install profitbricks-sdk-ruby

2. Install the module.

        puppet module install profitbricks-profitbricks

3. Set the environment variables for authentication.

        export PROFITBRICKS_USERNAME="user@example.com"
        export PROFITBRICKS_PASSWORD="secretpassword"

    Setting the ProfitBricks API URL is optional.

        export PROFITBRICKS_API_URL="https://api.profitbricks.com/cloudapi/v4"

A situation could arise in which you have installed a Puppet release that contains a bundled copy of Ruby, but you already had Ruby installed. In that case, you will want to be sure to specify the `gem` binary that comes with the bundled version of Ruby. This avoids a situation in which you inadvertently install the *profitbricks-ruby-sdk* library but it is not available to the Ruby install that Puppet is actually using.

To demonstrate this on a CentOS 7 server, these steps could be followed.

**Note:** You may need to prefix `sudo` to the commands in steps one through three.

1. Install Puppet using the official Puppet Collection.

        rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm

        yum install puppet-agent

2. Install the ProfitBricks Ruby SDK using `gem`. **Note:** We are supplying the full path to the `gem` binary.

        /opt/puppetlabs/puppet/bin/gem install profitbricks-sdk-ruby

3. Install the Puppet module. **Note:** We are supplying the full path to the `puppet` binary.

        /opt/puppetlabs/puppet/bin/puppet module install profitbricks-profitbricks

4. Set the environment variables for authentication.

        export PROFITBRICKS_USERNAME="user@example.com"
        export PROFITBRICKS_PASSWORD="secretpassword"

## Usage

A Puppet manifest uses a domain specific language, or DSL. This language allows resources and their states to be declared. Puppet will then build the resources and set the states as described in the manifest. The following snippet describes a simple LAN resource.

    lan { 'public':
      ensure => present,
      public => true,
      datacenter_id => '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    }

A LAN named `public` will have public Internet access enabled and will reside in the defined virtual data center.

**Note**: It is important that resource names be unique within the manifest. This includes both similar and different resource types. For example, a LAN resource named `public` will conflict with a server resource named `public`.

To provide a data center ID, you can create a data center within the module as follows:

    datacenter { 'myDataCenter' :
      ensure      => present,
      location    => 'de/fra',
      description => 'test data center'
    }

Afterwards, get the data center ID using the puppet resource command:

    puppet resource datacenter [myDataCenter]

which should return output similar to this:

    datacenter { 'myDataCenter':
      ensure      => 'present',
      description => 'test data center',
      id          => '4af72f13-221d-499d-88ea-48713173e12f',
      location    => 'de/fra',
    }

The returned *id* value of *4af72f13-221d-499d-88ea-48713173e12f* may be used elsewhere in our manifest to identify this virtual data center.

A data center name can be used instead. You may find this more convenient than using a data center ID. Please refer to the next section for an example.

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

**Note**: Using the ProfitBricks Puppet module to manage your ProfitBricks resources ensures uniqueness of the managed instances. The ProfitBricks Cloud API allows the creation of multiple virtual data centers having the same name.

If you attempt to manage LAN and server resources using data center names, the module will throw an error when more than one virtual data center with the same name is detected. The same is true if you attempt to remove virtual data centers by non-unique names.

### Verification

Once you have composed a manifest, it is good to have Puppet validate the syntax. The Puppet accessory `parser` can check for syntax errors. To validate a manifest named `init.pp` run:

    puppet parser validate init.pp

If the manifest validates successfully, no output is returned. If there is an issue, you should get some output indicating what is invalid:

    Error: Could not parse for environment production: Syntax error at '}' at init.pp:8:2

That error message indicates we should take a look at a curly brace located on line 8 column 2 of `init.pp`.

To have puppet go ahead and apply the manifest run:

    puppet apply init.pp

## Examples

## Full Server Example

The following example will describe deploying a new server with public Internet access and allow inbound SSH connections.

**Note:** the value for `$datacenter_id` needs to be set to a valid virtual data center UUID that your account credentials are allowed to access. There are a couple of ways to get the UUID of a virtual data center. You can make a GET request against the Cloud API using a command-line tool such as `curl`, use an application such Postman, or one of various browser plugins for working with REST APIs.

The [ProfitBricks CLI](https://devops.profitbricks.com/tools/cli/) may be helpful as the command: `profitbricks datacenter list` will return a list of available virtual data centers.

It is also possible to get the UUID from inside the ProfitBricks Data Center Designer (DCD). If you log in and hover over one of your virtual data centers listed under "My Data Centers", a tooltip appears that contains the UUID.

Once we have a valid virtual data center UUID, lets proceed with the full server example.

    $datacenter_id = '2dbf0e6b-3430-46fd-befd-6d08acd96557'

    lan { 'publicLAN':
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
          volume_type => 'SSD',
          image_id => 'e87692f2-3587-11e5-9b0d-52540066fee9',
          image_password => 'mysecretpassword',
          availability_zone => 'AUTO'
        }
      ],
      nics => [
        {
          name => 'nic0',
          dhcp => true,
          lan => 'publicLAN',
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

Instead of providing a data center ID, you can create a data center along with LAN and server resources in a single manifest by using the data center name as the input parameter.

    $datacenter_name = 'MyDataCenter'

    datacenter { $datacenter_name :
      ensure      => present,
      location    => 'de/fkb',
      description => 'my data center desc.'
    } ->

    lan { 'publicLAN' :
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
          name => 'publicNIC',
          dhcp => true,
          lan => 'publicLAN',
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

This reference section describes the various resources and the associated properties that may be used when composing a Puppet manifest.

### Data Center Resource

Data Center resources can have the following properties set.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the virtual data center. |
| ensure | **yes** | string | The desired state of the virtual data center. It must be `present` or `absent`. |
| location | **yes** | string | The ProfitBricks location of the virtual data center: `us/las`, `us/ewr`, `de/fkb`, or `de/fra` |
| description | no | string | The virtual data center description. |

It is possible to update the `description` property after the virtual data center is created.

### LAN Resource

LAN resources can have the following properties set.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the LAN. |
| ensure | **yes** | string | The desired state of the LAN. It must be `present` or `absent`. |
| datacenter_id | **yes** | string | The UUID of an existing virtual data center where the LAN will reside. Optional, if `datacenter_name` is specified. |
| datacenter_name | **yes** | string | The name of the virtual data center where the LAN will reside. Optional, if `datacenter_id` is specified. |
| public | no | boolean | Determines whether the LAN will have public Internet access. Can be `true` or `false`, defaults to `false`. |
| ip_failover | no | array | An array of failover groups. |

The LAN resource allows `public` and `ip_failover` properties to be updated if necessary. `ip_failover` requires the following parameters.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| ip | **yes** | string | IP address for the LAN failover. |
| nic_uuid | **yes** | string | UUID of the NIC for the LAN failover. |

### Server Resource

A Server resource has the following properties.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the server. |
| ensure | **yes** | string | The desired state of the server. It may be `present`, `absent`, `running`, or `stopped`. |
| datacenter_id | **yes** | string | The UUID of an existing virtual data center where the server will reside. Optional, if `datacenter_name` is specified. |
| datacenter_name | **yes** | string | The name of the virtual data center where the server will reside. Optional, if `datacenter_id` is specified. |
| cores | **yes** | integer | The number of CPU cores assigned to the server. |
| ram | **yes** | integer | The amount of RAM assigned to the server MB (must be a multiple of 256). |
| cpu_family | no | string | The CPU family which can be `AMD_OPTERON` or `INTEL_XEON`, defaults to `AMD_OPTERON`. |
| availability_zone | no | string | Availability zone of the server, defaults to `AUTO`. May also be set to `ZONE_1` or `ZONE_2`. |
| licence_type | no | string | If undefined the OS type will be inherited from the boot image or boot volume. |
| boot_volume | no | string | The boot volume name, if more than one volume it attached to the server. |
| purge_volumes | no | boolean | Set to `true` to purge all attached volumes on server delete, defaults to `false`. |
| volumes | no | array | An array of volumes that will be built and attached to the server. |
| nics | no | array | An array of NICs that will be connected to the server. |

**Note**: `availability_zone`, `boot_volume`, `cores`, `cpu_family` and `ram` are mutable properties. The values of these properties can be updated after the server has been created.

### Volume Resource

Volume resources can be managed independently within a data center or as a nested array defined within the server resource.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the volume. |
| ensure | **yes** | string | The desired state of the volume resource, `present` or `absent`. |
| size | **yes** | integer | Size of the volume in GB. |
| volume_type | **yes** | string | The volume type can be `HDD` or `SSD`. |
| image_id | no | string | UUID of the image to assign to the volume. |
| image_alias | no | string | The alias of the image to assign to the volume. |
| licence_type | no | string | The licence type of the volume. May be set to: `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, or `OTHER`. |
| image_password | no | string | One-time password is set on the Image for the appropriate account. |
| bus | no | string | The bus type of volume, can be `VIRTIO` or `IDE`, defaults to `VIRTIO`. |
| ssh_keys | no | string | A list of public SSH keys to add to supported image. |
| availability_zone | no | string | Direct a storage volume to be created in one of three zones per location. This allows for the deployment of enhanced high-availability configurations. Valid values for `availability_zone` are: `AUTO`, `ZONE_1`, `ZONE_2`, or `ZONE_3`. |

**Notes:**

* The volume `size` can be increased after the volume is created.
* When managing a volume independently, either the `datacenter_id` or `datacenter_name` is required.
* Either `image_id`, `image_alias` or `licence_type` **must** be defined.
* When using a ProfitBricks provided public `image_id` or `image_alias` either `image_password` or `ssh_keys` **must** be set. You **may** set both if you wish.

If the volume is **NOT** nested under a server resource, then one of the following parameters is required.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| datacenter_id | **yes** | string | The UUID of an existing virtual data center where the volume is or will be created. Optional, if `datacenter_name` is specified. |
| datacenter_name | **yes** | string | The name of the virtual data center where the volume is or will be created. Optional, if `datacenter_id` is specified. |

### NIC Resource

NICs can be created and managed separately just like other resources such as LANs. They may also be nested under a server resource.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the NIC. |
| ensure | **yes** | string | The desired state of the NIC resource, `present` or `absent`. |
| ips | **yes** | array |  An array of IP addresses to assign the NIC. |
| dhcp | no | boolean | Enable DHCP on the NIC with `true` or disable with `false`, defaults to `true`. |
| lan | **yes** | string | Name of the LAN to connect the NIC. |
| firewall_rules | no | array | An array of firewall rules to assign the NIC. |
| nat | no | boolean | A boolean which indicates if the NIC will perform Network Address Translation. There are a few requirements listed in Notes below this table. |

**Notes on NAT**:

* The NIC this is being activated on **must** belong to a private LAN.
* The NIC **must not** belong to a load balancer.
* NAT **cannot** be activated in a private LAN that contains an IPv4 address ending with ".1".
* NAT **should not** be enabled in a virtual data center with an active ProfitBricks firewall.

**Note**: `ips`, `dhcp`, `lan` and `nat` are mutable properties.

If the NIC is **NOT** nested under a server resource, some of the following parameters are required as well.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| datacenter_id | **yes** | string | The UUID of an existing virtual data center where the NIC is or will be created. Optional, if `datacenter_name` is specified. |
| datacenter_name | **yes** | string | The name of the virtual data center where the NIC is or will be created. Optional, if `datacenter_id` is specified. |
| server_id  | **yes** | string | The UUID of an existing server where the NIC will reside. Optional, if `server_name` is specified. |
| server_name | **yes** | string | The name of the server where the NIC will reside. Optional, if `server_id` is specified. |
| firewall_active | no | boolean | `true` indicates the firewall is active. Default value is `false`. |

### Firewall Rule Resource

Firewall rules are usually nested within `nics` under the server resource. This section applies to the ProfitBricks firewall for a virtual data center that you can also configure through the DCD or via the Cloud API. It does **NOT** refer to a firewall that is part of the OS or running as service on the virtual machine.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the firewall rule. |
| ensure | **yes** | string | The desired state of the firewall rule resource, `present` or `absent`. |
| protocol | **yes** | string | Allow traffic protocols including `TCP`, `UDP`, `ICMP`, and `ANY`. |
| source_mac | no | string | Allow traffic from the source MAC address. |
| source_ip | no | string | Allow traffic originating from the source IP address. |
| target_ip | no | string | Allow traffic destined to the target IP address. |
| port_range_start | no | string | Defines the start range of the allowed port (from 1 to 65534) if protocol TCP or UDP is chosen. |
| port_range_end | no | string | Defines the end range of the allowed port (from 1 to 65534) if the protocol TCP or UDP is chosen. |
| icmp_type | no | string | Defines the allowed type (from 0 to 254) if the protocol ICMP is chosen. |
| icmp_code | no | string | Defines the allowed code (from 0 to 254) if protocol ICMP is chosen. |

**Note**: `source_mac`, `source_ip`, `target_ip`, `port_range_start`, `port_range_end`, `icmp_type` and `icmp_code` are mutable properties.

If firewall rules are managed as an independent resource, the associated virtual data center, server, and NIC must be specified.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| datacenter_id | **yes** | string | The UUID of an existing virtual data center where the firewall rule is or will be created. Optional, if `datacenter_name` is specified. |
| datacenter_name | **yes** | string | The name of the virtual data center where the firewall rule is or will be created. Optional, if `datacenter_id` is specified. |
| server_id  | **yes** | string | The UUID of an existing server where the firewall rule will reside. Optional, if `server_name` is specified. |
| server_name | **yes** | string | The name of the server where the firewall rule will reside. Optional, if `server_id` is specified. |
| nic | **yes** | string | The name of the NIC the firewall rule will be added to. |


### IP Block Resource

IP Block resources must have the following properties set.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the IP Block. |
| ensure | **yes** | string | The desired state of the IP Block, `present` or `absent`. |
| location | **yes** | string | The ProfitBricks location of the IP Block: `us/las`, `us/ewr`, `de/fkb`, or `de/fra` |
| size | **yes** | integer | The size of the IP Block. |


### Snapshot Resource

Snapshot resources may have the following properties set at the creation time.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the snapshot. |
| ensure | **yes** | string | The desired state of the snapshot resource, `present` or `absent`. |
| datacenter | **yes** | integer | The ID or name of the virtual data center where the volume resides. |
| volume | **yes** | string | The ID or name of the volume used to create/restore the snapshot. |
| description | no | string | The snapshot's description. |

In addition, the following properties can be updated after the snapshot resource is created.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| cpu_hot_plug | no | boolean | Set to true to enable CPU hot plug capability. |
| cpu_hot_unplug | no | boolean | Set to true to enable CPU hot unplug capability. |
| ram_hot_plug | no | boolean | Set to true to enable memory hot plug capability. |
| ram_hot_unplug | no | boolean | Set to true to enable memory hot unplug capability. |
| nic_hot_plug | no | boolean | Set to true to enable NIC hot plug capability. |
| nic_hot_unplug | no | boolean | Set to true to enable NIC hot unplug capability. |
| disc_virtio_hot_plug | no | boolean | Set to true to enable VirtIO drive hot plug capability. |
| disc_virtio_hot_unplug | no | boolean | Set to true to enable VirtIO drive hot unplug capability. |
| disc_scsi_hot_plug | no | boolean | Set to true to enable SCSI drive hot plug capability. |
| disc_scsi_hot_unplug | no | boolean | Set to true to enable SCSI drive hot unplug capability. |
| licence_type | no | string | The licence type of the snapshot. May be set to: `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, or `OTHER`. |

To restore a snapshot set `restore => true` in the resource manifest.
The snapshot will be restored onto the volume specified by the `volume` property in the data center specified by the `datacenter` property.

**Note:** The restore operation will be performed each time the manifest has been applied, as long as the `restore` property is set to `true`.


### ProfitBricks Group Resource

ProfitBricks group resource exposes the following properties.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the group. |
| ensure | **yes** | string | The desired state of the group resource, `present` or `absent`. |
| create_datacenter | no | boolean | Indicates if the group is allowed to create virtual data centers. |
| create_snapshot | no | boolean | Indicates if the group is allowed to create snapshots. |
| reserve_ip | no | boolean | Indicates if the group is allowed to reserve IP addresses. |
| access_activity_log | no | boolean | Indicates if the group is allowed to access the activity log. |
| members | no | array | An array of strings representing non-administrator users (email addresses) to associate with the group. |

Excluding the group name, all the listed properties can be updated after the resource is created.
Specify `members => []` to remove all users from the group.


### ProfitBricks User Resource

ProfitBricks group resources can have the following properties set.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| firstname | **yes** | string | The first name of the user. |
| lastname | **yes** | string | The last name of the user. |
| ensure | **yes** | string | The desired state of the user resource, `present` or `absent`. |
| email | **yes** | string | The email address of the user. Serves as the resource name as well. |
| password | **yes** | string | The password for the user. |
| administrator | no | boolean | Indicates whether or not the user have administrative rights. |
| force_sec_auth | no | boolean | Indicates if secure (two-factor) authentication should be forced for the user. |
| groups | no | array | An array of strings representing ProfitBricks groups where a non-administrator user is to be added. |

Excluding the `email` and `password`, all the listed properties can be updated after the resource is created.
Specify `groups => []` to remove the user from all groups.


### Share Resource

Share resources can have the following properties set.

| Name | Required | Type | Description |
| --- | :-: | --- | --- |
| name | **yes** | string | The name of the share. |
| ensure | **yes** | string | The desired state of the share resource, `present` or `absent`. |
| group_id | **yes** | string | The UUID of an existing group where the share will be available. Optional, if `group_name` is specified. |
| group_name | **yes** | string | The name of an existing the group where the share will be available. Optional, if `group_id` is specified. |
| edit_privilege | no | boolean | Indicates if the group has permission to edit privileges on the resource. |
| share_privilege | no | boolean | Indicates if the group has permission to share the resource. |

`edit_privilege` and `share_privilege` can be updated after the resource is created.


### Image Resource

Image resource provider can be used only to obtain a single resource or list all available ProfitBricks images.

```
puppet resource image [profitbricks_image_name]
```


### Location Resource

Location resource provider can be used only to obtain a single resource or list all available ProfitBricks locations.

```
puppet resource location [profitbricks_location_name]
```


## Support

* Consult the [ProfitBricks Cloud API](https://devops.profitbricks.com/api/cloud/) documentation.
* Ask a question or discuss this module by visiting the [ProfitBricks DevOps Central](https://devops.profitbricks.com/community) community.
* Report an [issue in the GitHub project repository](https://github.com/profitbricks/profitbricks-puppet/issues).

## Testing

Make sure you have the necessary dependencies installed in your development environment with `bundle`. Then use `rake` to run all the available tests.

You can accomplish this by running the following commands from inside the repository root.

    bundle install
    rake spec

A successful test run should return output similar to:

    ............................................................

    Finished in 28.12 seconds (files took 2.59 seconds to load)
    60 examples, 0 failures

You can bypass `rake` and run a single test using `rspec` and supplying a path to the specific test. To do this for the *datacenter* test:

    rspec spec/unit/provider/datacenter/v1_spec.rb

    ..

    Finished in 0.06585 seconds (files took 2.28 seconds to load)
    2 examples, 0 failures

## Build and Install the Module

These instructions would only be necessary if you want to build the module yourself rather than use a pre-built one. You **DO NOT** need to do this if you followed the [installation instructions](#installation) above.

Clone the repository from [GitHub : profitbricks-puppet](https://github.com/profitbricks/profitbricks-puppet).

Run the following from the repository directory.

    cd profitbricks-puppet
    puppet module build
    puppet module install -f pkg/profitbricks-profitbricks-[version].tar.gz

Notes: [version] should be replaced with the module version built. For example, 1.5.0.

## Contributing

1. Fork it (`https://github.com/profitbricks/profitbricks-puppet/fork`).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new Pull Request.
