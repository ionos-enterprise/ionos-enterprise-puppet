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