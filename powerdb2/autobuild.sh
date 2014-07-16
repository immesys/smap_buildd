#!/usr/bin/env bash





# Pull the latest version of the sMAP powerdb2 source, and build a deb of it if the version is higher
# than what we last had

set -e





REPO="https://github.com/softwaredefinedbuildings/powerdb2.git"

REPOBRANCH=master
VERSION=2.2
BASEDIR=/rust/buildd/powerdb2
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
git clone $REPO powerdb2 2>&1

cd powerdb2
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

cp $BASEDIR/debian/changelog $WORKDIR/powerdb2/debian/changelog
cp $BASEDIR/debian/compat $WORKDIR/powerdb2/debian/compat
cp $BASEDIR/debian/control $WORKDIR/powerdb2/debian/control

cd $WORKDIR/powerdb2
sed -i "s/^\\(VERSION=\\).*\$/\1$VERSION/g" Makefile
make dist
make builddeb

cd $WORKDIR/powerdb2/dist/

#This key is Michael Andersen's software signing key
debsign -k8B3731DC powerdb2*.changes
dput ppa:cal-sdb/smap powerdb2*.changes

echo $LASTCOMMIT > $BASEDIR/lastversion

