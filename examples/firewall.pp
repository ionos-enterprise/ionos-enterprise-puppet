$datacenter_name = 'testdc1'
$server_name = 'worker1'
$nic = 'testnic'

firewall_rule { 'HTTP':
  datacenter_name => $datacenter_name,
  server_name => $server_name,
  nic => $nic,
  protocol => 'TCP',
  port_range_start => 80,
  port_range_end => 83,
  source_mac => '12:47:e9:b1:77:b4',
  source_ip => '10.81.12.123',
  target_ip => '10.81.12.124'
}