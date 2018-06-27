# == Class: opendnssec
#
class opendnssec::zones (
  Hash $zones = {},

) {

  include ::opendnssec

  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $zone_file          = $::opendnssec::zone_file
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled

  concat {$zone_file:
    owner => $user,
    group => $group,
  }
  concat::fragment{'zone_header':
    target  => $zone_file,
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<!-- File managed by Puppet DO NOT EDIT -->\n\n<ZoneList>\n",
    order   => '01',
  }
  concat::fragment{'zone_footer':
    target  => $zone_file,
    content => "</ZoneList>\n",
    order   => '99',
  }
  create_resources(opendnssec::zone, $zones)
  if $manage_ods_ksmutil and $enabled {
    exec {'ods-ksmutil updated zonelist.xml':
      command     => '/usr/bin/yes | /usr/bin/ods-ksmutil update zonelist',
      user        => $user,
      refreshonly => true,
      subscribe   => Concat[$zone_file];
    }
  }
}
