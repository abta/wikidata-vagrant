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
```

It'll take some time, because it'll need to fetch the base precise32 box and MediaWiki plus the extensions. Once it's done, you should be able to browse to
http://127.0.0.1:8080/w/ and see a Wikidata repo install (later a client, too), served by the guest VM, which is running Ubuntu Precise 32-bit.

The `repo/` sub-folder in the repository is mounted as `/srv/repo`,
and port 8080 on the host is forwarded to port 80 on the guest.

The MySQL root password and the MediaWiki admin password are both "vagrant".

  [0]: http://vagrantup.com/v1/docs/getting-started/index.html
  [1]: https://www.virtualbox.org/wiki/Downloads
