#!/usr/bin/env bash









set -ex

# Pull the latest version of the readingdb source, and build a deb of it if the version is higher
# than what we last had

REPO="https://github.com/softwaredefinedbuildings/readingdb.git"

REPOBRANCH=adaptive
VERSION=0.6.1
BASEDIR=/rust/buildd/readingdb
mkdir -p $BASEDIR
WORKDIR=$BASEDIR/build_$REPOBRANCH-$(date +"%d.%m.%y_%H_%M")
if [ ! -e $BASEDIR/lastversion ]
then
    echo "0" >> $BASEDIR/lastversion
fi
LASTVER=$(cat $BASEDIR/lastversion)
export DEBFULLNAME="Michael Andersen"
export DEBEMAIL="m.andersen@berkeley.edu"

mkdir -p $WORKDIR
cd $WORKDIR
git clone $REPO readingdb 2>&1

cd readingdb
git checkout $REPOBRANCH 2>&1

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
dch --distribution trusty -v $FULLVER --check-dirname-level 0 "git($REPO:$REPOBRANCH): $LASTLOG"

cp $BASEDIR/debian/changelog $WORKDIR/readingdb/debian/changelog
# These two are about to be sent upstream to SDH so may not be necessary
cp $BASEDIR/debian/control $WORKDIR/readingdb/debian/control
cp $BASEDIR/debian/compat $WORKDIR/readingdb/debian/compat

# Make sure all the pkg-check lines are uncommented
sed -i 's/^#\s*\(PKG_CHECK_MODULES.*\)$/\1/g' $WORKDIR/readingdb/configure.ac
sed -i 's/^#\s*\(PKG_CHECK_MODULES.*\)$/\1/g' $WORKDIR/readingdb/src/hashtable/configure.ac

cd $WORKDIR/readingdb
dpkg-buildpackage -rfakeroot -uc -us -S 2>&1

#This key is Michael Andersen's software signing key
cd $WORKDIR
debsign -k8B3731DC readingdb_*.changes
dput ppa:cal-sdb/smap readingdb_*.changes

#---------------------
# A'ight lets do the python part
cd $WORKDIR/readingdb
autoreconf --install
./configure
make

cd $BASEDIR/py/
dch --distribution trusty -v $FULLVER --check-dirname-level 0 "git($REPO:$REPOBRANCH): $LASTLOG"

cd $WORKDIR/readingdb/python

cp $BASEDIR/py/debian/changelog $WORKDIR/readingdb/python/debian/changelog
cp $BASEDIR/py/debian/control $WORKDIR/readingdb/python/debian/control
cp $BASEDIR/py/debian/compat $WORKDIR/readingdb/python/debian/compat
# There is currently a typo that I haven't sent upstream to Steve yet
cp $BASEDIR/py/Makefile $WORKDIR/readingdb/python/Makefile

cd $WORKDIR/readingdb/python/
#dpkg-buildpackage -rfakeroot -uc -us -S
make builddeb 2>&1
cd $WORKDIR/readingdb/
debsign -k8B3731DC readingdb-python*.changes
dput ppa:cal-sdb/smap readingdb-python*.changes

echo $LASTCOMMIT > $BASEDIR/lastversion

