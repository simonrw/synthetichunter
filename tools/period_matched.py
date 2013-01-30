#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
Prints if an object has had its period matched or not

Usage:
    period_matched.py [options] <id>

Options:
    -h, --help      Show this help
    --host <host>   Connect to host [default: localhost]
    --port <port>   Connect with port [default: 27017]
'''

from docopt import docopt
from bson.objectid import ObjectId
import pymongo

def main(args):
    with pymongo.Connection(host=args['--host'], port=int(args['--port'])) as conn:
        objects = conn.hunter.objects

        result = objects.find_one({ "_id": ObjectId(args['<id>']) },
                { "object_type": True })
        if result:
            if result['object_type'] == 'synthetic':
                print 'Matched object'
            else:
                print 'Mismatch'
        else:
            print "No object detected with id [{0}]".format(args['<id>'])

if __name__ == '__main__':
    main(docopt(__doc__))
