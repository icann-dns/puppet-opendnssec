# == Class: opendnssec::conf
#
class opendnssec::conf (
  $datastore_engine       = $::opendnssec::params::datastore_engine,
  $datastore_file         = $::opendnssec::params::datastore_file,
  $datastore_host         = $::opendnssec::params::datastore_host,
  $datastore_port         = $::opendnssec::params::datastore_port,
  $datastore_name         = $::opendnssec::params::datastore_name,
  $datastore_user         = $::opendnssec::params::datastore_user,
  $datastore_password     = $::opendnssec::params::datastore_password,
  $logging_level          = $::opendnssec::params::logging_level,
  $logging_facility       = $::opendnssec::params::logging_facility,
  $repository_name        = $::opendnssec::params::repository_name,
  $repository_module      = $::opendnssec::params::repository_module,
  $repository_pin         = $::opendnssec::params::repository_pin,
  $repository_capacity    = $::opendnssec::params::repository_capacity,
  $repository_token_label = $::opendnssec::params::repository_token_label,
) inherits opendnssec::params {

  file { '/etc/opendnssec/conf.xml':
    ensure  => 'present',
    mode    => '0644',
    owner   => $::opendnssec::user,
    group   => $::opendnssec::group,
    content => template('opendnssec/etc/opendnssec/conf.xml.erb');
  }
  if $opendnssec::manage_ods_ksmutil and $opendnssec::enabled {
    exec {'ods-ksmutil updated conf.xml':
      command     => '/usr/bin/ods-ksmutil update all',
      user        => $::opendnssec::user,
      refreshonly => true,
      subscribe   => File['/etc/opendnssec/conf.xml'],
    }
  }
  if $opendnssec::enabled {
    file {'/etc/opendnssec/MASTER':
      ensure  => 'file',
      mode    => '0644',
      recurse => true,
      owner   => $::opendnssec::user,
      group   => $::opendnssec::group;
    }
  } else {
    file {
      '/etc/opendnssec/MASTER':
        ensure  => 'absent'
    }
  }
}
