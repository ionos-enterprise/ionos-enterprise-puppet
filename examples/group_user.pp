$group_name = 'operators'

profitbricks_group { $group_name :
  ensure              => present,
  create_datacenter   => true,
  create_snapshot     => true,
  reserve_ip          => true,
  access_activity_log => false
} ->

profitbricks_user { 'operator.abc@mydomain.org' :
  ensure        => present,
  firstname     => 'John',
  lastname      => 'Doe',
  password      => 'Secrete.Password.007',
  administrator => false,
  groups        => [$group_name]
}