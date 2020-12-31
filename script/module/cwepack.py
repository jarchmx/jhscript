#!/usr/bin/env python

import argparse
import string
import os
import sys
import cwe_tools

#outbase = os.path.splitext(str(args.outimg))[0]
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='manual to this script')
    #The --files paramter --files="image1 image2 image3"
    parser.add_argument('--file', type=str, default = None)
    parser.add_argument('--imagetype', type=str, default='SECE')
    parser.add_argument('--outfile', type=str, default='sec.cwe')
    args = parser.parse_args()
    #print args.file
    #print args.outimg
    cwe_tools.generate_cwe(args.outfile, args.file, args.imagetype)
