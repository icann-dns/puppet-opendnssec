# == Class: opendnssec
#
define opendnssec::addns (
  Array                 $masters         = [],
  Array                 $provide_xfrs    = [],
) {

  include ::opendnssec
  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled
  $remotes            = $::opendnssec::remotes
  $tsigs              = $::opendnssec::tsigs
  $xferout_enabled    = $::opendnssec::xferout_enabled
  $default_tsig_name  = $::opendnssec::default_tsig_name

  file { "/etc/opendnssec/addns-${name}.xml":
    owner => $user,
    group => $group,
    content => template('opendnssec/etc/opendnssec/addns.xml.erb'),
  }
  if $manage_ods_ksmutil and $enabled {
    exec {"Forcing ods-ksmutil to update after modifying addns-${name}.xml":
      command     => '/usr/bin/ods-ksmutil update all',
      user        => $user,
      refreshonly => true,
      subscribe   => File["/etc/opendnssec/addns-${name}.xml"],
    }
  }
}
