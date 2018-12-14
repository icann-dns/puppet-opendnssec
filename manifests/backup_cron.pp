# Class Opendnssec::backup
#
class opendnssec::backup_cron (
  Stdlib::Host         $backup_host,
  String[1,32]         $backup_user,
  String               $backup_glob,
  String               $date_format,
  Integer              $retention,
  Stdlib::Absolutepath $backup_dir,
  Stdlib::Absolutepath $tmp_dirbase,
  Stdlib::Absolutepath $script_path,

) {
  include ::opendnssec
  $user             = $::opendnssec::user
  $group            = $::opendnssec::group
  $datastore_engine = $::opendnssec::datastore_engine
  $require_backup   = $::opendnssec::require_backup
  
  file {[$backup_dir, $tmp_dirbase]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }
  if $require_backup {
    if $datastore_engine == 'mysql' {
      file {$script_path:
        ensure  => file,
        mode    => '0755',
        owner   => $user,
        group   => $group,
        content => template('opendnssec/usr/local/bin/backup-hsm-mysql.sh.erb'),
      }
      cron {'backup-hsm-mysql':
        ensure  => present,
        command => $script_path,
        user    => $user,
        hour    => '*/6',
        minute  => 0,
        require => File[$script_path],
      }
    }
  }
  else {
    if $datastore_engine == 'mysql' {
      file {$script_path:
        ensure  => absent,
      }
      cron {'backup-hsm-mysql':
        ensure  => absent,
      }
    }
  }
}
