class mediawiki {

	$mwserver = "http://127.0.0.1:8080"

	file { "/etc/apache2/sites-available/wiki":
		mode => 644,
		owner => root,
		group => root,
		content => template("apache/sites/wiki"),
		ensure => present,
		require => Package["apache2"];
	} ->

	apache::enable_site { "wiki":
		name => "wiki",
		require => File["/etc/apache2/sites-available/wiki"];
	}

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

	exec { 'repo_setup':
		require => [Package["mysql-server"], Exec["mysql-set-password"], Package["apache2"]],
		creates => "/srv/repo/LocalSettings.php",
		command => "/usr/bin/php /srv/repo/maintenance/install.php Wikidata-repo admin --pass vagrant --dbname repo --dbuser root --dbpass vagrant --server $mwserver --scriptpath '/srv/repo' --confpath '/srv/repo/'",
		logoutput => "on_failure";
	} ->

	file { "/var/www/srv":
		ensure => 'directory';
	}

	file { "/var/www/srv/repo":
		require => File['/var/www/srv'],
		ensure  => 'link',
		target  => '/srv/repo';
	}

	file { "/srv/repo/LocalSettings.php":
		require => Exec["repo_setup"],
		content => template('wikidata/wikibase-repo-localsettings'),
		ensure => present;
	}

}
