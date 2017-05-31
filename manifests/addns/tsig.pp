# == Class: opendnssec
#
# Full description of class opendnssec here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'opendnssec':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Mauricio Vergara Ereche <mave@cero32.cl>
#
# === Copyright
#
# Copyright 2015 ICANN
#
define opendnssec::addns::tsig (
  $order     = '15',
  $tsig_name = undef,
  $algorithm = 'hmac-md5',
  $secret    = undef
) {

  $addns_file = $::opendnssec::addns_file
  $tsig_algorithims = ['^hmac-(md5|sha(1|224|256|384|512))$']

  validate_absolute_path($addns_file)

  if $tsig_name {
    validate_string($tsig_name)
    $tsig_name_real = $tsig_name
  } else {
    $tsig_name_real = $name
  }

  validate_re($algorithm, $tsig_algorithims)
  validate_re($secret, '^[a-zA-Z0-9\+=]+$')

  concat::fragment{"tsig_${name}":
    target  => $addns_file,
    content => template('opendnssec/etc/opendnssec/addns-tsig.xml.erb'),
    order   => $order,
  }
}
