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
define opendnssec::addns::xfer_out (
  $slaves = {},
  $remotes    = {},
) {

  $addns_file = $::opendnssec::addns_file

  validate_absolute_path($addns_file)
  validate_hash($slaves)
  validate_hash($remotes)
  if $slaves {
    concat::fragment{"xfer_out_providetransfer_header_${name}":
      target  => $addns_file,
      content => "      <ProvideTransfer>\n",
      order   => '31',
    }
    concat::fragment{"xfer_out_providetransfer_footer_${name}":
      target  => $addns_file,
      content => "\n      </ProvideTransfer>\n",
      order   => '33',
    }
    create_resources(opendnssec::addns::xfer_out::slave,  $slaves)
  }
  if $remotes {
    concat::fragment{"xfer_out_notify_header_${name}":
      target  => $addns_file,
      content => "      <Notify>\n",
      order   => '34',
    }
    concat::fragment{"xfer_out_notify_footer_${name}":
      target  => $addns_file,
      content => "\n      </Notify>\n",
      order   => '36',
    }
    create_resources(opendnssec::addns::xfer_out::remote, $remotes)
  }
}
