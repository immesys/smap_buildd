#!/usr/bin/env bash

# Pull the latest version of the sMAP powerdb2 source, and build a deb of it if the version is higher
# than what we last had

set -e

BASEDIR=/srv/buildd/powerdb2
WORKDIR=$BASEDIR/$(date +"%d.%m.%y_%H_%M")
if [ ! -e $BASEDIR/lastversion ]
then
    echo "0" >> $BASEDIR/lastversion
fi
LASTVER=$(cat $BASEDIR/lastversion)
export DEBFULLNAME="Michael Andersen"
export DEBEMAIL="m.andersen@berkeley.edu"
REPO="http://smap-data.googlecode.com/svn/branches/powerdb2"

mkdir -p $WORKDIR
cd $WORKDIR
CURVER=$(($(svn info $REPO | grep "Revision" | cut -d ":" -f 2)))

echo "Head version is $CURVER"
if [ $CURVER -le $LASTVER ]
then
    echo "Repository has not been updated"
    exit 0
fi

svn co $REPO powerdb2
cd $WORKDIR/powerdb2/

LASTLOG=$(svn log | head -n 4 | tail -n 1)

#Copy in our local changelog
cd $BASEDIR
dch --distribution raring -v 2.0.$CURVER --check-dirname-level 0 "commit-msg: $LASTLOG"

cp $BASEDIR/debian/changelog $WORKDIR/powerdb2/debian/changelog
cp $BASEDIR/debian/compat $WORKDIR/powerdb2/debian/compat

cd $WORKDIR/powerdb2
sed -i "s/^\\(VERSION=\\).*\$/\1$CURVER/g" Makefile
make dist
make builddeb

cd $WORKDIR/powerdb2/dist/

#This key is Michael Andersen's software signing key
debsign -k6E82A804 powerdb2*.changes
dput ppa:mandersen/smap powerdb2*.changes

echo $CURVER > $BASEDIR/lastversion
echo "Completed revision $CURVER"
