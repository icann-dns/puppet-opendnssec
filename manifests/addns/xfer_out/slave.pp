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
define opendnssec::addns::xfer_out::slave (
  $order     = '35',
  $port      = 53,
  $address   = undef,
  $key       = undef,
  $prefix    = undef
) {

  $addns_file = $::opendnssec::addns_file

  validate_absolute_path($addns_file)
  validate_integer($port)
  unless is_ip_address($address) {
    fail("xfer address (${address}) needs to be a valid ip")
  }
  validate_string($key)
  if $prefix {
    if is_ip_address($prefix) {
      $prefix_real = $prefix
    } else {
      fail("xfer prefix (${prefix}) needs to be a valid ip")
    }
  } else {
    $prefix_real = $address
  }

  concat::fragment{"xfer_out_slave_${name}":
    target  => $addns_file,
    content => template('opendnssec/etc/opendnssec/addns-xfer-out-slave.xml.erb'),
    order   => $order,
  }
}
