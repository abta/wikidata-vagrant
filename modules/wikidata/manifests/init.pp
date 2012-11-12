# client

class wikidata {

# later: class wikidata::client {

	require mediawiki
	# later: require wikidata::repo

	file { "/etc/apache2/sites-available/client":
		mode => 644,
		owner => root,
		group => root,
		content => template("apache/sites/client"),
		ensure => present,
		require => Package["apache2"];
	} ->

	apache::enable_site { "client":
		name => "client",
		require => File["/etc/apache2/sites-available/client"];
	}

	exec { "client_setup":
		require => [Exec["mysql-set-password"], Service["apache2"], File["/srv/orig"]],
		command => "/usr/bin/php /srv/client/maintenance/install.php Wikidata-client admin --pass vagrant --dbname client --dbuser root --dbpass vagrant --server '$mwserver' --scriptpath '/srv/client' --confpath '/srv/orig/'",
		logoutput => "on_failure";
	} ->

	file { "/var/www/srv":
		ensure => "directory";
	}

	file { "/var/www/srv/client":
		require => File["/var/www/srv"],
		ensure  => "link",
		target  => "/srv/client";
	}

# update script I
	exec { "update":
		require => Exec["client_setup"],
		command => "/usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/orig/LocalSettings.php'",
		unless => "/usr/bin/test -e /srv/client/LocalSettings.php";
	}

# get Wikidata-specific stuff AFTER MW is up
	file { "/srv/client/LocalSettings.php":
		require => [Exec["client_setup"], Exec["update"]],
		content => template('wikidata/wikibase-client-localsettings'),
		ensure => present;
	}

# update script II
	exec { "update2":
		require => [Exec["update"], File["/srv/client/LocalSettings.php"]],
		command => "/usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/client/LocalSettings.php'";
	}

}
