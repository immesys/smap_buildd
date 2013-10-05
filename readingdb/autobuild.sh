#!/usr/bin/env bash

set -e

# Pull the latest version of the readingdb source, and build a deb of it if the version is higher
# than what we last had
REPO="https://github.com/stevedh/readingdb.git"
REPOBRANCH="microseconds"
VERSION=0.6.0-6
BASEDIR=/srv/buildd/readingdb
WORKDIR=$BASEDIR/$(date +"%d.%m.%y_%H_%M")
if [ ! -e $BASEDIR/lastversion ]
then
    echo "0" >> $BASEDIR/lastversion
fi
LASTVER=$(cat $BASEDIR/lastversion)
export DEBFULLNAME="Michael Andersen"
export DEBEMAIL="m.andersen@berkeley.edu"


mkdir -p $WORKDIR
cd $WORKDIR
echo "PWD is "`pwd`
git clone $REPO readingdb

cd readingdb
git checkout $REPOBRANCH

LASTCOMMIT=$(git log -n1 --format="%H")
echo "LAST COMMIT IS: "$LASTCOMMIT
LASTLOG=$(git log -n 1 --format=oneline)

if [ $LASTVER = $LASTCOMMIT ]
then
    echo "Last commit has already been processed"
    exit 0
fi

DBID=$($BASEDIR/../gitversion.py $REPO $LASTCOMMIT $VERSION)

echo "Using -git$DBID for changeset $LASTCOMMIT from $REPO"

#Copy in our local changelog
cd $BASEDIR
FULLVER=$VERSION
FULLVER+=git$DBID
dch --distribution raring -v $FULLVER --check-dirname-level 0 "git($REPO): $LASTLOG"

cp $BASEDIR/debian/changelog $WORKDIR/readingdb/debian/changelog
cp $BASEDIR/debian/control $WORKDIR/readingdb/debian/control
cp $BASEDIR/debian/compat $WORKDIR/readingdb/debian/compat

# Make sure all the pkg-check lines are uncommented
sed -i 's/^#\s*\(PKG_CHECK_MODULES.*\)$/\1/g' $WORKDIR/readingdb/configure.ac
sed -i 's/^#\s*\(PKG_CHECK_MODULES.*\)$/\1/g' $WORKDIR/readingdb/src/hashtable/configure.ac

cd $WORKDIR/readingdb
dpkg-buildpackage -rfakeroot -uc -us -S
#cd ..
#This key is Michael Andersen's software signing key
cd $WORKDIR
debsign -k6E82A804 readingdb_*.changes
dput ppa:mandersen/smap readingdb_*.changes

#---------------------
# A'ight lets do the python part
cd $WORKDIR/readingdb
autoreconf --install
./configure
make

cd $BASEDIR/py/
dch --distribution raring -v $FULLVER --check-dirname-level 0 "git($REPO): $LASTLOG"

cd $WORKDIR/readingdb/python

cp $BASEDIR/py/debian/changelog $WORKDIR/readingdb/python/debian/changelog
cp $BASEDIR/py/debian/control $WORKDIR/readingdb/python/debian/control
cp $BASEDIR/py/debian/compat $WORKDIR/readingdb/python/debian/compat
# There is currently a typo that I haven't sent upstream to Steve yet
cp $BASEDIR/py/Makefile $WORKDIR/readingdb/python/Makefile

cd $WORKDIR/readingdb/python/
#dpkg-buildpackage -rfakeroot -uc -us -S
make builddeb
cd $WORKDIR/readingdb/
debsign -k6E82A804 readingdb-python*.changes
dput ppa:mandersen/smap readingdb-python*.changes

echo $LASTCOMMIT > $BASEDIR/lastversion

