$datacenter_name = 'testdc1'
$server_name = 'worker1'
$lan_name = 'public1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'de/fkb',
  description => 'my data center desc.'
} ->

lan { $lan_name :
  ensure => present,
  public => true,
  datacenter_name => $datacenter_name
} ->

server { $server_name :
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
  ]
} ->

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
    },
    { 
      name => 'HTTP',
      protocol => 'TCP',
      port_range_start => 80,
      port_range_end => 80
    }
  ]
}
