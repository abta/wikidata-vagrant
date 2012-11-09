class apache {

	file { '/var/log/apache2/error.log':
	   ensure => 'link',
	   target => '/srv/apache2-error.log';
	} ->

	package { "apache2":
		ensure => present;
	}

	service { "apache2":
		ensure => running,
		require => Package["apache2"],
		hasstatus => true,
		hasrestart => true;
	}

	define disable_site( $name ) {
		exec { "/usr/sbin/a2dissite $name":
			require => Package["apache2"],
			notify => Exec["force-reload-apache2"];
		}
	}

	define enable_site( $name ) {
		exec { "/usr/sbin/a2ensite $name":
			require => Package["apache2"],
			notify => Exec["force-reload-apache2"];
		}
	}

	exec { "force-reload-apache2":
		command => "/etc/init.d/apache2 force-reload",
		refreshonly => true,
		before => Service["apache2"];
	}

	
	file { "/srv/index.html":
		source => "puppet:///modules/apache/index.html",
		ensure => present;
	}

	file { "/srv/favicon.ico":
		source => "puppet:///modules/apache/favicon.ico",
		ensure => present;
	}

	file { "/srv/style.css":
		source => "puppet:///modules/apache/srv/style.css",
		ensure => present;
	}

	file { "/srv/Wikidata-logo-demo.png":
		source => "puppet:///modules/apache/Wikidata-logo-demo.png",
		ensure => present;
	}

}
