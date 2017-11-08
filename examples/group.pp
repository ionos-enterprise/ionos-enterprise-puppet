profitbricks_group { 'Puppet Test' :
  ensure              => present,
  create_datacenter   => false,
  create_snapshot     => false,
  reserve_ip          => true,
  access_activity_log => true,
  members             => []
}