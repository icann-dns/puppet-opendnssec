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
define opendnssec::addns::xfer_in (
  $peers     = {},
  $remotes   = {},
) {

  $addns_file = $::opendnssec::addns_file

  validate_absolute_path($addns_file)
  validate_hash($peers)
  validate_hash($remotes)

  if $remotes {
    concat::fragment{"xfer_in_remotes_${name}_header":
      target  => $addns_file,
      content => "      <RequestTransfer>\n",
      order   => '21',
    }
    concat::fragment{"xfer_in_remotes_${name}_footer":
      target  => $addns_file,
      content => "      </RequestTransfer>\n",
      order   => '23',
    }
    create_resources(opendnssec::addns::xfer_in::remote, $remotes)
  }
  if $peers {
    concat::fragment{"xfer_in_peers_${name}_header":
      target  => $addns_file,
      content => "      <AllowNotify>\n",
      order   => '24',
    }
    concat::fragment{"xfer_in_peers_${name}_footer":
      target  => $addns_file,
      content => "      </AllowNotify>\n",
      order   => '26',
    }
    create_resources(opendnssec::addns::xfer_in::peer, $peers)
  }
}
