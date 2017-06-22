[![Build Status](https://travis-ci.org/icann-dns/puppet-opendnssec.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-opendnssec)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/opendnssec.svg?maxAge=2592000)](https://forge.puppet.com/icann/opendnssec)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/opendnssec.svg?maxAge=2592000)](https://forge.puppet.com/icann/opendnssec)
# opendnssec

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with opendnssec](#setup)
    * [What opendnssec affects](#what-opendnssec-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with opendnssec](#beginning-with-opendnssec)
4. [Usage - Configuration options and additional functionality](#usage)
    * [SoftHSM](#softhsm)
    * [Add a zone with masters]( #add-a-zone-with-masters)
    * [Add a zone with masters and slave]( #add-a-zone-with-masters-and-slave)
    * [Add a zone with masters and slave with default tsig](#add-a-zone-with-masters-and-slave-with-default-tsig)
    * [Add a zone with masters and slave with remote based tsig](#add-a-zone-with-masters-and-slave-with-remote-based-tsig)
    * [Classes](#classes)
    * [Defines](#defines)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs and manages opendnssec

## Setup

### What opendnssec affects

* Manages the opendnssec policies, zones and configueration

### Setup Requirements

* puppetlabs-stdlib 4.17.0
* puppetlabs-concat 1.2.0
* puppetlabs-mysql 3.11.0
* icann-tea 2.11.0
* icann-softhsm 0.2.0 (required for spec tests)

### Beginning with opendnssec

just add the opendnssec class. This will configure opendnssec with a default signing policy and configuered to use SoftHSM with a token id of OpenDNSSEC

```puppet
class {'::opendnssec' }
```

## Usage

### SoftHSM

To work with opendnssec you will need a HSM.  the openndsec project have created SoftHSM a software based HSM.  in order to make the below examples work out of the box you can configure and install SoftHSM using the `icann-softhsm` puppet module.  The following configueration will get things up and running but you may want to change pins

```puppet
class {'::softhsm':
  tokens => {
	'OpenDNSSEC' => {
	  'pin'    => '1234',
	  'so_pin' => '1234',
	},
  },
}
```

hiera
```yaml
softhsm::tokens:
  OpenDNSSEC:
    pin: 1234
    so_pin: 1234
```

### Add a zone with masters

```puppet
class {'::opendnssec':
  remotes  => {
	'lax.xfr.dns.icann.org' => {
	  'address4' => '192.0.32.132',
	  'address6' => '2620:0:2d0:202::132',
	},
	'iad.xfr.dns.icann.org' => {
	  'address4' => '192.0.47.132',
	  'address6' => '2620:0:2830:202::132',
	},
  },
  zones => {
	'root-servers.net' => {
	  'masters' => [
		'lax.xfr.dns.icann.org',
		'iad.xfr.dns.icann.org',
	  ],
	},
  },
}
```

of with hiera

```yaml
opendnssec::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
opendnssec::zones:
  root-servers.net:
    masters:
    - lax.xfr.dns.icann.org
    - lax.xfr.dns.icann.org
```


### Add a zone with masters and slave

```puppet
class {'::opendnssec':
  remotes  => {
	'lax.xfr.dns.icann.org' => {
	  'address4' => '192.0.32.132',
	  'address6' => '2620:0:2d0:202::132',
	},
	'iad.xfr.dns.icann.org' => {
	  'address4' => '192.0.47.132',
	  'address6' => '2620:0:2830:202::132',
	},
	'ns.example.com' => {
	  'address4' => '192.0.2.1',
	  'address6' => '2001:db8::1',
	},
  },
  zones => {
	'root-servers.net' => {
	  'masters' => [
		'lax.xfr.dns.icann.org',
		'iad.xfr.dns.icann.org',
	  ],
      'provide_xfrs' => [ 'ns.example.com' ]
	},
  },
}
```

of with hiera

```yaml
opendnssec::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
  ns.example.com:
    address4: 192.0.2.1
    address6: 2001::db8::1
opendnssec::zones:
  root-servers.net:
    masters:
    - lax.xfr.dns.icann.org
    - lax.xfr.dns.icann.org
    provide_xfrs:
    - ns.example.com
```

### Add a zone with masters and slave with default tsig

```puppet
class {'::opendnssec':
  tsigs => {
    'default_tsig_key' => {
      algo => 'hmac-sha1',
      data => 'AAAA',
    },
  },
  default_tsig_name => 'default_tsig_key'
  remotes  => {
	'lax.xfr.dns.icann.org' => {
	  'address4' => '192.0.32.132',
	  'address6' => '2620:0:2d0:202::132',
	},
	'iad.xfr.dns.icann.org' => {
	  'address4' => '192.0.47.132',
	  'address6' => '2620:0:2830:202::132',
	},
	'ns.example.com' => {
	  'address4' => '192.0.2.1',
	  'address6' => '2001:db8::1',
	},
  },
  zones => {
	'root-servers.net' => {
	  'masters' => [
		'lax.xfr.dns.icann.org',
		'iad.xfr.dns.icann.org',
	  ],
      'provide_xfrs' => [ 'ns.example.com' ]
	},
  },
}
```

of with hiera

```yaml
opendnssec::tsigs:
  default_tsig_key:
    algo:'hmac-sha1',
    data:'AAAA',
opendnssec::default_tsig_name: default_tsig_key
opendnssec::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
  ns.example.com:
    address4: 192.0.2.1
    address6: 2001::db8::1
opendnssec::zones:
  root-servers.net:
    masters:
    - lax.xfr.dns.icann.org
    - lax.xfr.dns.icann.org
    provide_xfrs:
    - ns.example.com
```


### Add a zone with masters and slave with remote based tsig

```puppet
class {'::opendnssec':
  tsigs => {
    'master_tsig_key' => {
      algo => 'hmac-sha1',
      data => 'AAAA',
    },
  },
  remotes  => {
	'lax.xfr.dns.icann.org' => {
	  'address4' => '192.0.32.132',
	  'address6' => '2620:0:2d0:202::132',
      'tsig_name' => 'master_tsig_key',
	},
	'iad.xfr.dns.icann.org' => {
	  'address4' => '192.0.47.132',
	  'address6' => '2620:0:2830:202::132',
	},
	'ns.example.com' => {
	  'address4' => '192.0.2.1',
	  'address6' => '2001:db8::1',
	},
  },
  zones => {
	'root-servers.net' => {
	  'masters' => [
		'lax.xfr.dns.icann.org',
		'iad.xfr.dns.icann.org',
	  ],
      'provide_xfrs' => [ 'ns.example.com' ]
	},
  },
}
```

of with hiera

```yaml
opendnssec::tsigs:
  master_tsig_key:
    algo:'hmac-sha1',
    data:'AAAA',
opendnssec::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
    tsig_name: master_tsig_key
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
  ns.example.com:
    address4: 192.0.2.1
    address6: 2001::db8::1
opendnssec::zones:
  root-servers.net:
    masters:
    - lax.xfr.dns.icann.org
    - lax.xfr.dns.icann.org
    provide_xfrs:
    - ns.example.com
```

## Reference

### Classes

#### Public Classes

* [`opendnssec`](#class-opendnssec)

#### Class: `opendnssec`

Main class, includes all other classes

##### Parameters 

* `$enabled` (Boolean, Default: true): Whether to enable opendnssec
* `$user` (String[1,32], Default: 'root'): owner of config files
* `$group` (String[1,32], Default: 'root'): group owner of config files
* `$manage_packages` (Boolean, Default: true): weather to manage the installation of packages
* `$manage_datastore` (Boolean, Default: true): Weather to manage the datastore
* `$manage_service` (Boolean, Default: true): whether to manage services  
* `$manage_ods_ksmutil` (Boolean, Default: true): whether to manage ods-ksmutils updates
* `$manage_conf` (Boolean, Default: true): whether to manage config files
* `$logging_level` (Integer[1,7], Default: 3): syslog level to use
* `$logging_facility` (Tea::Syslogfacility, Default: 'local0'): sysloc facilty tp use
* `$repository_name` (String[1,100], Default: 'SoftHSM'): name of the hsm repository
* `$repository_module` (Stdlib::Absolutepath, Default: $::opendnssec::params::repository_module): dentifies the dynamic-link library that controls the repository
* `$repository_pin` (String[1,100], Default: '1234'): an optional element containing the password to the HSM
* `$repository_capacity` (Optional[Integer], Default: undef): indicates the maximum number of keys the HSM can store. It is an optional element - if there is no (realistic) limit to the number of keys, remove it.
* `$repository_token_label` (String[1,32], Default: 'OpenDNSSEC'): the "token" within the HSM that is being used - essentially a form of sub-repository. The token label is also used where there are two repositories of the same type, in that each repository should contain a different token label sub-repository. OpenDNSSEC will automatically go to the right HSM based on this. This field is limited to 32 characters.
* `$skip_publickey` (Boolean, Default: true):  specifies that the public key objects should not be stored or handled in the HSM. The public key is needed in order to create the DNSKEY RR. In theory, the public part of the key is also available in the private key object. However, the PKCS#11 API does not require the HSM to behave in this way. We have not seen a HSM where we cannot do this, but you should remove this flag if you are having any problem with it. The benefit of adding this flag is that you save space in your HSM, because you are only storing the private key object.
* `$require_backup` (Boolean, Default: false): specifies that keys from this repository may not be used until they are backed up. If backup has been done, then use ods-ksmutil to notify OpenDNSSEC about this. The backup notification is needed for OpenDNSSEC to be able to complete a key rollover.
* `$datastore_engine` (Opendnssec::Datastore, Default: 'mysql'): the backenbd datastor to use.  only mysql is supported
* `$datastore_host` (Tea::Host, Default: 'localhost'): location of mysql server
* `$datastore_port` (Tea::Port, Default: 3306): port of mysql server
* `$datastore_name` (String[1,100], Default: 'kasp'): user on mysql server
* `$datastore_user` (String[1,100], Default: 'opendnssec'): database name on mysql server
* `$datastore_password` (String[1,100], Default: 'change\_me') password on mysql server:
* `$mysql_sql_file` (Stdlib::Absolutepath, Default: '/usr/share/opendnssec/database_create.mysql'): sql file to use to initiate database
* `$policy_file` (Stdlib::Absolutepath, Default: '/etc/opendnssec/kasp.xml'): location of policy file
* `$zone_file` (Stdlib::Absolutepath, Default: '/etc/opendnssec/zonelist.xml'): location of zonelist file
* `$xferout_enabled` (Boolean, Default: true): enable this to disable zone transfers and notifies.  usefull for standby signers
* `$zones` (Hash, Default: {}): hash of `opendnssec::zone` defines to configure
* `$policies` (Hash, Default: {}) hash of `opendnssec::policy` defines to configure:
* `$remotes` (Hash, Default: {}): Hash of remote servers used by `opendnsec::zone` objects
* `$default_tsig_name` (String, Default: 'NOKEY'): default tsig key to use if no present in zone object
* `$default_policy_name` (String, Default: 'default'): default policy name if no present in zone objectif no present in zone object
* `$default_masters` (Array[String], Default: []): list of default masters if no present in zone object
* `$default_provide_xfrs` (Array[String], Default: []): list of default provide\_xfrs to use if none present on zone object

#### Class: `opendnssec::backup_cron`

Add a cron job to backup the keystore and copy it to a standby server

##### Parameters 

* `$backup_user` (String[1,32], Default: 'backup'): User used to sen backup to remote server
* `$backup_glob` (String, Default: '\*.tar.bz2'): used for cleaning up old backups in the `backup_dir`
* `$date_format` (String, Default: '%Y%m%d-%H%M'): date formate to use for backup files
* `$retention` (Integer, Default: 500): how many backup files to keep
* `$backup_dir` (Stdlib::Absolutepath, Default: '/opt/backup'): location of bacup directory
* `$tmp_dirbase` (Stdlib::Absolutepath, Default: '/opt/tmp'): tmp directoy to use for staging backup files
* `$script_path` (Stdlib::Absolutepath, Default: '/usr/local/bin/backup-hsm-mysql.sh'): location to stor backup script

### Private Classes

#### Class: `opendnssec::policies`

Wrapper class to initiate kasp.xml

##### Parameters 

* `$policies` (Hash, Default: {}): Hash of polices to pass to create\_resource(`opendnssec::policy, $policies)`

#### Class: `opendnssec::zones`

Wrapper class to initiate zonelist.xml

##### Parameters 

* `$zones` (Hash, Default: {}): Hash of zones to pass to create\_resource(`opendnssec::zone, $zones)`

### Defines

#### Public defines

#### Define: `opendnssec::policies`

Create OpenDNSSEC signing policy

##### Parameters 

* `$order` (String, Default: '10'): concat order, you probably dont need t override this
* `$description` (Optional[String], Default: [based on config]): the description of the signing policy
* `$resign` (Opendnssec::Timestring, Default: 'PT2H'): the re-sign interval, which is the interval between runs of the Signer Engine.
* `$refresh` (Opendnssec::Timestring, Default: 'P6D'): the refresh interval, detailing when a signature should be refreshed. As signatures are typically valid for much longer than the interval between runs of the signer, there is no need to re-generate the signatures each time the signer is run if there is no change to the data being signed. The signature will be refreshed when the time until the signature expiration is closer than the refresh interval. Set it to zero if you want to refresh the signatures each re-sign interval.
* `$validity_default` (Opendnssec::Timestring, Default: 'P21D'): the validity interval for all RRSIG records except those related to NSEC or NSEC3 records
* `$validity_denial` (Opendnssec::Timestring, Default: 'P21D'): validity period of  NSEC or NSEC3 record
* `$jitter` (Opendnssec::Timestring, Default: 'PT12H'):he value added to or extracted from the expiration time of signatures to ensure that not all signatures expire at the same time. The actual value of the <Jitter> element is the -j + r %2j, where j is the jitter value and r a random duration, uniformly ranging between -j and j, is added to signature validity period to get the signature expiration time.
* `$inception_offset` (Opendnssec::Timestring, Default: 'PT3600S'): a duration subtracted from the time at which a record is signed to give the start time of the record. This is required to allow for clock skew between the signing system and the system on which the signature is checked. Without it, the possibility exists that the checking system could retrieve a signature whose start time is later than the current time.
* `$denial_policy` (Opendnssec::Denialpolicy, Default: 'NSEC3'): denial policy either NSEc or NSEC3
* `$denial_optout` (Boolean, Default: false): if true, enable "opt out". This is an optimisation that means that NSEC3 records are only created for authoritative data or for secure delegations; insecure delegations have no NSEC3 records. For zones where a majority of the entries are delegations that are not signed - typically TLDs during the take-up phase of DNSSEC - this reduces the number of DNSSEC records in the zone.
* `$denial_resalt` (Opendnssec::Timestring, Default: 'P100D'): the interval between generating new salt values for the hashing algorithm.
* `$denial_algorithm` (Opendnssec::Nsec3algo, Default: 'SHA1'): parameters to the hash algorithm, described in RFC 5155.
* `$denial_iterations` (Integer, Default: 5): parameters to the hash algorithm, described in RFC 5155.
* `$denial_salt_length` (Integer, Default: 8): parameters to the hash algorithm, described in RFC 5155.
* `$key_ttl` (Opendnssec::Timestring, Default: 'PT3600S'): the time-to-live value for the DNSKEY resource records.
* `$key_retire_safty` (Opendnssec::Timestring, Default: 'PT3600S'): `key_retire_safty` and `key_publish_safty` are the publish and retire safety margins for the keys. These intervals are safety margins added to calculated timing values to give some extra time to cover unforeseen events, e.g. in case external events prevent zone publication.
* `$key_publish_safty` (Opendnssec::Timestring, Default: 'PT3600S'): `key_retire_safty` and `key_publish_safty` are the publish and retire safety margins for the keys. These intervals are safety margins added to calculated timing values to give some extra time to cover unforeseen events, e.g. in case external events prevent zone publication.
* `$key_share_keys` (Boolean, Default: false): If multiple zones are associated with a policy, this indicates if a key can be shared between zones
* `$key_purge` (Opendnssec::Timestring, Default: 'P14D'): keys marked as dead will be automatically purged from the database after this interval.
* `$ksk_algorithm` (Opendnssec::Dnskeyalgo, Default: 'RSASHA1-NSEC3-SHA1'): the algorithm used for the key (the numbers reserved for each algorithm can be found in the appropriate IANA registry
* `$ksk_algorithm_length` (Integer, Default: 2048): The size of the KSK key
* `$ksk_lifetime` (Opendnssec::Timestring, Default: 'P365D'): how long the key is used for before it is rolled.
* `$ksk_standby` (Integer, Default: 0): Determines the number of standby keys held in the zone. These keys allow the currently active key to be immediately retired should it be compromised, so enhancing the security of the system. 
* `$ksk_manual_rollover` (Boolean, Default: true): ndicate that the key rollover will only be initiated on the command by the operator.
* `$zsk_algorithm` (Opendnssec::Dnskeyalgo, Default: 'RSASHA1-NSEC3-SHA1'): the algorithm used for the key (the numbers reserved for each algorithm can be found in the appropriate IANA registry).
* `$zsk_algorithm_length` (Integer, Default: 1024): The size of the ZSK key
* `$zsk_lifetime` (Opendnssec::Timestring, Default: 'P90D'): how long the key is used for before it is rolled.
* `$zsk_standby` (Integer, Default: 0): Determines the number of standby keys held in the zone. These keys allow the currently active key to be immediately retired should it be compromised, so enhancing the security of the system. 
* `$zsk_manual_rollover` (Boolean, Default: false): ndicate that the key rollover will only be initiated on the command by the operator.
* `$zone_propagation_delay` (Opendnssec::Timestring, Default: 'PT43200S'): the amount of time needed for information changes at the master server for the zone to work its way through to all the secondary nameservers.
* `$zone_soa_ttl` (Opendnssec::Timestring, Default: 'PT3600S'): TTL of the SOA record.
* `$zone_soa_minimum` (Opendnssec::Timestring, Default: 'PT3600S'): value for the SOA's "minimum" parameter.
* `$zone_soa_serial` (Opendnssec::Soaserial, Default: 'unixtime'): the format of the serial number in the signed zone.
* `$parent_propagation_delay` (Opendnssec::Timestring, Default: 'PT9999S'): the interval between the time a new KSK is published in the zone and the time that the DS record appears in the parent zone.
* `$parent_ds_ttl` (Opendnssec::Timestring, Default: 'PT3600S'): he TTL of the DS record in the parent zone.
* `$parent_soa_ttl` (Opendnssec::Timestring, Default: 'PT172800S'): TTL of the parent SOA record
* `$parent_soa_minimum` (Opendnssec::Timestring, Default: 'PT10800S'): the value of the parent "minimum" SOA record.

#### Define: `opendnssec::zone`

Create OpenDNSSEC zone

##### Parameters 

* `$policy` (Optional[String], Default: `opendnssec::default_policy_name`): DNSSEC sigining policy to use
* `$masters` (Optional[Array[String]], Default: []): list of `opendnssec::remotes` keys configured to pull unsigned zones from
* `$provide_xfrs` (Optional[Array[String]], Default: []): list of `opendnssec::remotes` keys configured to recive signed zones
* `$order` (String, Default: '10'):concat order, you probably dont need to override this
* `$adapter_base_dir` (Stdlib::Absolutepath, Default: '/var/lib/opendnssec'): base directoy used for fconf file locations
* `$adapter_signer_conf` (Optional[Stdlib::Absolutepath], Default: [based on zone name]): singner congi file location
* `$adapter_input_file` (Optional[Stdlib::Absolutepath], Default: [based on zone name]): if using file adapter to location on the opendnssec server of the config file
* `$adapter_output_file` (Optional[Stdlib::Absolutepath], Default: [based on zone name]): if using file adapter to location on the opendnssec server of the config file
* `$adapter_input_type` (Opendnssec::Adapter, Default: 'DNS'):  The adapter to use either DNS or File, note oly DNS is well tested
* `$adapter_output_type` (Opendnssec::Adapter, Default: 'DNS'): The adapter to use either DNS or File, note oly DNS is well tested


#### Private defines

#### Define: `opendnssec::addns`

Create addns files based on masters and provide\_xfrs configuered on zones

##### Parameters 

* `$masters` (Array[String], Default: []):Array of `opendnssec::remotes` keys to configure as master servers
* `$provide_xfrs` (Array[String], Default: []): Array of `opendnssec::remotes` keys to use as configure as slave servers

## Limitations

This module is tested on Ubuntu 14.04, and 16.04
