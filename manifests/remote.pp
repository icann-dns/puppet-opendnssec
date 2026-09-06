# @summary Add a new remote configuration
# @param address4 IPv4 address of the remote
# @param address6 IPv6 address of the remote
# @param tsig TSIG key name
# @param tsig_name TSIG key name
# @param sign_notifies Sign notifies
# @param send_notifies Send notifies
# @param port Port to connect to
#
define opendnssec::remote (
  Optional[Stdlib::IP::Address::V4] $address4      = undef,
  Optional[Stdlib::IP::Address::V6] $address6      = undef,
  Optional[String[1]]               $tsig          = undef,
  Optional[String[1]]               $tsig_name     = undef,
  Boolean                           $sign_notifies = false,
  Boolean                           $send_notifies = true,
  Stdlib::Port                      $port          = 53,
) {
  include opendnssec
  $user               = $opendnssec::user
  $group              = $opendnssec::group
  $tsigs              = $opendnssec::tsigs
  $enabled            = $opendnssec::enabled
  $base_dir           = $opendnssec::remotes_dir
  $services           = $opendnssec::services

  unless $address4 or $address6 {
    fail("${name} must specify either address4 or address6")
  }
  # TODO: whats the difference between tsig and tsig_name probably related to the dns module
  if $tsig {
    unless $tsig in $tsigs {
      fail("${name}: Tsig (${tsig}) is not defined")
    }
    unless $tsig_name {
      fail("${name}: you must define tsig_name when you define tsig")
    } else {
      $_tsig_name = $tsig_name
    }
  } elsif $tsig_name {
    unless $tsig_name == 'NOKEY' or $tsig_name in $tsigs {
      fail("${name}: Tsig (${tsig_name}) is not defined")
    }
    $_tsig_name = $tsig_name
  } else {
    $_tsig_name = $opendnssec::default_tsig_name
  }
  file {
    default:
      ensure => stdlib::ensure($send_notifies, file),
      owner  => $user,
      group  => $group,
      notify => Service[$services];
    "${base_dir}/${name}_notify_in.xml":
      content => template('opendnssec/etc/opendnssec/notify_in.xml.erb');
    "${base_dir}/${name}_notify_out.xml":
      content => template('opendnssec/etc/opendnssec/notify_out.xml.erb');
    "${base_dir}/${name}_providetransfer.xml":
      # TODO: should this use the provide_xfr bool?
      ensure  => file,
      content => template('opendnssec/etc/opendnssec/providetransfer.xml.erb');
    "${base_dir}/${name}_requesttransfer.xml":
      ensure  => file,
      content => template('opendnssec/etc/opendnssec/requesttransfer.xml.erb');
  }
}
