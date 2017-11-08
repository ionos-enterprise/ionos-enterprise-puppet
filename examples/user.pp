profitbricks_user { 'john.doe.007@example.com' :
  ensure        => present,
  firstname     => 'John',
  lastname      => 'Doe',
  password      => 'Secrete.Password.007',
  administrator => true
}