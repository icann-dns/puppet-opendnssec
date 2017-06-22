# == Class: opendnssec
#
define opendnssec::policy (
  String                   $order                    = '10',
  Optional[String]         $description              = undef,

  Opendnssec::Timestring   $resign                   = 'PT2H',
  Opendnssec::Timestring   $refresh                  = 'P6D',
  Opendnssec::Timestring   $validity_default         = 'P21D',
  Opendnssec::Timestring   $validity_denial          = 'P21D',
  Opendnssec::Timestring   $jitter                   = 'PT12H',
  Opendnssec::Timestring   $inception_offset         = 'PT3600S',

  Opendnssec::Denialpolicy $denial_policy            = 'NSEC3',
  Boolean                  $denial_optout            = false,
  Opendnssec::Timestring   $denial_resalt            = 'P100D',
  Opendnssec::Nsec3algo    $denial_algorithm         = 'SHA1',
  Integer                  $denial_iterations        = 5,
  Integer                  $denial_salt_length       = 8,

  Opendnssec::Timestring   $key_ttl                  = 'PT3600S',
  Opendnssec::Timestring   $key_retire_safty         = 'PT3600S',
  Opendnssec::Timestring   $key_publish_safty        = 'PT3600S',
  Boolean                  $key_share_keys           = false,
  Opendnssec::Timestring   $key_purge                = 'P14D',

  Opendnssec::Dnskeyalgo   $ksk_algorithm            = 'RSASHA1-NSEC3-SHA1',
  Integer                  $ksk_algorithm_length     = 2048,
  Opendnssec::Timestring   $ksk_lifetime             = 'P365D',
  Integer                  $ksk_standby              = 0,
  Boolean                  $ksk_manual_rollover      = true,

  Opendnssec::Dnskeyalgo   $zsk_algorithm            = 'RSASHA1-NSEC3-SHA1',
  Integer                  $zsk_algorithm_length     = 1048,
  Opendnssec::Timestring   $zsk_lifetime             = 'P90D',
  Integer                  $zsk_standby              = 0,
  Boolean                  $zsk_manual_rollover      = false,

  Opendnssec::Timestring   $zone_propagation_delay   = 'PT43200S',
  Opendnssec::Timestring   $zone_soa_ttl             = 'PT3600S',
  Opendnssec::Timestring   $zone_soa_minimum         = 'PT3600S',
  Opendnssec::Soaserial    $zone_soa_serial          = 'unixtime',

  Opendnssec::Timestring   $parent_propagation_delay = 'PT9999S',
  Opendnssec::Timestring   $parent_ds_ttl            = 'PT3600S',
  Opendnssec::Timestring   $parent_soa_ttl           = 'PT172800S',
  Opendnssec::Timestring   $parent_soa_minimum       = 'PT10800S',
) {
  include ::opendnssec

  $policy_file     = $::opendnssec::policy_file
  $repository_name = $::opendnssec::repository_name

  if $description {
    $description_text = $description
  } else {
    $description_text = "${name} - Deny:${denial_policy}; KSK:${ksk_algorithm}; ZSK:${zsk_algorithm}"
  }
  concat::fragment{"policy_${name}":
    target  => $policy_file,
    content => template('opendnssec/etc/opendnssec/kasp-fragment.xml.erb'),
    order   => $order,
  }
}
