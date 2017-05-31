# == Class: opendnssec
#
class opendnssec::addns (
  Hash                  $tsigs           = {},
  Hash                  $xfers_in        = {},
  Hash                  $xfers_out       = {},
  Boolean               $xferout_enabled = true,
  Stdlib::Absolutepath  $addns_file      = '/etc/opendnssec/addns.xml',
) {

  include ::opendnssec
  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled

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
  if $manage_ods_ksmutil and $enabled {
    exec {'Forcing ods-ksmutil to update after modifying addns.xml':
      command     => '/usr/bin/ods-ksmutil update all',
      user        => $user,
      refreshonly => true,
      subscribe   => Concat[$addns_file];
    }
  }
}
