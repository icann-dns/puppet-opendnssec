# @summary class to manage opendnssec
# @param enabled enable this module
# @param user user to run opendnssec
# @param group group to run opendnssec
# @param manage_packages manage packages
# @param manage_datastore manage datastore
# @param manage_service manage service
# @param manage_ods_ksmutil manage ods-ksmutil
# @param manage_conf manage conf
# @param opendnssec_version opendnssec version
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
  String[1,32]                  $user                   = 'root',
  String[1,32]                  $group                  = 'opendnssec',
  Boolean                       $manage_packages        = true,
  Boolean                       $manage_datastore       = true,
  Boolean                       $manage_service         = true,
  Boolean                       $manage_ods_ksmutil     = true,
  Boolean                       $manage_conf            = true,
  String[1,10]                  $opendnssec_version     = '1',
  Integer[1,7]                  $logging_level          = 3,
  Stdlib::Syslogfacility        $logging_facility       = 'local0',
  Array[String]                 $packages               = ['opendnssec', 'xsltproc'],
  String[1,100]                 $service_enforcer       = 'opendnssec-enforcer',
  String[1,100]                 $service_signer         = 'opendnssec-signer',
  Array[String]                 $sqlite_packages        = [],
  Array[String]                 $mysql_packages         = [],
  String[1,100]                 $repository_name        = 'SoftHSM',
  Stdlib::Unixpath              $repository_module      = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so',
  String[1,100]                 $repository_pin         = '1234',
  Optional[Integer]             $repository_capacity    = undef,
  String[1,32]                  $repository_token_label = 'OpenDNSSEC',
  Boolean                       $skip_publickey         = true,
  Opendnssec::Datastore         $datastore_engine       = 'mysql',
  Stdlib::Host                  $datastore_host         = 'localhost',
  Stdlib::Port                  $datastore_port         = 3306,
  String[1,100]                 $datastore_name         = 'kasp',
  String[1,100]                 $datastore_user         = 'opendnssec',
  String[1,100]                 $datastore_password     = 'change_me',
  Stdlib::Unixpath              $mysql_sql_file         = '/usr/share/opendnssec/database_create.mysql',
  Stdlib::Unixpath              $base_dir               = '/var/lib/opendnssec',
  Stdlib::Unixpath              $policy_file            = '/etc/opendnssec/kasp.xml',
  Stdlib::Unixpath              $zone_file              = '/etc/opendnssec/zonelist.xml',
  Stdlib::Unixpath              $tsigs_dir              = '/etc/opendnssec/tsigs',
  Stdlib::Unixpath              $remotes_dir            = '/etc/opendnssec/remotes',
  Stdlib::Unixpath              $xsl_file               = '/usr/share/opendnssec/addns.xsl',
  Stdlib::Unixpath              $sqlite_file            = "${base_dir}/kasp.db",
  Stdlib::Unixpath              $working_dir            = "${base_dir}/tmp",
  Stdlib::Unixpath              $signconf_dir           = "${base_dir}/signerconf",
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
  if $facts['os']['family'] == 'RedHat' and $datastore_engine == 'mysql' {
    fail('RedHat does not support mysql')
  }
  $ods_setup_command = $opendnssec_version ? {
    /^1/    => "/usr/bin/yes | ${ksmutil_path} setup",
    /^2/    => "${enforcer_path} setup",
    default => fail('opendnssec_version must be 1 or 2'),
  }
  $ods_update_conf_command = $opendnssec_version ? {
    /^1/    => "/usr/bin/yes | ${ksmutil_path} update conf",
    /^2/    => "${enforcer_path} update conf",
    default => fail('opendnssec_version must be 1 or 2'),
  }
  $datastore_setup_before = [$enabled, $manage_datastore, $manage_conf, $manage_ods_ksmutil].all |$i| { $i } ? {
    false => undef,
    true  => Exec['updated conf.xml'],
  }
  $exec_subscribe = $manage_conf ? {
    true  => File['/etc/opendnssec/conf.xml'],
    false => undef,
  }
  if $manage_packages {
    ensure_packages($packages)
  }
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
  if $enabled and $manage_datastore {
    if $datastore_engine == 'mysql' {
      if $manage_packages {
        ensure_packages($mysql_packages)
      }
      require  mysql::server
      mysql::db { $datastore_name:
        user     => $datastore_user,
        password => $datastore_password,
        sql      => [$mysql_sql_file],
        before   => $datastore_setup_before,
      }
    } elsif $datastore_engine == 'sqlite' {
      if $manage_packages {
        ensure_packages($sqlite_packages)
      }
      exec { 'ods-ksmutil setup':
        path     => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin'],
        provider => 'shell',
        command  => $ods_setup_command,
        unless   => "test -s ${sqlite_file}",
        before   => $datastore_setup_before,
      }
    }
  }
  if $manage_conf {
    create_resources(opendnssec::tsig, $tsigs)
    if $default_tsig_name != 'NOKEY' and ! defined(Opendnssec::Tsig[$default_tsig_name]) {
      fail("Opendnssec::Tsig['${default_tsig_name}'] defined by default_tsig_name does not exist")
    }

    create_resources(opendnssec::remote, $remotes)
    $default_masters.each |String $master| {
      if ! defined(Opendnssec::Remote[$master]) {
        fail("Opendnssec::Remote['${master}'] defined by default_master does not exist")
      }
    }
    $default_provide_xfrs.each |String $provide_xfr| {
      if ! defined(Opendnssec::Remote[$provide_xfr]) {
        fail("Opendnssec::Remote['${provide_xfr}'] defined by default_provide_xfr does not exist")
      }
    }
    file { '/etc/opendnssec/conf.xml':
      ensure  => 'file',
      mode    => '0644',
      owner   => $user,
      group   => $group,
      content => template('opendnssec/etc/opendnssec/conf.xml.erb');
    }
    opendnssec::addns { 'default':
      masters      => $default_masters,
      provide_xfrs => $default_provide_xfrs,
    }
    if $enabled {
      if $manage_ods_ksmutil {
        exec { 'updated conf.xml':
          command     => $ods_update_conf_command,
          user        => $user,
          refreshonly => true,
          subscribe   => $exec_subscribe,
        }
      }
    }
    file { '/etc/opendnssec/MASTER':
      ensure => stdlib::ensure($enabled, 'file'),
      mode   => '0644',
      owner  => $user,
      group  => $group;
    }
  }
  if ! defined(Class['opendnssec::policies']) {
    class { 'opendnssec::policies': policies => $policies }
  }
  if ! defined(Opendnssec::Policy[$default_policy_name]) {
    opendnssec::policy { $default_policy_name: }
  }
  if ! defined(Class['opendnssec::zones']) {
    class { 'opendnssec::zones': zones => $zones }
  }
  file { '/var/lib/opendnssec/enforcer/zones.xml':
    ensure  => 'link',
    target  => '/etc/opendnssec/zonelist.xml',
    replace => true,
    links   => manage,
  }

  if $enabled and $manage_service {
    service { $service_enforcer:
      ensure => running,
      enable => true,
    } ~> service { $service_signer:
      ensure => running,
      enable => true,
    }
    Opendnssec::Tsig   <| |> ~> Service[$service_enforcer, $service_signer]
    Opendnssec::Zone   <| |> -> Service[$service_enforcer, $service_signer]
    Opendnssec::Addns  <| |> ~> Service[$service_enforcer, $service_signer]
    Opendnssec::Policy <| |> -> Service[$service_enforcer, $service_signer]
    Opendnssec::Remote <| |> ~> Service[$service_enforcer, $service_signer]
  }
}
