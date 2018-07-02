# == Define: opendnssec::tsig
#
define opendnssec::remote (
  Optional[Variant[Tea::Ipv4, Tea::Ipv4_cidr]] $address4             = undef,
  Optional[Variant[Tea::Ipv6, Tea::Ipv6_cidr]] $address6             = undef,
  Optional[String]                             $tsig                 = undef,
  Optional[String]                             $tsig_name            = undef,
  Optional[String]                             $tsig_name_transfer_request = undef,
  Optional[String]                             $tsig_name_transfer_provide = undef,
  Optional[String]                             $tsig_name_notify_in  = undef,
  Optional[String]                             $tsig_name_notify_out = undef,
  Tea::Port                                    $port                 = 53,
) {
  include ::opendnssec
  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
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
    if $tsig_name {
      $_tsig_name_transfer_request = $tsig_name
      $_tsig_name_transfer_provide = $tsig_name

    } elsif ! $tsig_name_transfer_request or ! $tsig_name_transfer_provide {
      if ! $tsig_name_transfer_request {
        fail("${name}: you must define tsig_name when you define tsig")
      } else {
        $_tsig_name_transfer_request = $tsig_name_transfer_request
      }

      if ! $tsig_name_transfer_provide {
        fail("${name}: you must define tsig_name when you define tsig")
      } else {
        $_tsig_name_transfer_provide = $tsig_name_transfer_provide
      }
    }
    else {
      fail("${name}: you must define tsig_name when you define tsig")
    }

    if $tsig_name_notify_in and $tsig_name_notify_in != '' {
      $_tsig_name_notify_in = $tsig_name_notify_in
    } else {
      $_tsig_name_notify_in = $::opendnssec::default_tsig_name
    }

    if $tsig_name_notify_out and $tsig_name_notify_out != '' {
      $_tsig_name_notify_out = $tsig_name_notify_out
    } else {
      $_tsig_name_notify_out = $::opendnssec::default_tsig_name
    }
  } else {
    if $tsig_name and $tsig_name != '' {
      if defined(Opendnssec::Tsig[$tsig_name]) or $tsig_name == 'NOKEY' {
        $_tsig_name_transfer_request = $tsig_name
        $_tsig_name_transfer_provide = $tsig_name
      } else {
        fail("${name}: Opendnssec::Tsig['${tsig_name}'] does not exist")
      }
    } else {
      if $tsig_name_transfer_request and $tsig_name_transfer_request != '' {
        if defined(Opendnssec::Tsig[$tsig_name_transfer_request]) or $tsig_name_transfer_request == 'NOKEY' {
          $_tsig_name_transfer_request = $tsig_name_transfer_request
        } else {
          fail("${name}: Opendnssec::Tsig['${tsig_name_transfer_request}'] does not exist")
        }
      } else {
        $_tsig_name_transfer_request = $::opendnssec::default_tsig_name
      }

      if $tsig_name_transfer_provide and $tsig_name_transfer_provide != '' {
        if defined(Opendnssec::Tsig[$tsig_name_transfer_provide]) or $tsig_name_transfer_provide == 'NOKEY' {
          $_tsig_name_transfer_provide = $tsig_name_transfer_provide
        } else {
          fail("${name}: Opendnssec::Tsig['${tsig_name_transfer_provide}'] does not exist")
        }
      } else {
        $_tsig_name_transfer_provide = $::opendnssec::default_tsig_name
      }
    }

    if $tsig_name_notify_in and $tsig_name_notify_in != '' {
      if defined(Opendnssec::Tsig[$tsig_name_notify_in]) or $tsig_name_notify_in == 'NOKEY' {
        $_tsig_name_notify_in = $tsig_name_notify_in
      } else {
        fail("${name}: Opendnssec::Tsig['${tsig_name_notify_in}'] does not exist")
      }
    } else {
      $_tsig_name_notify_in = $::opendnssec::default_tsig_name
    }

    if $tsig_name_notify_out and $tsig_name_notify_out != '' {
      if defined(Opendnssec::Tsig[$tsig_name_notify_out]) or $tsig_name_notify_out == 'NOKEY' {
        $_tsig_name_notify_out = $tsig_name_notify_out
      } else {
        fail("${name}: Opendnssec::Tsig['${tsig_name_notify_out}'] does not exist")
      }
    } else {
      $_tsig_name_notify_out = $::opendnssec::default_tsig_name
    }
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
  if $manage_ods_ksmutil and $enabled {
    exec {"Forcing ods-ksmutil to update after modifying remote ${name}":
      command     => '/usr/bin/yes | /usr/bin/ods-ksmutil update all',
      user        => $user,
      refreshonly => true,
      subscribe   => File[
        "${base_dir}/${name}_notify_out.xml",
        "${base_dir}/${name}_providetransfer.xml",
        "${base_dir}/${name}_notify_in.xml",
        "${base_dir}/${name}_requesttransfer.xml",
      ],
    }
  }
}
