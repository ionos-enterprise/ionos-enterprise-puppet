lan { 'testfo' :
  ensure          => present,
  public          => true,
  datacenter_name => 'FailoverTest',
  ip_failover     => [
    {
      ip       => '192.152.28.17',
      nic_uuid => 'bd8cca6b-4098-40ff-b3e6-db4f0de5afc8'
    }
  ]
}