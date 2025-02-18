# @summary Add a new policy configuration
# @param policies Hash of policies to add
#
class opendnssec::policies (
  Hash $policies = {},
) {
  include opendnssec

  $user               = $opendnssec::user
  $group              = $opendnssec::group
  $policy_file        = $opendnssec::policy_file
  $manage_ods_ksmutil = $opendnssec::manage_ods_ksmutil
  $ksmutil_path       = $opendnssec::ksmutil_path
  $enabled            = $opendnssec::enabled
  $opendnssec_version = $opendnssec::opendnssec_version
  $enforcer_path      = $opendnssec::enforcer_path
  $update_command = $opendnssec_version ? {
    /^1/    => "/usr/bin/yes | ${ksmutil_path} update all",
    /^2/    => "/usr/bin/yes | ${enforcer_path} update all",
    default => fail("Unsupported OpenDNSSEC version: ${opendnssec_version}"),
  }

  concat { $policy_file:
    owner => $user,
    group => $group,
  }
  concat::fragment { 'policy_header':
    target  => $policy_file,
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<!-- File managed by puppet DO NOT EDIT -->\n\n<KASP>\n",
    order   => '01',
  }
  concat::fragment { 'policy_footer':
    target  => $policy_file,
    content => "</KASP>\n",
    order   => '99',
  }
  create_resources(opendnssec::policy, $policies)
  if $enabled and $manage_ods_ksmutil {
    exec { 'ods-ksmutil updated kasp.xml':
      command     => $update_command,
      user        => $user,
      refreshonly => true,
      subscribe   => Concat[$policy_file];
    }
  }
}
