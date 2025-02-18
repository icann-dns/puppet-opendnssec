# @summary Add a new zone configuration
# @param signed Whether the zone is signed
# @param signer_policy Signer policy
# @param masters Array of masters to add
# @param provide_xfrs Array of masters to provide xfrs to
# @param order Order of the zone
# @param adapter_base_dir Base directory for the adapter
# @param adapter_signer_conf_file Signer configuration file
# @param adapter_input_file Input file for the adapter
# @param adapter_output_file Output file for the adapter
# @param zone_source Source of the zone file
# @param zone_content Content of the zone file
# @param adapter_input_type Input type for the adapter
# @param adapter_output_type Output type for the adapter
#
define opendnssec::zone (
  Boolean                      $signed                   = true,
  Optional[String]             $signer_policy            = $opendnssec::default_policy_name,
  Array[String]                $masters                  = [],
  Array[String]                $provide_xfrs             = [],
  String                       $order                    = '10',
  Stdlib::Unixpath             $adapter_base_dir         = $opendnssec::base_dir,
  Stdlib::Unixpath             $adapter_signer_conf_file = "${adapter_base_dir}/signconf/${name}.xml",
  Stdlib::Unixpath             $adapter_input_file       = "${adapter_base_dir}/unsigned/${name}",
  Stdlib::Unixpath             $adapter_output_file      = "${adapter_base_dir}/signed/${name}",
  Optional[Stdlib::Filesource] $zone_source              = undef,
  Optional[String]             $zone_content             = undef,
  Opendnssec::Adapter          $adapter_input_type       = 'DNS',
  Opendnssec::Adapter          $adapter_output_type      = 'DNS',
) {
  if $signed {
    include opendnssec
    $enabled   = $opendnssec::enabled
    $remotes   = $opendnssec::remotes
    $zone_file = $opendnssec::zone_file

    if $adapter_input_type == 'File' {
      if $zone_source and $zone_content {
        fail('you can only specify one either \$zone_source or \$zone_content')
      }
      if !$zone_source and !$zone_content {
        fail('you must specify either \$zone_source or \$zone_content when adapter_input_type=="File"')
      }
      file { $adapter_input_file:
        ensure  => file,
        source  => $zone_source,
        content => $zone_content,
      }
    }
    $masters.each |String $master| {
      unless $master in $remotes {
        fail("\$::opendnssec::remotes[${master}] does not exist but defined in Opendnssec::Zone['${name}'")
      }
    }
    $provide_xfrs.each |String $provide_xfr| {
      unless $provide_xfr in $remotes {
        fail("\$::opendnssec::remotes[${provide_xfr}] does not exist but defined in Opendnssec::Zone['${name}'")
      }
    }
    if ! defined(Opendnssec::Policy[$signer_policy]) {
      fail("${name} defines signer_policy ${signer_policy} however Opendnssec::Policy[${signer_policy}] is not defined")
    }
    if $adapter_input_type == 'DNS' {
      if empty($masters) {
        $adapter_masters_conf = 'default'
      } else {
        $adapter_masters_conf = "${name}-masters"
        opendnssec::addns { $adapter_masters_conf:
          masters      => $masters,
          provide_xfrs => $provide_xfrs,
        }
      }
    }
    if $adapter_output_type == 'DNS' {
      if empty($provide_xfrs) {
        $adapter_provide_xfrs_conf = 'default'
      } else {
        $adapter_provide_xfrs_conf = "${name}-provide_xfrs"
        opendnssec::addns { $adapter_provide_xfrs_conf:
          masters      => $masters,
          provide_xfrs => $provide_xfrs,
        }
      }
    }
    concat::fragment { "zone_${name}":
      target  => $zone_file,
      content => template('opendnssec/etc/opendnssec/zonelist-fragment.xml.erb'),
      order   => $order,
    }
  }
}
