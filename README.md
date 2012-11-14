Wikidata-vagrant
===========

This project is a fork of https://github.com/atdt/wmf-vagrant.git to be adapted to Wikidata. At the moment it is not ready for use!

## Prerequisites ##

You'll need to install [Vagrant][0] and [VirtualBox][1] (>= 4.1).

## Installation ##

```bash
git clone https://github.com/SilkeMeyer/wikidata-vagrant.git
cd ./wikidata-vagrant
git submodule update --init
vagrant up
# If the mediawiki update script (Wikidata::Repo/Exec[repo_update]) fails, reboot the Vagrant machine by running
vagrant reload
```

It'll take some time, because it'll need to fetch the base precise32 box and MediaWiki core (twice) plus the extensions. Once it's done, browse to http://127.0.0.1:8080. You find a Wikidata repo and client preinstalled, served by the guest VM, which is running Ubuntu Precise 32-bit.

The vagrant root folder is mounted `/srv`, and port 8080 on the host is forwarded to port 80 on the guest.

The MySQL root credentials are:

* Username: root
* Password: vagrant

The MediaWiki credentials are:

* Username: admin
* Password: vagrant

  [0]: http://vagrantup.com/v1/docs/getting-started/index.html
  [1]: https://www.virtualbox.org/wiki/Downloads
