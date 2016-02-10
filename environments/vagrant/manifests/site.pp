node /icinga2-stack-puppet-profile.vm/ {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  include role::monitoring_server
}
