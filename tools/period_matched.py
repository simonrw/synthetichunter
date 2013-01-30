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
import sys
from prettytable import PrettyTable
import pymongo

def main(args):
    with pymongo.Connection(host=args['--host'], port=int(args['--port'])) as conn:
        objects = conn.hunter.objects

        _id = ObjectId(args['<id>'])

        result = objects.find_one({ "_id": _id },
                { "object_type": True, 'object_info': True, })

        if result:
            info = result['object_info']
            input_period = info['input']['period']
            orion_period = info['orion']['period']
            mcmc_period = info['mcmc']['period']

            pt = PrettyTable(['Object type', 'Input', 'Orion', 'MCMC'])

            row = [
                    'Matched' if result['object_type'] == 'synthetic' else 'Mismatch',
                    input_period, orion_period, mcmc_period
                    ]

            pt.add_row(row)

            print pt
        else:
            print "No object detected with id [{0}]".format(args['<id>'])

if __name__ == '__main__':
    main(docopt(__doc__))
