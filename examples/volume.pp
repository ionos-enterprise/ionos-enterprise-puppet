$datacenter_name = 'TestDataCenter'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las'
} ->

volume { 'testvolume' :
  ensure            => present,
  datacenter_name   => $datacenter_name,
  image_id          => 'adf0c2e4-e83b-11e6-a994-525400f64d8d',
  size              => 50,
  volume_type       => 'SSD',
  ssh_keys          => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...']
}
