###########################################
##### This file is not used right now ! ###
###########################################

class wikidata {

	require mediawiki

	file { "/srv/repo/LocalSettings.php":
		require => Exec["repo_setup"],
		content => template('wikidata/wikibase-repo-localsettings'),
		ensure => present;
	}

#	file { "/var/www/srv/repo":
#		ensure => 'directory';
#	}

	exec { "rm-extensions-dir":
		require => Exec["repo_setup"],
		command => "rm -rf /var/www/srv/repo/extensions";
	}

	file { "/var/www/srv/repo/extensions":
		require => [File['/var/www/srv/repo'], Exec["rm-extensions-dir"]],
		ensure => 'link',
		target => '/srv/extensions';
	}

#	file { '/srv/client/LocalSettings.php':
#		require => Exec["mediawiki_setup"],
#		content => template('wikidata/wikibase-client-localsettings'),
#		ensure => present;
#	}

}
