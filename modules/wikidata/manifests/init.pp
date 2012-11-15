# repo

class wikidata::repo {

	require mysql

	$mwserver = "http://127.0.0.1:8080"

	file { "/etc/apache2/sites-available/wikidata":
		mode => 644,
		owner => root,
		group => root,
		content => template("apache/sites/wikidata"),
		ensure => present,
		require => Package["apache2"];
	} ->

	apache::enable_site { "wikidata":
		name => "wikidata",
		require => File["/etc/apache2/sites-available/wikidata"];
	}

	apache::disable_site { "default": name => "default"; }

	file { "/srv/orig-repo/":
		ensure => 'directory';
	}

	exec { "repo_setup":
		require => [Exec["mysql-set-password"], File["/srv/orig-repo"]],
		creates => "/srv/orig-repo/LocalSettings.php",
		command => "/usr/bin/php /srv/repo/maintenance/install.php Wikidata-repo admin --pass vagrant --dbname repo --dbuser root --dbpass vagrant --server 'http://localhost:8080' --scriptpath '/repo' --confpath '/srv/orig-repo/'",
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
	exec { "repo_update":
		require => Exec["repo_setup"],
		command => "/usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/orig-repo/LocalSettings.php'",
		unless => "/usr/bin/test -e /srv/repo/LocalSettings.php",
		logoutput => "on_failure";
	}

# get Wikidata-specific stuff AFTER MW is up

	file { "/var/www/srv/repo/skins/common/images/Wikidata-logo-demorepo.png":
		source => "puppet:///modules/wikidata/Wikidata-logo-demorepo.png",
		require => Exec["repo_update"];
	}

	file { "/srv/repo/LocalSettings.php":
		require => [Exec["repo_setup"], Exec["repo_update"]],
		content => template('wikidata/wikibase-repo-localsettings'),
		ensure => present;
	}

# update script II
	exec { "repo_update2":
		require => [Exec["repo_update"], File["/srv/repo/LocalSettings.php"]],
		provider => shell,
		command => "MW_INSTALL_PATH=/srv/repo /usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/repo/LocalSettings.php' || MW_INSTALL_PATH=/srv/repo /usr/bin/php /srv/repo/maintenance/update.php --quick --conf '/srv/repo/LocalSettings.php'",
		logoutput => "on_failure";
	}

# for this to work we probably need to declare the mw install path
## import items
	exec { "import_items":
		require => Exec["repo_update2"],
		provider => shell,
		cwd => "/srv/extensions/Wikibase/repo/maintenance",
		command => "MW_INSTALL_PATH=/srv/repo /usr/bin/php importInterlang.php --verbose --ignore-errors simple simple-elements.csv",
		logoutput => "on_failure";
	}

# import properties
	exec { "import_properties":
		require => Exec["repo_update2"],
		provider => shell,
		cwd => "/srv/extensions/Wikibase/repo/maintenance",
		command => "MW_INSTALL_PATH=/srv/repo /usr/bin/php importProperties.php --verbose en en-elements-properties.csv",
		logoutput => "on_failure";
	}
}

# client

class wikidata::client {

	require wikidata::repo

	file { "/srv/orig-client/":
		ensure => 'directory';
	}

	exec { "client_setup":
		require => [Exec["mysql-set-password"], Service["apache2"]],
		creates => "/srv/orig-client/LocalSettings.php",
		command => "/usr/bin/php /srv/client/maintenance/install.php Wikidata-client admin --pass vagrant --dbname client --dbuser root --dbpass vagrant --server 'http://localhost:8080' --scriptpath '/client' --confpath '/srv/orig-client/'",
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
		command => "/usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/orig-client/LocalSettings.php'",
		unless => "/usr/bin/test -e /srv/client/LocalSettings.php",
		logoutput => "on_failure";
	}

# get Wikidata-specific stuff AFTER MW is up

	file { "/var/www/srv/client/skins/common/images/Wikidata-logo-democlient.png":
		source => "puppet:///modules/wikidata/Wikidata-logo-democlient.png",
		require => Exec["repo_update"];
	}

	file { "/srv/client/LocalSettings.php":
		require => [Exec["client_setup"], Exec["client_update"]],
		content => template('wikidata/wikibase-client-localsettings'),
		ensure => present;
	}

# update script II
	exec { "client_update2":
		require => [Exec["client_update"], File["/srv/client/LocalSettings.php"]],
		provider => shell,
		command => "MW_INSTALL_PATH=/srv/client /usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/client/LocalSettings.php' || MW_INSTALL_PATH=/srv/client /usr/bin/php /srv/client/maintenance/update.php --quick --conf '/srv/client/LocalSettings.php'",
		logoutput => "on_failure";
	}

	exec { "populate_interwiki":
		require => Exec["client_update2"],
		cwd => "/srv/extensions/Wikibase/client/maintenance",
		provider => shell,
		command => "MW_INSTALL_PATH=/srv/client /usr/bin/php populateInterwiki.php",
		logoutput => "on_failure";
	}

# for client repo replication
	user { "www-data":
		ensure => present
	}
# replication log file
	file { "/var/log/wikidata-replication.log":
		ensure => present,
		owner => "www-data",
		group => "www-data",
		mode => "0664";
	}
# poll for changes
	cron { "pollForChanges":
		ensure => present,
		require => Exec["client_update2"],
		command => "/bin/sleep 300 ; MW_INSTALL_PATH=/srv/client /usr/bin/php /srv/extensions/Wikibase/lib/maintenance/pollForChanges.php --since \"yesterday\" >> /var/log/wikidata-replication.log",
		user => "www-data",
		minute => "*/5";
	}

}
