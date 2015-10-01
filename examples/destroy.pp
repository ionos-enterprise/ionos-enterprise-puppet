$datacenter_id = '2dbf0e6b-3430-46fd-befd-6d08acd96557'

[
  server { 'frontend':
    ensure => absent,
    purge_volumes => true,
    datacenter_id => $datacenter_id
  },
  server { 'backend':
    ensure => absent,
    datacenter_id => $datacenter_id
  }
] ~>
[
  lan { 'public':
    ensure => absent,
    datacenter_id => $datacenter_id
  },
  lan { 'private':
    ensure => absent,
    datacenter_id => $datacenter_id
  }
]
