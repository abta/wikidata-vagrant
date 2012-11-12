class mediawiki {

	require mysql

	$mwserver = "http://127.0.0.1:8000"

#	file { "/etc/apache2/sites-available/wiki":
#		mode => 644,
#		owner => root,
#		group => root,
#		content => template("apache/sites/wiki"),
#		ensure => present,
#		require => Package["apache2"];
#	} ->
#
#	apache::enable_site { "wiki":
#		name => "wiki",
#		require => File["/etc/apache2/sites-available/wiki"];
#	}

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
	exec { "update":
		require => Exec["repo_setup"],
		command => "/usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/orig/LocalSettings.php'",
		unless => "/usr/bin/test -e /srv/repo/LocalSettings.php";
	}

# get Wikidata-specific stuff AFTER MW is up
	file { "/srv/repo/LocalSettings.php":
		require => [Exec["repo_setup"], Exec["update"]],
		content => template('wikidata/wikibase-repo-localsettings'),
		ensure => present;
	}

# update script II
	exec { "update2":
		require => [Exec["update"], File["/srv/repo/LocalSettings.php"]],
		command => "/usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/repo/LocalSettings.php'";
	}

}
