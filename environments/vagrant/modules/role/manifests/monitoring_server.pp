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

  icinga2::object::hostgroup { 'linux_servers': }
  Icinga2::Object::Host <<| |>>

  icinga2::object::apply_service { 'check_load':
    display_name   => 'Load from nrpe',
    check_command  => 'nrpe',
    vars           => {
                        nrpe_command => 'check_load',
                      },
    assign_where   => '"linux_servers" in host.groups',
    ignore_where   => 'host.name == "localhost"',
    target_dir     => '/etc/icinga2/objects/applys'
  }

  icinga2::object::apply_service { 'check_swap':
    display_name   => 'Swap from nrpe',
    check_command  => 'nrpe',
    vars           => {
                        nrpe_command => 'check_swap',
                      },
    assign_where   => '"linux_servers" in host.groups',
    ignore_where   => 'host.name == "localhost"',
    target_dir     => '/etc/icinga2/objects/applys'
  }

  icinga2::object::apply_service { 'check_disk':
    display_name   => 'Disk from nrpe',
    check_command  => 'nrpe',
    vars           => {
                        nrpe_command => 'check_disk',
                      },
    assign_where   => '"linux_servers" in host.groups',
    ignore_where   => 'host.name == "localhost"',
    target_dir     => '/etc/icinga2/objects/applys'
  }

  icinga2::object::apply_service { 'check_hpacucli':
    display_name   => 'hpacucli from nrpe',
    check_command  => 'nrpe',
    vars           => {
                        nrpe_command => 'check_hpacucli',
                      },
    assign_where   => '"linux_servers" in host.groups',
    ignore_where   => 'regex("(localhost|compute0(4|5))", host.name)',
    target_dir     => '/etc/icinga2/objects/applys'
  }

  package { 'nrpe':
    ensure => installed,
  }

  package { 'nagios-plugins':
    ensure => installed,
  }

  if $::icingaweb2::install_method == 'git' {
    $sql_schema_location = '/usr/share/icingaweb2/etc/schema/mysql.schema.sql'
  } else {
    $sql_schema_location = '/usr/share/doc/icingaweb2/schema/mysql.schema.sql'
  }

  class {'::icingaweb2':
    admin_users         => 'data',
    ido_db_name         => 'icinga2_data',
    ido_db_pass         => $icinga_db_password,
    ido_db_user         => 'icinga2',
    web_db_pass         => $icingaweb2_db_password,
    manage_apache_vhost => true,
    initialize          => true,
  }

  class {'::icingaweb2::mod::monitoring':}

  file_line { 'date.timezone':
    path => '/etc/php.ini',
    line => 'date.timezone=UTC',
    match => '^.*date.timezone=.*',
  }

}
