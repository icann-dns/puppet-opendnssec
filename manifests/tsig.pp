# == Define: opendnssec::tsig
#
define opendnssec::tsig (
    String           $data,
    Opendnssec::Algo $algo     = 'hmac-sha256',
    Optional[String] $key_name = undef,
) {
  include ::opendnssec
  $user               = $::opendnssec::user
  $group              = $::opendnssec::user
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled
  $base_dir           = $::opendnssec::tsigs_dir

  $_name = $key_name ? {
    undef   => $name,
    default => $key_name,
  }
  file{ "${base_dir}/${_name}.xml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/tsig.xml.erb'),
  }
}
