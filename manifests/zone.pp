# == Define: opendnssec::zone
#
define opendnssec::zone (
  Boolean                        $signed              = true,
  Optional[String]               $signer_policy       = undef,
  Optional[Array[String]]        $masters             = [],
  Optional[Array[String]]        $provide_xfrs        = [],
  String                         $order               = '10',
  Stdlib::Absolutepath           $adapter_base_dir    = '/var/lib/opendnssec',
  Optional[Stdlib::Absolutepath] $adapter_signer_conf = undef,
  Optional[Stdlib::Absolutepath] $adapter_input_file  = undef,
  Optional[Stdlib::Absolutepath] $adapter_output_file = undef,
  Optional[Tea::Puppetsource]    $zone_source         = undef,
  Optional[String]               $zone_content        = undef,
  Opendnssec::Adapter            $adapter_input_type  = 'DNS',
  Opendnssec::Adapter            $adapter_output_type = 'DNS',
) {

  if $signed {
    include ::opendnssec
    $remotes   = $::opendnssec::remotes
    $zone_file = $::opendnssec::zone_file

    $adapter_signer_conf_file = $adapter_signer_conf ? {
      undef   => "${adapter_base_dir}/signconf/${name}.xml",
      default => $adapter_signer_conf,
    }
    $adapter_input_f = $adapter_input_file ? {
      undef   => "${adapter_base_dir}/unsigned/${name}",
      default => $adapter_input_file,
    }
    $adapter_output_f = $adapter_output_file ? {
      undef   =>  "${adapter_base_dir}/signed/${name}",
      default =>  $adapter_output_file,
    }
    $_signer_policy = $signer_policy ? {
      undef   => $::opendnssec::default_signer_policy_name,
      default => $signer_policy,
    }
    if $adapter_input_type == 'File' {
      if $zone_source and $zone_content {
        fail('you can only specify one either \$zone_source or \$zone_content')
      }
      if !$zone_source and !$zone_content {
        fail('you must specify either \$zone_source or \$zone_content when adapter_input_type=="File"')
      }
      file{$adapter_input_f:
        ensure  => file,
        source  => $zone_source,
        content => $zone_content,
      }
    }
    $masters.each |String $master| {
      if ! has_key($remotes, $master) {
        fail("\$::opendnssec::remotes[${master}] does not exist but defined in Opendnssec::Zone['${name}'")
      }
    }
    $provide_xfrs.each |String $provide_xfr| {
      if ! has_key($remotes, $provide_xfr) {
        fail("\$::opendnssec::remotes[${provide_xfr}] does not exist but defined in Opendnssec::Zone['${name}'")
      }
    }

    if ! defined(Opendnssec::Policy[$_signer_policy]) {
      fail("${name} defines signer_policy ${_signer_policy} however Opendnssec::Policy[${_signer_policy}] is not defined")
    }
    if $adapter_input_type == 'DNS' {
      if empty($masters) {
        $adapter_masters_conf = 'default'
      } else {
        $adapter_masters_conf = "${name}-masters"
        opendnssec::addns{ $adapter_masters_conf:
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
        opendnssec::addns{ $adapter_provide_xfrs_conf:
          masters      => $masters,
          provide_xfrs => $provide_xfrs,
        }
      }
    }
    concat::fragment{"zone_${name}":
      target  => $zone_file,
      content => template('opendnssec/etc/opendnssec/zonelist-fragment.xml.erb'),
      order   => $order,
    }
  }
}
