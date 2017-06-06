# == Class: opendnssec
#
define opendnssec::addns::tsig (
  Tea::Base64          $secret,
  Optional[String]     $tsig_name = undef,
  String               $order     = '15',
  Opendnssec::Tsigalgo $algorithm = 'hmac-md5',
) {

  include ::opendnssec
  $addns_file = $::opendnssec::addns_file

  $tsig_name_real = $tsig_name ? {
    undef   => $name,
    default => $tsig_name,
  }

  concat::fragment{"tsig_${name}":
    target  => $addns_file,
    content => template('opendnssec/etc/opendnssec/addns-tsig.xml.erb'),
    order   => $order,
  }
}
