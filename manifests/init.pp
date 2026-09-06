# @summary class to manage opendnssec
# @param enabled enable this module
# @param user user to run opendnssec
# @param group group to run opendnssec
# @param logging_level logging level
# @param logging_facility logging facility
# @param packages packages to install
# @param service_enforcer service enforcer
# @param service_signer service signer
# @param sqlite_packages sqlite packages
# @param mysql_packages mysql packages
# @param repository_name repository name
# @param repository_module repository module
# @param repository_pin repository pin
# @param repository_capacity repository capacity
# @param repository_token_label repository token label
# @param skip_publickey skip publickey
# @param datastore_engine datastore engine
# @param datastore_host datastore host
# @param datastore_port datastore port
# @param datastore_name datastore name
# @param datastore_user datastore user
# @param datastore_password datastore password
# @param mysql_sql_file mysql sql file
# @param base_dir base dir
# @param policy_file policy file
# @param zone_file zone file
# @param tsigs_dir tsigs dir
# @param remotes_dir remotes dir
# @param xsl_file xsl file
# @param sqlite_file sqlite file
# @param working_dir working dir
# @param signconf_dir signconf dir
# @param signed_dir signed dir
# @param unsigned_dir unsigned dir
# @param ksmutil_path ksmutil path
# @param enforcer_path enforcer path
# @param listener_address listener address
# @param listener_port listener port
# @param xferout_enabled xferout enabled
# @param zones zones
# @param policies policies
# @param remotes remotes
# @param tsigs tsigs
# @param default_tsig_name default tsig name
# @param default_policy_name default policy name
# @param default_masters default masters
# @param default_provide_xfrs default provide xfrs
# @param notify_boolean notify boolean
# @param notify_command notify command
# @param require_backup require backup
#
class opendnssec (
  Boolean                       $enabled                = true,
  String[1, 32]                 $user                   = 'root',
  String[1, 32]                 $group                  = 'opendnssec',
  Integer[1, 7]                 $logging_level          = 3,
  Stdlib::Syslogfacility        $logging_facility       = 'local0',
  Array[String]                 $packages               = ['opendnssec', 'xsltproc'],
  String[1, 100]                $service_enforcer       = 'opendnssec-enforcer',
  String[1, 100]                $service_signer         = 'opendnssec-signer',
  Array[String]                 $sqlite_packages        = [],
  Array[String]                 $mysql_packages         = [],
  String[1, 100]                $repository_name        = 'SoftHSM',
  Stdlib::Unixpath              $repository_module      = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so',
  String[1, 100]                $repository_pin         = '1234',
  Optional[Integer]             $repository_capacity    = undef,
  String[1, 32]                 $repository_token_label = 'OpenDNSSEC',
  Boolean                       $skip_publickey         = true,
  Opendnssec::Datastore         $datastore_engine       = 'mysql',
  Stdlib::Host                  $datastore_host         = 'localhost',
  Stdlib::Port                  $datastore_port         = 3306,
  String[1, 100]                $datastore_name         = 'kasp',
  String[1, 100]                $datastore_user         = 'opendnssec',
  String[1, 100]                $datastore_password     = 'change_me',
  Stdlib::Unixpath              $mysql_sql_file         = '/usr/share/opendnssec/database_create.mysql',
  Stdlib::Unixpath              $base_dir               = '/var/lib/opendnssec',
  Stdlib::Unixpath              $policy_file            = '/etc/opendnssec/kasp.xml',
  Stdlib::Unixpath              $zone_file              = '/etc/opendnssec/zonelist.xml',
  Stdlib::Unixpath              $tsigs_dir              = '/etc/opendnssec/tsigs',
  Stdlib::Unixpath              $remotes_dir            = '/etc/opendnssec/remotes',
  Stdlib::Unixpath              $xsl_file               = '/usr/share/opendnssec/addns.xsl',
  Stdlib::Unixpath              $sqlite_file            = "${base_dir}/kasp.db",
  Stdlib::Unixpath              $working_dir            = "${base_dir}/tmp",
  Stdlib::Unixpath              $signconf_dir           = "${base_dir}/signconf",
  Stdlib::Unixpath              $signed_dir             = "${base_dir}/signed",
  Stdlib::Unixpath              $unsigned_dir           = "${base_dir}/unsigned",
  Stdlib::Unixpath              $ksmutil_path           = '/usr/bin/ods-ksmutil',
  Stdlib::Unixpath              $enforcer_path          = '/usr/sbin/ods-enforcer',
  Optional[Stdlib::Ip::Address] $listener_address       = undef,
  Stdlib::Port                  $listener_port          = 53,
  Boolean                       $xferout_enabled        = true,
  Hash                          $zones                  = {},
  Hash                          $policies               = {},
  Hash                          $remotes                = {},
  Hash                          $tsigs                  = {},
  String                        $default_tsig_name      = 'NOKEY',
  String                        $default_policy_name    = 'default',
  Array[String]                 $default_masters        = [],
  Array[String]                 $default_provide_xfrs   = [],
  Boolean                       $notify_boolean         = false,
  Optional[String[1]]           $notify_command         = undef,
  Boolean                       $require_backup         = false,
) {
  unless $default_tsig_name == 'NOKEY' or $default_tsig_name in $tsigs {
    fail("${default_tsig_name}: default_tsig_name must be a defined tsig")
  }
  $default_masters.each |String $master| {
    unless $master in $remotes {
      fail("${master}: default_master must be a defined remote")
    }
  }
  $default_provide_xfrs.each |String $provide_xfr| {
    unless $provide_xfr in $remotes {
      fail("${provide_xfr}: default_provide_xfr must be a defined remote")
    }
  }

  $services = [$service_enforcer, $service_signer]
  stdlib::ensure_packages($packages)

  include opendnssec::datastore

  file {[$base_dir, $signed_dir, $unsigned_dir, $tsigs_dir, $remotes_dir, $signconf_dir, $working_dir]:
    ensure => 'directory',
    mode   => '0640',
    owner  => $user,
    group  => $group;
  }
  file { $xsl_file:
    ensure => file,
    source => 'puppet:///modules/opendnssec/usr/share/opendnssec/addns.xsl',
  }

  file { '/etc/opendnssec/conf.xml':
    ensure  => 'file',
    mode    => '0644',
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/conf.xml.erb');
  }
  file { '/etc/opendnssec/MASTER':
    ensure => stdlib::ensure($enabled, 'file'),
    mode   => '0644',
    owner  => $user,
    group  => $group;
  }
  file { '/var/lib/opendnssec/enforcer/zones.xml':
    ensure  => 'link',
    target  => '/etc/opendnssec/zonelist.xml',
    replace => true,
    links   => manage,
  }

  # configure policies file
  concat { $policy_file:
    owner  => $user,
    group  => $group,
    notify => Service[$services],
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

  # configure $zones file
  concat { $zone_file:
    owner  => $user,
    group  => $group,
    notify => Service[$services],
  }
  concat::fragment { 'zone_header':
    target  => $zone_file,
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<!-- File managed by Puppet DO NOT EDIT -->\n\n<ZoneList>\n",
    order   => '01',
  }
  concat::fragment { 'zone_footer':
    target  => $zone_file,
    content => "</ZoneList>\n",
    order   => '99',
  }

  if $enabled {
    # Bug: https://github.com/trlinkin/puppet-lint-exec_idempotent-check/issues/2
    # lint:ignore:exec_idempotency
    exec {
      default:
        user        => $user,
        refreshonly => true;
      'updated conf.xml':
        command   => "${enforcer_path} update conf",
        subscribe => [File['/etc/opendnssec/conf.xml'], $opendnssec::datastore::subscribe];
      'ods-ksmutil updated zonelist.xml':
        command   => "${enforcer_path} zonelist import --remove-missing-zones",
        subscribe => Concat[$zone_file];
      'ods-ksmutil updated kasp.xml':
        command   => "${enforcer_path} policy import --remove-missing-policies",
        subscribe => Concat[$policy_file];
    }
    # lint:endignore
  }
  service { $service_enforcer:
    ensure => stdlib::ensure($enabled, 'service'),
    enable => true,
  }
service { $service_signer:
  ensure  => stdlib::ensure($enabled, 'service'),
  enable  => $enabled,
  require => Service[$service_enforcer],
}
  opendnssec::addns { 'default':
    masters      => $default_masters,
    provide_xfrs => $default_provide_xfrs,
  }
  $tsigs.each |$name, $config| {
    opendnssec::tsig { $name:
      * => $config,
    }
  }
  $remotes.each |$name, $config| {
    opendnssec::remote { $name:
      * => $config,
    }
  }
  $policies.each |$policy, $config| {
    opendnssec::policy { $policy:
      * => $config,
    }
  }
  unless $default_policy_name in $policies {
    opendnssec::policy { $default_policy_name: }
  }
  $zones.each |$zone, $config| {
    opendnssec::zone { $zone:
      * => $config,
    }
  }
}
