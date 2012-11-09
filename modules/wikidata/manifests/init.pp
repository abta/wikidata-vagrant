class wikidata {

	file { '/srv/repo/LocalSettings.php':
		require => Exec["mediawiki_setup"],
		content => template('wikidata/wikibase-repo-localsettings'),
		ensure => present;
	}
}

	file { '/srv/client/LocalSettings.php':
		require => Exec["mediawiki_setup"],
		content => template('wikidata/wikibase-client-localsettings'),
		ensure => present;
	}
}
