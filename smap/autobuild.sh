#!/usr/bin/env bash









set -ex
# Pull the latest version of the sMAP source, and build a deb of it if the version is higher
# than what we last had


REPO="https://github.com/softwaredefinedbuildings/smap.git"

REPOBRANCH=unitoftime
VERSION=2.2
BASEDIR=/rust/buildd/smap
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
git clone $REPO smap 2>&1

cd smap
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
debsign -k8B3731DC smap_*.changes
cd $WORKDIR/smap/python/dist
dput ppa:cal-sdb/smap smap*.changes

echo $LASTCOMMIT > $BASEDIR/lastversion

