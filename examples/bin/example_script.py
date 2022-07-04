#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
Stupid script to demonstrate how to write Python command line scripts.
This script will overwrite given files with the string "FOOBAR"!
'''

import logging
from argparse import ArgumentParser

def main(args):
    logging.basicConfig(level=args.loglevel or logging.INFO)

    logging.debug('Will write to following files: %s', ', '.join(args.file))

    for fname in args.file:
        if args.dry_run:
            logging.info('** DRY-RUN ** would overwrite %s', fname)
        else:
            logging.info('Trying to overwrite %s..', fname)
            try:
                with open(fname, 'w') as fd:
                    fd.write('FOOBAR')
            except:
                logging.exception('Failed to write to %s', fname)


if __name__ == '__main__':
    parser = ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-v', '--verbose', help='Verbose (debug) logging', action='store_const', const=logging.DEBUG,
            dest='loglevel')
    group.add_argument('-q', '--quiet', help='Silent mode, only log warnings', action='store_const',
            const=logging.WARN, dest='loglevel')
    parser.add_argument('--dry-run', help='Noop, do not write anything', action='store_true')
    parser.add_argument('file', nargs='+', help='Files to overwrite with FOOBAR')
    args = parser.parse_args()
    main(args)

