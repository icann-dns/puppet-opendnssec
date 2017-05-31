# == Class: opendnssec
#
class opendnssec::datastore (
  $engine       = $::opendnssec::params::datastore_engine,
  $file         = $::opendnssec::params::datastore_file,
  $host         = $::opendnssec::params::datastore_host,
  $port         = $::opendnssec::params::datastore_port,
  $store_name   = $::opendnssec::params::datastore_name,
  $user         = $::opendnssec::params::datastore_user,
  $password     = $::opendnssec::params::datastore_password,

) inherits opendnssec::params {
  if $engine == 'mysql' {
    if $::opendnssec::manage_packages {
      ensure_packages(['opendnssec-enforcer-mysql'])
    }
    mysql::db {$store_name:
      user     => $user,
      password => $password,
    } -> file {'/usr/local/bin/backup-hsm-mysql.sh':
      ensure => present,
      mode   => '0755',
      owner  => 'root',
      group  => $opendnssec::group,
      source => 'puppet:///modules/opendnssec/backup-hsm-mysql.sh';
    } -> cron {'backup-hsm-mysql':
      ensure  => present,
      command => '/usr/local/bin/backup-hsm-mysql.sh',
      user    => 'root',
      hour    => '*/6',
      minute  => 0,
    }
  } elsif $engine == 'sqlite' {
    ensure_packages(['opendnssec-enforcer-sqlite'])
  }
}
