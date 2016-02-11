class role::monitoring_server {

  $mysql_password         = 'password'
  $icinga_db_password     = 'password'
  $icingaweb2_db_password = 'password'

  class { '::apache':
    mpm_module => 'prefork',
  }
  include ::apache::mod::rewrite
  include ::apache::mod::prefork
  include ::apache::mod::php

  class { '::mysql::server':
    root_password => $mysql_password,
  } ->
  mysql::db { 'icinga2_data':
    user     => 'icinga2',
    password => $icinga_db_password,
    host     => 'localhost',
  }
  mysql::db { 'icingaweb2':
    user     => 'icingaweb2',
    password => $icingaweb2_db_password,
    host     => 'localhost',
  }

  class { '::icinga2':
    db_type                       => 'mysql',
    db_host                       => 'localhost',
    db_port                       => '3306',
    db_name                       => 'icinga2_data',
    db_user                       => 'icinga2',
    db_pass                       => $icinga_db_password,
    manage_database               => true,
    install_plugins               => true,
    install_mailutils             => false,
  }

  icinga2::object::hostgroup { 'Linux Servers': }
  Icinga2::Object::Host <<| |>>

  package { 'icingacli':
    ensure => installed,
  }

  package { 'nrpe':
    ensure => installed,
  }

  package { 'nagios-plugins':
    ensure => installed,
  }

  class {'::icingaweb2':
    admin_users         => 'data',
    ido_db_name         => 'icinga2_data',
    ido_db_pass         => $icinga_db_password,
    ido_db_user         => 'icinga2',
    web_db_pass         => $icingaweb2_db_password,
    manage_apache_vhost => true,
    install_method      => 'package',
    config_dir_recurse  => true,
    require             => Package['icingacli'],
  }

  class {'::icingaweb2::mod::monitoring':}

  file_line { 'date.timezone':
    path => '/etc/php.ini',
    line => 'date.timezone=UTC',
    match => '^.*date.timezone=.*',
  }

  exec { 'ln -s /usr/share/icingaweb2/modules/setup /etc/icingaweb2/enabledModules/':
    creates => '/etc/icingaweb2/enabledModules/setup/',
    require => Class['::icingaweb2'],
  }

  exec { 'icingacli setup token create':
    creates => '/etc/icingaweb2/setup.token',
    require => Class['::icingaweb2'],
  }


}
