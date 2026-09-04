# @summry private class to configure datastore
class opendnssec::datastore {
  include opendnssec
  if $opendnssec::datastore_engine == 'mysql' {
    stdlib::ensure_packages($opendnssec::mysql_packages)
    require  mysql::server
    $subscribe = Mysql::Db[$opendnssec::datastore_name]
    mysql::db { $opendnssec::datastore_name:
      user     => $opendnssec::datastore_user,
      password => $opendnssec::datastore_password,
      # TODO: drop this after upgrade
      charset  => 'utf8',
      collate  => 'utf8_general_ci',
      sql      => [$opendnssec::mysql_sql_file],
    }
  } elsif $opendnssec::datastore_engine == 'sqlite' {
    stdlib::ensure_packages($opendnssec::sqlite_packages)
    $subscribe = Exec['ods-ksmutil setup']
    exec { 'ods-ksmutil setup':
      path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin'],
      command => "${opendnssec::enforcer_path} setup",
      unless  => "test -s ${opendnssec::sqlite_file}",
      before  => Exec['updated conf.xml'],
    }
  }
}
