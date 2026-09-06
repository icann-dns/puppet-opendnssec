# @summary Manage OpenDNSSEC backup cron job
# @param backup_host Host to backup to
# @param backup_user User to backup as
# @param backup_glob Glob to backup
# @param date_format Date format to use
# @param retention Number of days to retain backups
# @param backup_dir Directory to store backups
# @param tmp_dirbase Directory to store temporary files
# @param script_path Path to the backup script
# @param restore_script Path to the restore script
# @param require_backup Whether to require a backup
#
class opendnssec::backup_cron (
  Stdlib::Host     $backup_host    = 'localhost',
  String[1, 32]    $backup_user    = 'backup',
  String           $backup_glob    = '*.tar.bz2',
  String           $date_format    = '%Y%m%d-%H%M',
  Integer          $retention      = 500,
  Stdlib::Unixpath $backup_dir     = '/opt/backup',
  Stdlib::Unixpath $tmp_dirbase    = '/opt/tmp',
  Stdlib::Unixpath $script_path    = '/usr/local/bin/backup-hsm-mysql.sh',
  Stdlib::Unixpath $restore_script = '/usr/local/bin/restore-hsm-opendnssec.sh',
  Boolean          $require_backup = false,
) {
  include opendnssec
  $user               = $opendnssec::user
  $group              = $opendnssec::group
  $datastore_engine   = $opendnssec::datastore_engine

  file {[$backup_dir, $tmp_dirbase]:
    ensure => directory,
    owner  => $backup_user,
    group  => $group,
  }
  if $datastore_engine == 'mysql' {
    file {
      default:
        ensure => stdlib::ensure($require_backup, 'file'),
        mode   => '0755',
        owner  => $user,
        group  => $group;
      $script_path:
        content => template('opendnssec/usr/local/bin/backup-hsm-mysql.sh.erb');
      $restore_script:
        source => 'puppet:///modules/opendnssec/usr/local/bin/restore-hsm-opendnssec.sh';
    }
    cron { 'backup-hsm-mysql':
      ensure  => stdlib::ensure($require_backup),
      command => $script_path,
      user    => $user,
      hour    => '*/6',
      minute  => 0,
      require => File[$script_path],
    }
  }
}
