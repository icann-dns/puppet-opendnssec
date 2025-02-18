# @summary Manage OpenDNSSEC zones
# @param zones Hash of zones to add
#
class opendnssec::zones (
  Hash $zones = {},
) {

  include ::opendnssec

  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $zone_file          = $::opendnssec::zone_file
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $ksmutil_path       = $::opendnssec::ksmutil_path
  $enabled            = $::opendnssec::enabled
  $opendnssec_version = $::opendnssec::opendnssec_version
  $enforcer_path      = $::opendnssec::enforcer_path

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
  if $enabled {
    if ( $manage_ods_ksmutil and ( versioncmp($opendnssec_version, '1') >= 0 ) ) {
      exec {'ods-ksmutil updated zonelist.xml':
        command     => "/usr/bin/yes | ${ksmutil_path} update zonelist",
        user        => $user,
        refreshonly => true,
        subscribe   => Concat[$zone_file];
      }
    } elsif ( versioncmp($opendnssec_version, '2') >= 0) {
      exec {'ods-enforcer updated zonelist.xml':
        command     => "/usr/bin/yes | ${enforcer_path} update zonelist",
        user        => $user,
        refreshonly => true,
        subscribe   => Concat[$zone_file];
      }
    }
  }
}
