# Replace the datacenter_id below with an existing datacenter id
$datacenter_id = '67eb66ac-712f-40be-bb1e-b03dcc0a27c8'

lan { 'private' :
  ensure => present,
  public => false,
  datacenter_id => $datacenter_id
} ->

lan { 'public' :
  ensure => present,
  public => true,
  datacenter_id => $datacenter_id
} ->

server { 'frontend' :
  ensure => present,
  cores => 1,
  datacenter_id => $datacenter_id,
  ram => 1024,
  volumes => [
    {
      name => 'system',
      size => 10,
      bus => 'VIRTIO',
      volume_type => 'SSD',
      image_id => '82fcd652-b785-11e6-9724-525400f64d8d',
      image_password => 'secretpassword2015',
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
        },
        { 
          name => 'HTTP',
          protocol => 'TCP',
          port_range_start => 80,
          port_range_end => 80
        }
      ]
    },
    {
      name => 'private',
      dhcp => true,
      lan => 'private',
      nat => false,
    }
  ]
} ->

server { 'backend' :
  ensure => present,
  datacenter_id => $datacenter_id,
  cores => 1,
  cpu_family => 'INTEL_XEON',
  ram => 1024,
  volumes => [
    {
      name => 'system',
      size => 5,
      bus => 'VIRTIO',
      volume_type => 'HDD',
      availability_zone => 'AUTO',
      image_id => '82fcd652-b785-11e6-9724-525400f64d8d',
      image_password => 'secretpassword2015',
      ssh_keys => [ 'ssh-rsa AAAAB3NzaC1yc2EAA...' ]
    },
    {
      name => 'data',
      size => 10,
      bus => 'VIRTIO',
      volume_type => 'SSD',
      licence_type => 'OTHER',
      availability_zone => 'AUTO',
    }
  ],
  nics => [
    {
      name => 'primary',
      dhcp => true,
      lan => 'private',
      nat => false,
      firewall_rules => [
        {
          name => 'SSH',
          protocol => 'TCP',
          port_range_start => 22,
          port_range_end => 22
        },
        {
          name => 'MySQL',
          protocol => 'TCP',
          port_range_start => 3306,
          port_range_end => 3306
        }
      ]
    }
  ]
}
