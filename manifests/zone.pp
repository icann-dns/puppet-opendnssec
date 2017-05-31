# == Define: opendnssec::zone
#
define opendnssec::zone (
  String                         $policy,
  String                         $order               = '10',
  Stdlib::Absolutepath           $adapter_base_dir    = '/var/lib/opendnssec',
  Optional[Stdlib::Absolutepath] $adapter_signer_conf = undef,
  Optional[Stdlib::Absolutepath] $adapter_input_file  = undef,
  Optional[Stdlib::Absolutepath] $adapter_output_file = undef,
  Opendnssec::Adapter            $adapter_input_type  = 'DNS',
  Opendnssec::Adapter            $adapter_output_type = 'DNS',
) {

  include ::opendnssec
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
