#!/usr/bin/env bash

# Pull the latest version of the sMAP source, and build a deb of it if the version is higher
# than what we last had

set -e

BASEDIR=/srv/buildd/smap
WORKDIR=$BASEDIR/$(date +"%d.%m.%y_%H_%M")
if [ ! -e $BASEDIR/lastversion ]
then
    echo "0" >> $BASEDIR/lastversion
fi
LASTVER=$(cat $BASEDIR/lastversion)
export DEBFULLNAME="Michael Andersen"
export DEBEMAIL="m.andersen@berkeley.edu"
REPO="http://smap-data.googlecode.com/svn/trunk/"

mkdir -p $WORKDIR
cd $WORKDIR


svn co $REPO smap
cd $WORKDIR/smap/
CURVER=$(($(svn info | grep "Last Changed Rev:" | cut -d ":" -f 2)))

echo "Head version is $CURVER"
if [ $CURVER -le $LASTVER ]
then
    echo "Repository has not been updated"
    exit 0
fi

LASTLOG=$(svn log | head -n 4 | tail -n 1)

#Copy in our local changelog
cd $BASEDIR
dch --distribution raring -v 2.0.$CURVER --check-dirname-level 0 "commit-msg: $LASTLOG"

cp $BASEDIR/debian/changelog $WORKDIR/smap/python/debian/changelog
cp $BASEDIR/debian/control $WORKDIR/smap/python/debian/control

cd $WORKDIR/smap/python

#Taken from SDH's publish-deb
rm -rf dist
rm -rf smap/schema
cp -rp ../schema smap
python setup.py sdist 2>&1

cd dist
tar zxvf *.tar.gz
SOURCE=$(find . -maxdepth 1 -type d -name 'Smap*' -print )
echo source dir is  $SOURCE
cd $SOURCE
dpkg-buildpackage -rfakeroot -uc -us -S 2>&1
cd ..
#This key is Michael Andersen's software signing key
debsign -k6E82A804 smap_*.changes
cd $WORKDIR/smap/python/dist
dput ppa:mandersen/smap smap*.changes
echo $CURVER > $BASEDIR/lastversion
echo "Completed revision $CURVER"

