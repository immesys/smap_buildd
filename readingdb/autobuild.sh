#!/usr/bin/env bash

# Pull the latest version of the sMAP source, and build a deb of it if the version is higher
# than what we last had
REPO="https://github.com/stevedh/readingdb.git"
REPOBRANCH="microseconds"

BASEDIR=/srv/buildd/readingdb
WORKDIR=$BASEDIR/rdb_$(date +"%d.%m.%y_%H_%M")
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
LASTLOG=$(git log -n 1 --format=oneline)

if [ $LASTVER = $LASTCOMMIT ]
then
    echo "Last commit has already been processed"
    exit 1
fi

DBID=$($BASEDIR/../gitversion.py $REPO $LASTCOMMIT)
EC=$?
# Might be more return codes in future
if [ $EC -eq 1 ]
then
    echo "Could not generate a gitversion number"
    exit 1
fi

echo "Using -git$DBID for changeset $CURVER from $REPO"

#Copy in our local changelog
cd $BASEDIR
dch --distribution raring -v 0.6.0-6git$DBID --check-dirname-level 0 "git($REPO): $LASTLOG"
if [ $? -ne 0 ]
then
    echo "DCH failed"
    exit 1
fi

cp $BASEDIR/debian/changelog $WORKDIR/readingdb/debian/changelog
cp $BASEDIR/debian/control $WORKDIR/readingdb/debian/control
cp $BASEDIR/debian/compat $WORKDIR/readingdb/debian/compat

cd $WORKDIR/readingdb


#dpkg-buildpackage -rfakeroot -uc -us -S
#cd ..
#This key is Michael Andersen's software signing key
#debsign -k6E82A804 smap_*.changes
#cd $WORKDIR/smap/python/dist
#dput ppa:mandersen/smap smap*.changes
#echo $CURVER > $BASEDIR/lastversion
#echo "Completed revision $CURVER"
