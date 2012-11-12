# repo

class wikidata::repo {

	require mysql

	$mwserver = "http://127.0.0.1:8080"

	file { "/etc/apache2/sites-available/repo":
		mode => 644,
		owner => root,
		group => root,
		content => template("apache/sites/repo"),
		ensure => present,
		require => Package["apache2"];
	} ->

	apache::enable_site { "repo":
		name => "repo",
		require => File["/etc/apache2/sites-available/repo"];
	}

	apache::disable_site { "default": name => "default"; }

	file { "/srv/orig/":
		ensure => 'directory';
	}

	exec { "repo_setup":
		#require => [Exec["mysql-set-password"], Service["apache2"], File["/srv/orig"]],
		require => [Exec["mysql-set-password"], File["/srv/orig"]],
		creates => "/srv/orig/LocalSettings.php",
		command => "/usr/bin/php /srv/repo/maintenance/install.php Wikidata-repo admin --pass vagrant --dbname repo --dbuser root --dbpass vagrant --server '$mwserver' --scriptpath '/srv/repo' --confpath '/srv/orig/'",
		logoutput => "on_failure";
	} ->

	file { "/var/www/srv":
		ensure => "directory";
	}

	file { "/var/www/srv/repo":
		require => File["/var/www/srv"],
		ensure  => "link",
		target  => "/srv/repo";
	}

# update script I
# hier nochmal sicherstellen, dass /srv/repo/LocalSettings.php NICHT existiert!
	exec { "update":
		require => Exec["repo_setup"],
		command => "/usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/orig/LocalSettings.php'",
		unless => "/usr/bin/test -e /srv/repo/LocalSettings.php",
		logoutput => "on_failure";
	}

# get Wikidata-specific stuff AFTER MW is up
	file { "/srv/repo/LocalSettings.php":
		require => [Exec["repo_setup"], Exec["update"]],
		content => template('wikidata/wikibase-repo-localsettings'),
		ensure => present;
	}

# update script II
# hier sicherstellen, dass das update script 2x aufgerufen wird!
	exec { "update2":
		require => [Exec["update"], File["/srv/repo/LocalSettings.php"]],
		command => "/usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/repo/LocalSettings.php'",
		logoutput => "on_failure";
	}

}

# client

class wikidata::client {

	require wikidata::repo

	file { "/etc/apache2/sites-available/client":
		mode => 644,
		owner => root,
		group => root,
		content => template("apache/sites/client"),
		ensure => present;
	} ->

	apache::enable_site { "client":
		name => "client",
		require => File["/etc/apache2/sites-available/client"];
	}

	exec { "client_setup":
		require => [Exec["mysql-set-password"], Service["apache2"], File["/srv/orig/LocalSettings.php"]],
		command => "/usr/bin/php /srv/client/maintenance/install.php Wikidata-client admin --pass vagrant --dbname client --dbuser root --dbpass vagrant --server '$mwserver' --scriptpath '/srv/client' --confpath '/srv/orig/'",
		logoutput => "on_failure";
	} ->

	file { "/var/www/srv/client":
		require => File["/var/www/srv"],
		ensure  => "link",
		target  => "/srv/client";
	}

# update script I
	exec { "client_update":
		require => Exec["client_setup"],
		command => "/usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/orig/LocalSettings.php'",
		unless => "/usr/bin/test -e /srv/client/LocalSettings.php",
		logoutput => "on_failure";
	}

# get Wikidata-specific stuff AFTER MW is up
	file { "/srv/client/LocalSettings.php":
		require => [Exec["client_setup"], Exec["client_update"]],
		content => template('wikidata/wikibase-client-localsettings'),
		ensure => present;
	}

# update script II
	exec { "client_update2":
		require => [Exec["client_update"], File["/srv/client/LocalSettings.php"]],
		command => "/usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/client/LocalSettings.php'",
		logoutput => "on_failure";
	}

}
