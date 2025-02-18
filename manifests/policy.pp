# @summary Add a new policy configuration
# @param order Order of the policy
# @param description Description of the policy
# @param resign Resign interval
# @param refresh Refresh interval
# @param validity_default Default validity
# @param validity_denial Denial validity
# @param jitter Jitter
# @param inception_offset Inception offset
# @param denial_policy Denial policy
# @param denial_optout Denial optout
# @param denial_resalt Denial resalt
# @param denial_algorithm Denial algorithm
# @param denial_iterations Denial iterations
# @param denial_salt_length Denial salt length
# @param key_ttl Key TTL
# @param key_retire_safty Key retire safty
# @param key_publish_safty Key publish safty
# @param key_share_keys Key share keys
# @param key_purge Key purge
# @param ksk_algorithm KSK algorithm
# @param ksk_algorithm_length KSK algorithm length
# @param ksk_lifetime KSK lifetime
# @param ksk_standby KSK standby
# @param ksk_manual_rollover KSK manual rollover
# @param zsk_algorithm ZSK algorithm
# @param zsk_algorithm_length ZSK algorithm length
# @param zsk_lifetime ZSK lifetime
# @param zsk_standby ZSK standby
# @param zsk_manual_rollover ZSK manual rollover
# @param zone_propagation_delay Zone propagation delay
# @param zone_soa_ttl Zone SOA TTL
# @param zone_soa_minimum Zone SOA minimum
# @param zone_soa_serial Zone SOA serial
# @param parent_propagation_delay Parent propagation delay
# @param parent_ds_ttl Parent DS TTL
# @param parent_soa_ttl Parent SOA TTL
# @param parent_soa_minimum Parent SOA minimum

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
  Integer                  $denial_iterations        = 0,
  Integer                  $denial_salt_length       = 0,

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
  Integer                  $zsk_algorithm_length     = 1024,
  Opendnssec::Timestring   $zsk_lifetime             = 'P90D',
  Integer                  $zsk_standby              = 0,
  Boolean                  $zsk_manual_rollover      = false,

  Opendnssec::Timestring   $zone_propagation_delay   = 'PT43200S',
  Opendnssec::Timestring   $zone_soa_ttl             = 'PT3600S',
  Opendnssec::Timestring   $zone_soa_minimum         = 'PT3600S',
  Opendnssec::Soaserial    $zone_soa_serial          = 'keep',

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
