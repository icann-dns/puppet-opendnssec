# == Define: opendnssec::zone
#
define opendnssec::zone (
  String                         $policy,
  Optional[Array[String]]        $masters             = [],
  Optional[Array[String]]        $provide_xfrs        = [],
  String                         $order               = '10',
  Stdlib::Absolutepath           $adapter_base_dir    = '/var/lib/opendnssec',
  Optional[Stdlib::Absolutepath] $adapter_signer_conf = undef,
  Optional[Stdlib::Absolutepath] $adapter_input_file  = undef,
  Optional[Stdlib::Absolutepath] $adapter_output_file = undef,
  Opendnssec::Adapter            $adapter_input_type  = 'DNS',
  Opendnssec::Adapter            $adapter_output_type = 'DNS',
) {

  include ::opendnssec
  $remotes = $::opendnssec::remotes
  $masters.each |String $master| {
    if ! has_key($remotes, $master) {
      fail("\$::opendnssec::remotes[$master] does not exist but defined in Opendnssec::Zone['${name}'")
    }
  }
  $provide_xfrs.each |String $provide_xfr| {
    if ! has_key($remotes, $provide_xfr) {
      fail("\$::opendnssec::remotes[$provide_xfr] does not exist but defined in Opendnssec::Zone['${name}'")
    }
  }

  if ! defined(Opendnssec::Policy[$policy]) {
    fail("${name} defines policy ${policy} however Opendnssec::Policy[${policy}] is not defined")
  }
  if empty($masters) {
    $adapter_masters_conf = 'default'
  } else {
    $adapter_masters_conf = "${name}-masters"
    opendnssec::addns{ $adapter_masters_conf:
      masters      => $masters,
      provide_xfrs => $provide_xfrs,
    }
  }
  if empty($provide_xfrs) {
    $adapter_provide_xfrs_conf = 'default'
  } else {
    $adapter_provide_xfrs_conf = "${name}-provide_xfrs"
    opendnssec::addns{ $adapter_provide_xfrs_conf:
      masters      => $masters,
      provide_xfrs => $provide_xfrs,
    }
  }
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
  concat::fragment{"zone_${name}":
    target  => $zone_file,
    content => template('opendnssec/etc/opendnssec/zonelist-fragment.xml.erb'),
    order   => $order,
  }
}
