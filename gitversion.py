#!/usr/bin/env python

# This script allocates the canonical 'global git version' numbers. Basically the problem is that
# we need a 'version' number that we generate from all of the git repositories that we are building.
# this is so that even if the official version numbers have not changes, we can generate things like
# package-1.0git34 and 'just' know that our 34 will be bigger than any other packages version number
# even from other repos. This allows apt-get to automatically pull the latest package, even from
# multiple source repos.

# usage
# python gitversion.py <repository> <changeset_id> 
import sys
from pymongo import MongoClient, ASCENDING, DESCENDING
client = MongoClient()

if len(sys.argv) != 4:
    print "Usage: gitversion.py <repository> <changeset_id> <version>"
    sys.exit(1)

if len(sys.argv[2]) != 40:
    print "Please use the 40 character hex changeset id"
    sys.exit(1)
      
lastdoc = list(client.gitversions.ids.find({}).sort("db_id", DESCENDING).limit(1))
if len(lastdoc) == 0:
    next = 0
else:
    next = lastdoc[0]["db_id"]+1
nextdoc = {"db_id":next, "repo":sys.argv[1], "changeset":sys.argv[2], "version":sys.argv[3]}

client.gitversions.ids.save(nextdoc)
print next
sys.exit(0)


