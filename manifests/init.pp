# == Class: opendnssec
#
class opendnssec (
  Boolean              $enabled                = true,
  Boolean              $xferout_enabled        = true,
  String               $user                   = 'root',
  String               $group                  = 'root',

  Boolean              $manage_packages        = true,
  Boolean              $manage_datastore       = true,
  Boolean              $manage_service         = true,
  Boolean              $manage_ods_ksmutil     = true,
  Boolean              $manage_conf            = true,

  Boolean              $manage_policies        = true,
  Hash                 $policies               = {},

  Boolean              $manage_zones           = true,
  Hash                 $zones                  = {},

  Boolean              $manage_addns           = true,
  Hash                 $addns_tsigs            = {},
  Hash                 $addns_xfers_in         = {},
  Hash                 $addns_xfers_out        = {},

  Integer[0,7]         $logging_level          = 3,
  String[20]           $logging_facility       = 'loacl0',

  String[100]          $repository_name        = 'thales',
  Stdlib::Absolutepath $repository_module      = '/opt/nfast/toolkits/pkcs11/libcknfast.so',
  String[100]          $repository_pin         = '11223344',
  Optional[Interger]   $repository_capacity    = undef,
  String[100]          $repository_token_label = 'OpenDNSSEC',

  Opendnsec::Datastore $datastore_engine       = 'mysql',
  Stdlib::Absolutepath $datastore_file         = '/var/lib/opendnssec/kasp.db',
  Tea::Host            $datastore_host         = 'localhost',
  Tea::Port            $datastore_port         = 3306,
  String[100]          $datastore_name         = 'kasp',
  String[100]          $datastore_user         = 'opendnssec',
  String[100]          $datastore_password     = 'change_me',

  Stdlib::Absolutepath $policy_file            = '/etc/opendnssec/kasp.xml',
  Stdlib::Absolutepath $zone_file              = '/etc/opendnssec/zonelist.xml',
  Stdlib::Absolutepath $addns_file             = '/etc/opendnssec/addns.xml',

) inherits opendnssec::params {

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
    service {
      ['pe-puppet']:
        ensure => 'stopped',
        enable => false,
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
      if $manage_packages {
        ensure_packages(['opendnssec-enforcer-mysql'])
      }
      mysql::db {$datastore_name:
        user     => $datastore_user,
        password => $datastore_password,
      }
    } elsif $datastore_engine == 'sqlite' {
      ensure_packages(['opendnssec-enforcer-sqlite'])
    }
  }
  if $manage_policies {
    class {'::opendnssec::policies':
      policies => $policies,
    }
  }
  if $manage_zones {
    class {'::opendnssec::zones':
      zones => $zones,
    }
  }
  if $manage_addns {
    class {'::opendnssec::addns':
      tsigs     => $addns_tsigs,
      xfers_in  => $addns_xfers_in,
      xfers_out => $addns_xfers_out,
    }
  }
}
