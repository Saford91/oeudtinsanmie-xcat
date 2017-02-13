class xcat::params (
  $manage_repo = hiera('xcat::manage_repo'),
){

  $servicedefault = {
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    tag => 'xcat-service',
  }

  $enable_ipmi = hiera("xcat::enable_ipmi", true)

  case $::osfamily {
    'RedHat': {
      case $::operatingsystem {
        'CentOS': {
          $rmcmd = '/bin/rm'
          $cpcmd = '/bin/cp'
        }
        default: {
          $rmcmd = 'rm'
          $cpcmd = 'cp'
        }
      }
      if $::lsbmajdistrelease == undef {
        $majrelease = $::operatingsystemmajrelease
      }
      else {
        $majrelease = $::lsbmajdistrelease
      }

      $xcatcore_mirror = 'http://sourceforge.net/projects/xcat/files/yum/2.8/xcat-core'
      $xcatdep_mirror  = "http://sourceforge.net/projects/xcat/files/yum/xcat-dep/rh${majrelease}/${::architecture}"
      $key     = '/repodata/repomd.xml.key'
      $defaultrepo = {
        enabled  => 1,
        gpgcheck => 1,
        tag  => 'xcatrepo',
      }
      $repo_provider = 'yumrepo'
      $repos = {
        'xcat-2-core' => {
          descr => 'xCat 2 Core packages',
          baseurl => $xcatcore_mirror,
          gpgkey  => "${xcatcore_mirror}${key}",
        },
        'xcat-dep' => {
          descr => 'xCat 2 Core dependencies',
          baseurl => $xcatdep_mirror,
          gpgkey  => "${xcatdep_mirror}${key}",
        },
      }
      if $enable_ipmi {
        $service_list = {
          'xinetd'  => {},
          'xcatd'   => {},
          'ipmi'    => {},
        }
        $pkg_list = [
          "tftp-server.${::architecture}",
          "xCAT.${::architecture}",
          "OpenIPMI.${::architecture}",
          "xinetd.${::architecture}",
          'ipmitool',
        ]
      } else {
        $service_list = {
          'xinetd'  => {},
          'xcatd'   => {},
        }
        $pkg_list = [
          "tftp-server.${::architecture}",
          "xCAT.${::architecture}",
          "xinetd.${::architecture}",
        ]
      }
      $pkg_exclude = [ "atftp-xcat.${::architecture}" ]
    }
    'Debian': {
      $rmcmd = 'rm'
      $cpcmd = 'cp'
      $defaultrepo = {
        release => $::lsbdistcodename,
        repos   => 'main',
        tag     => 'xcatrepo',
        key     => {
          id     => '47AE47C50C45D502AEA2A47520E475A8DA736C68',
          server => 'pgp.mit.edu',
        },
      }
      $repo_provider = 'apt::source'
      $repos = {
        'xcat-core' => {
          comment  => 'xCat Core packages',
          location => 'http://xcat.org/files/xcat/repos/apt/2.11/xcat-core',
        },
        'xcat-dep' => {
          comment  => 'xCat Core dependencies',
          location => 'http://xcat.org/files/xcat/repos/apt/xcat-dep',
        },
      }
      $service_list = {
        'xinetd'  => {},
        'xcatd'   => {},
        'ipmievd' => {},
      }
      $pkg_list = [
        'tftpd-hpa',
        'xcat',
        'openipmi',
        'ipmitool',
      ]
      $pkg_exclude = []
    }
  }

  $firewalls = {
    '112 reject foward across vlans' => {
      chain => 'FORWARD',
      proto => 'all',
      action => 'reject',
    },
  }

  $configphase  = 'config'
  $setupphase   = 'setup'
}
