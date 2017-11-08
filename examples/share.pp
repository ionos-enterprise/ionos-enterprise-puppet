$datacenter_id = '4017613d-b3fb-41bd-a7bf-8da8e1b02890'

share { $datacenter_id :
  ensure          => present,
  edit_privilege  => true,
  share_privilege => true,
  group_name      => 'cli'
}