# Class Opendnssed::backup
#
class opendnssec::backup (
  Tea::Host            $backup_host,
  String[32]           $backup_user = 'backup',
  String               $backup_glob = 'backup-20*.tar.bz2',
  Integer              $retention   = 500,
  Stdlib::Absolutepath $backup_dir  = '/opt/backup',
  Stdlib::Absolutepath $script_path = '/usr/local/bin/backup-hsm-mysql.sh',

) {
  include ::opendnssec
  $user = $::opendnssec::user
  $group = $::opendnssec::group
  file {'/usr/local/bin/backup-hsm-mysql.sh':
    ensure  => file,
    mode    => '0755',
    owner   => $user,
    group   => $group,
    content => template('opendnssec/usr/local/bin/backup-hsm-mysql.sh.erb'),
  }
  cron {'backup-hsm-mysql':
    ensure  => present,
    command => '/usr/local/bin/backup-hsm-mysql.sh',
    user    => $user,
    hour    => '*/6',
    minute  => 0,
    require => File['/usr/local/bin/backup-hsm-mysql.sh'],
  }
}
