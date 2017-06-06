# == Class: opendnssec
#
class opendnssec::addns (
  Hash                  $tsigs           = {},
  Array                 $masters         = [],
  Array                 $provide_xfrs    = [],
  Boolean               $xferout_enabled = true,
  Stdlib::Absolutepath  $addns_file      = '/etc/opendnssec/addns.xml',
) {

  include ::opendnssec
  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled
  $remotes            = $::opendnssec::remotes

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
  if $masters {
    concat::fragment{'master_header':
      target  => $addns_file,
      content => "\n    <Inbound>\n      <RequestTransfer>\n",
      order   => '20',
    }
    $masters.each |String $master| {
      if ! has_key($remotes, $master) {
        fail("${master} is not defined in opendnssec::remotes")
      }
      $port = pick($remotes[$master]['port'], 53)
      concat::fragment{ "master_remote_${master}":
        target  => $addns_file,
        content => "<Remote><Address>${remotes[$master]['address4']}</Address><Port>${port}</Port></Remote>\n",
        order   => '23',
      }
    }
    concat::fragment{ 'master_mid':
      target  => $addns_file,
      content => "      </RequestTransfer>\n      <AllowNotify>\n",
      order   => '25',
    }
    $masters.each |String $master| {
      concat::fragment{ "master_peer_${master}":
        target  => $addns_file,
        content => "<Peer><Prefix>${remotes[$master]['address4']}</Prefix></Peer>\n",
        order   => '27',
      }
    }
    concat::fragment{'master_footer':
      target  => $addns_file,
      content => "      </AllowNotify>\n    </Inbound>\n",
      order   => '29',
    }
  }
  if ! empty($provide_xfrs) and $xferout_enabled {
    concat::fragment{'provide_xfr_header':
      target  => $addns_file,
      content => "\n    <Outbound>\n      <ProvideTransfer>\n",
      order   => '30',
    }
    $provide_xfrs.each |String $provide_xfr| {
      if ! has_key($remotes, $provide_xfr) {
        fail("${provide_xfr} is not defined in opendnssec::remotes")
      }
      concat::fragment{ "provide_xfr_transfer_peer_${provide_xfr}":
        target  => $addns_file,
        content => "<Peer><Prefix>${remotes[$provide_xfr]['address4']}</Prefix></Peer>\n",
        order   => '33',
      }
    }
    concat::fragment{'provide_xfr_mid':
      target  => $addns_file,
      content => "\n      </ProvideTransfer>\n      <Notify>\n",
      order   => '35',
    }
    $provide_xfrs.each |String $provide_xfr| {
      concat::fragment{ "provide_xfr_notify_peer_${provide_xfr}":
        target  => $addns_file,
        content => "<Peer><Address>${remotes[$provide_xfr]['address4']}</Address></Peer>\n",
        order   => '37',
      }
    }
    concat::fragment{'provide_xfr_footer':
      target  => $addns_file,
      content => "\n      </Notify>\n    </Outbound>\n",
      order   => '39',
    }
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
