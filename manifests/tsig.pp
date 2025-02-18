# @summary Add a new tsig configuration
# @param data TSIG key data
# @param algo TSIG key algorithm
# @param key_name TSIG key name
#
define opendnssec::tsig (
  String           $data,
  Opendnssec::Algo $algo     = 'hmac-sha256',
  Optional[String] $key_name = undef,
) {
  include opendnssec
  $user               = $opendnssec::user
  $group              = $opendnssec::user
  $manage_ods_ksmutil = $opendnssec::manage_ods_ksmutil
  $enabled            = $opendnssec::enabled
  $base_dir           = $opendnssec::tsigs_dir

  $_name = $key_name.lest || { $name }

  file { "${base_dir}/${_name}.xml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/tsig.xml.erb'),
  }
}
