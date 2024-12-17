# == Class: opendnssec::policies
#
class opendnssec::policies (
  Hash $policies = {},
) {

  include ::opendnssec

  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $policy_file        = $::opendnssec::policy_file
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $ksmutil_path       = $::opendnssec::ksmutil_path
  $enabled            = $::opendnssec::enabled
  $opendnssec_version = $::opendnssec::opendnssec_version
  $enforcer_path      = $::opendnssec::enforcer_path

  concat {$policy_file:
    owner => $user,
    group => $group,
  }
  concat::fragment{'policy_header':
    target  => $policy_file,
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<!-- File managed by puppet DO NOT EDIT -->\n\n<KASP>\n",
    order   => '01',
  }
  concat::fragment{'policy_footer':
    target  => $policy_file,
    content => "</KASP>\n",
    order   => '99',
  }
  create_resources(opendnssec::policy, $policies)
  if $enabled {
    if ( $manage_ods_ksmutil and ( versioncmp($opendnssec_version, '1') >= 0 ) ) {
      exec {'ods-ksmutil updated kasp.xml':
        command     => "${ksmutil_path} update all",
        user        => $user,
        refreshonly => true,
        subscribe   => Concat[$policy_file];
      }
    } elsif ( versioncmp($opendnssec_version, '2') >= 0) {
      exec {'ods-enforcer updated kasp.xml':
        command     => "${enforcer_path} update all",
        user        => $user,
        refreshonly => true,
        subscribe   => Concat[$policy_file];
      }
    }
  }
}
