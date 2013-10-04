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
from pymongo import MongoClient
client = MongoClient()

if len(sys.argv) != 3:
    print "Usage: gitversion.py <repository> <changeset_id>"
    sys.exit(1)

if len(sys.argv[1]) != 40:
    print "Please use the 40 character hex changeset id"
    sys.exit(1)
      
next = client.gitversions.ids.find_one({"db_id":-1})["db_id"] + 1
if next is None:
    next = 0
nextdoc = {"db_id":next, "repo":sys.argv[0], "changeset":sys.argv[1]}

client.gitversions.ids.save(nextdoc)
print next
sys.exit(0)
