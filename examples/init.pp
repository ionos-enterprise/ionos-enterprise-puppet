$datacenter_id = '2dbf0e6b-3430-46fd-befd-6d08acd96557'

lan { 'private' :
  ensure => present,
  public => false,
  datacenter_id => $datacenter_id
}

lan { 'public' :
  ensure => present,
  public => true,
  datacenter_id => $datacenter_id
}

server { 'frontend' :
  ensure => present,
  datacenter_id => $datacenter_id,
  cores  => 1,
  ram    => 1024,
  volumes => [
    {
      name => 'system',
      size => 20,
      bus => 'VIRTIO',
      image_id => 'e87692f2-3587-11e5-9b0d-52540066fee9',
      image_password => 'secretpassword2015'
    }
  ],
  nics => [
    {
      name => 'public',
      dhcp => true,
      lan => 'public',
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
    }
  ]
}

server { 'backend' :
  ensure => present,
  datacenter_id => $datacenter_id,
  cores  => 1,
  ram    => 1024,
  volumes => [
    {
      name => 'system',
      size => 10,
      bus => 'VIRTIO',
      image_id => 'e87692f2-3587-11e5-9b0d-52540066fee9',
      image_password => 'secretpassword2015'
    }
  ],
  nics => [
    {
      name => 'primary',
      dhcp => true,
      lan => 'private',
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
