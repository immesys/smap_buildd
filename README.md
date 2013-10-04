smap_buildd
===========

The buildserver scripts that scrape the SVN and push debian packages to launchpad

Essentially just tweak the paths in autobuild.sh and stick it in a cronjob.

Also, you would need to change the signing key and the PPA it tried to push to
