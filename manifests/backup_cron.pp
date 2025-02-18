# @summary Manage OpenDNSSEC backup cron job
# @param backup_host Host to backup to
# @param backup_user User to backup as
# @param backup_glob Glob to backup
# @param date_format Date format to use
# @param retention Number of days to retain backups
# @param backup_dir Directory to store backups
# @param tmp_dirbase Directory to store temporary files
# @param script_path Path to the backup script
# @param require_backup Whether to require a backup
#
class opendnssec::backup_cron (
  Stdlib::Host     $backup_host    = 'localhost',
  String[1,32]     $backup_user    = 'bacuckup',
  String           $backup_glob    = '*.tar.bz2',
  String           $date_format    = '%Y%m%d-%H%M',
  Integer          $retention      = 500,
  Stdlib::Unixpath $backup_dir     = '/opt/backup',
  Stdlib::Unixpath $tmp_dirbase    = '/opt/tmp',
  Stdlib::Unixpath $script_path    = '/usr/local/bin/backup-hsm-mysql.sh',
  Boolean          $require_backup = false,
) {
  include opendnssec
  $user               = $opendnssec::user
  $group              = $opendnssec::group
  $datastore_engine   = $opendnssec::datastore_engine

  file {[$backup_dir, $tmp_dirbase]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }
  if $require_backup == false {
    if $datastore_engine == 'mysql' {
      file { $script_path:
        ensure  => absent,
      }
      cron { 'backup-hsm-mysql':
        ensure  => absent,
      }
    }
  }
  else {
    if $datastore_engine == 'mysql' {
      file { $script_path:
        ensure  => file,
        mode    => '0755',
        owner   => $user,
        group   => $group,
        content => template('opendnssec/usr/local/bin/backup-hsm-mysql.sh.erb'),
      }
      cron { 'backup-hsm-mysql':
        ensure  => present,
        command => $script_path,
        user    => $user,
        hour    => '*/6',
        minute  => 0,
        require => File[$script_path],
      }
    }
  }
}
