# == Class: opendnssec
#
class opendnssec (
  Boolean               $enabled                = true,
  String[1,32]          $user                   = 'root',
  String[1,32]          $group                  = 'root',

  Boolean               $manage_packages        = true,
  Boolean               $manage_datastore       = true,
  Boolean               $manage_service         = true,
  Boolean               $manage_ods_ksmutil     = true,
  Boolean               $manage_conf            = true,

  Integer[1,7]          $logging_level          = 3,
  Tea::Syslogfacility   $logging_facility       = 'local0',

  String[1,100]         $repository_name        = 'SoftHSM',
  Stdlib::Absolutepath  $repository_module      = '/usr/lib/softhsm/libsofthsm.so',
  String[1,100]         $repository_pin         = '1234',
  Optional[Integer]     $repository_capacity    = undef,
  String[1,100]         $repository_token_label = 'OpenDNSSEC',
  Boolean               $skip_publickey         = true,
  Boolean               $require_backup         = false,

  Opendnssec::Datastore $datastore_engine       = 'mysql',
  Tea::Host             $datastore_host         = 'localhost',
  Tea::Port             $datastore_port         = 3306,
  String[1,100]         $datastore_name         = 'kasp',
  String[1,100]         $datastore_user         = 'opendnssec',
  String[1,100]         $datastore_password     = 'change_me',

  Stdlib::Absolutepath  $policy_file            = '/etc/opendnssec/kasp.xml',
  Stdlib::Absolutepath  $zone_file              = '/etc/opendnssec/zonelist.xml',
  Stdlib::Absolutepath  $addns_file             = '/etc/opendnssec/addns.xml',

  Hash                  $zones                  = {},
  Hash                  $policies               = {},
  Hash                  $remotes                = {},
  Array[String]         $default_masters        = [],
  Array[String]         $default_provide_xfrs   = [],

) {

  if $manage_packages {
    ensure_packages(['opendnssec'])
    file {'/var/lib/opendnssec':
      ensure  => 'directory',
      mode    => '0640',
      recurse => true,
      owner   => $user,
      group   => $group;
    }
  }
  if $enabled and $manage_service {
    service {
      ['opendnssec-enforcer', 'opendnssec-signer']:
        ensure => running,
        enable => true,
    }
  }
  if $manage_conf {
    file { '/etc/opendnssec/conf.xml':
      ensure  => 'file',
      mode    => '0644',
      owner   => $user,
      group   => $group,
      content => template('opendnssec/etc/opendnssec/conf.xml.erb');
    }
    if $enabled {
      if $manage_ods_ksmutil {
        exec {'ods-ksmutil updated conf.xml':
          command     => '/usr/bin/ods-ksmutil update all',
          user        => $user,
          refreshonly => true,
          subscribe   => File['/etc/opendnssec/conf.xml'],
        }
      }
      file {'/etc/opendnssec/MASTER':
        ensure => 'file',
        mode   => '0644',
        owner  => $user,
        group  => $group;
      }
    } else {
      file {'/etc/opendnssec/MASTER':
        ensure => 'absent',
      }
    }
  }
  if $manage_datastore {
    if $datastore_engine == 'mysql' {
      require  ::mysql::server
      mysql::db {$datastore_name:
        user     => $datastore_user,
        password => $datastore_password,
      }
      if $manage_packages {
        ensure_packages(['opendnssec-enforcer-mysql'])
      }
    } elsif $datastore_engine == 'sqlite' {
      ensure_packages(['opendnssec-enforcer-sqlite'])
    }
  }
  if ! empty($policies) {
    if defined(Class['opendnssec::policies']) {
      warning('setting policies and calling opendnssec::policies directly is not supported.  do one or the other')
    } else {
      class { '::opendnssec::policies': policies => $policies }
    }
  }
  if ! empty($zones) {
    if defined(Class['opendnssec::zones']) {
      warning('setting zones and calling opendnssec::zones directly is not supported.  do one or the other')
    } else {
      class { '::opendnssec::zones': zones => $zones }
    }
  }
}
