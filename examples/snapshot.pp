$datacenter_name = 'PPSnapshotTest'
$volume_name = 'staging'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/ewr'
} ->

volume { $volume_name :
  ensure          => present,
  datacenter_name => $datacenter_name,
  size            => 10,
  volume_type     => 'HDD',
  image_alias     => 'ubuntu:latest',
  ssh_keys        => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...']
} ->

snapshot { 'PPTestSnapshot' :
  ensure     => present,
  datacenter => $datacenter_name,
  volume     => $volume_name
}