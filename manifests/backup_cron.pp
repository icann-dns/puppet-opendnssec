# Class Opendnssed::backup
#
class opendnssec::backup_cron (
  Tea::Host            $backup_host,
  String[1,32]         $backup_user = 'backup',
  String               $backup_glob = '*.tar.bz2',
  String               $date_format = '%Y%m%d-%H%M',
  Integer              $retention   = 500,
  Stdlib::Absolutepath $backup_dir  = '/opt/backup',
  Stdlib::Absolutepath $tmp_dirbase = '/opt/tmp',
  Stdlib::Absolutepath $script_path = '/usr/local/bin/backup-hsm-mysql.sh',

) {
  include ::opendnssec
  $user             = $::opendnssec::user
  $group            = $::opendnssec::group
  $datastore_engine = $::opendnssec::datastore_engine
  file {[$backup_dir, $tmp_dirbase]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }
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
