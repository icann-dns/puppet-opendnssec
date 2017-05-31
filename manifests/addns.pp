# == Class: opendnssec
#
# Full description of class opendnssec here.
#
# === Parameters
#
# Document parameters here.
#
# [*tsigs*]
#   A has of tsig parameters to pass to create_resource(opendnssec::addns::tsig, $tsigs)
#
# === Variables
#
# === Examples
#
#  class { 'opendnssec::adddns':
#    tsigs       => {
#      'name'    => {
#         secret => 'PRIVATE'
#      }
#    }
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
class opendnssec::addns (
  $tsigs          = {},
  $xfers_in       = {},
  $xfers_out      = {},
) inherits opendnssec::params {

  $user            = $::opendnssec::user
  $group           = $::opendnssec::group
  $addns_file      = $::opendnssec::addns_file
  $xferout_enabled = $::opendnssec::xferout_enabled

  validate_absolute_path($addns_file)
  validate_hash($tsigs)
  validate_hash($xfers_in)
  validate_hash($xfers_out)

  concat {$addns_file:
    owner => $user,
    group => $group,
  }
  concat::fragment{'addns_header':
    target  => $addns_file,
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!-- File managed by puppet DO NOT EDIT -->\n<Adapter>\n  <DNS>\n",
    order   => '01',
  }
  concat::fragment{'addns_footer':
    target  => $addns_file,
    content => "  </DNS>\n</Adapter>\n",
    order   => '99',
  }

  if $tsigs {
    create_resources(opendnssec::addns::tsig, $tsigs)
  }
  if $xfers_in {
    concat::fragment{'xfer_in_header':
      target  => $addns_file,
      content => "\n    <Inbound>\n",
      order   => '20',
    }
    concat::fragment{'xfer_in_footer':
      target  => $addns_file,
      content => "    </Inbound>\n",
      order   => '29',
    }
    create_resources(opendnssec::addns::xfer_in, $xfers_in)
  }
  if $xfers_out and $xferout_enabled {
    concat::fragment{'xfer_out_header':
      target  => $addns_file,
      content => "\n    <Outbound>\n",
      order   => '30',
    }
    concat::fragment{'xfer_out_footer':
      target  => $addns_file,
      content => "    </Outbound>\n",
      order   => '39',
    }
    create_resources(opendnssec::addns::xfer_out, $xfers_out)
  }
  if $::opendnssec::manage_ods_ksmutil and $opendnssec::enabled {
    exec {'Forcing ods-ksmutil to update after modifying addns.xml':
      command     => '/usr/bin/ods-ksmutil update all',
      user        => $user,
      refreshonly => true,
      subscribe   => Concat[$addns_file];
    }
  }
}
