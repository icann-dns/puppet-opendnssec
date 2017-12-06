# == Define: opendnssec::tsig
#
define opendnssec::remote (
  Optional[Variant[Tea::Ipv4, Tea::Ipv4_cidr]] $address4  = undef,
  Optional[Variant[Tea::Ipv6, Tea::Ipv6_cidr]] $address6  = undef,
  Optional[String]                             $tsig      = undef,
  Optional[String]                             $tsig_name = undef,
  Tea::Port                                    $port      = 53,
) {
  include ::opendnssec
  $user               = $::opendnssec::user
  $group              = $::opendnssec::user
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled
  $base_dir           = $::opendnssec::remotes_dir

  if ! $address4 and ! $address6 {
    fail("${name} must specify either address4 or address6")
  }
  if $tsig {
    if ! defined(Opendnssec::Tsig[$tsig]) {
      fail("${name}: Opendnssec::Tsig['${tsig}'] does not exist")
    }
    if ! $tsig_name {
      fail("${name}: you must define tsig_name when you deinfe tsig")
    } else {
      $_tsig_name = $tsig_name
    }
  } elsif $tsig_name and $tsig_name != '' {
    if defined(Opendnssec::Tsig[$tsig_name]) or $tsig_name == 'NOKEY' {
      $_tsig_name = $tsig_name
    } else {
      fail("${name}: Opendnssec::Tsig['${tsig_name}'] does not exist")
    }
  } else {
    $_tsig_name = $::opendnssec::default_tsig_name
  }
  file{ "${base_dir}/${name}_requesttransfer.xml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/requesttransfer.xml.erb'),
  }
  file{ "${base_dir}/${name}_notify_in.xml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/notify_in.xml.erb'),
  }
  file{ "${base_dir}/${name}_providetransfer.xml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/providetransfer.xml.erb'),
  }
  file{ "${base_dir}/${name}_notify_out.xml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/notify_out.xml.erb'),
  }
}
