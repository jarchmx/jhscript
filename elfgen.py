#============================================================================
#
# ELF Generate Scripts
#
# GENERAL DESCRIPTION
#    Secure Boot related scripts to generate elf images:
#    encapsulate the binary images into program segment.
#    multi images encapsulate into different program segments.
#    This script will be used for the following cases:
#    1. Create elf header.
#    2. encapsulated image into program segment.
#
# Copyright: (c) 2019 Sierra Wireless, Inc.
#            All rights reserved
#
#----------------------------------------------------------------------------
#

import argparse
import string
import os
import sys
import stat
import csv
import itertools
import shutil

# ELF Definitions
ELF_HDR_COMMON_SIZE       = 24
ELF32_HDR_SIZE            = 52
ELF32_PHDR_SIZE           = 32
ELFINFO_MAG0_INDEX        = 0
ELFINFO_MAG1_INDEX        = 1
ELFINFO_MAG2_INDEX        = 2
ELFINFO_MAG3_INDEX        = 3
ELFINFO_MAG0              = '\x7f'
ELFINFO_MAG1              = 'E'
ELFINFO_MAG2              = 'L'
ELFINFO_MAG3              = 'F'
ELFINFO_CLASS_INDEX       = 4
ELFINFO_CLASS_32          = '\x01'
ELFINFO_VERSION_INDEX     = 6
ELFINFO_VERSION_CURRENT   = '\x01'
ELF_BLOCK_ALIGN           = 0x1000
ELFINFO_DATA2LSB          = '\x01'
ELFINFO_EXEC_ETYPE        = '\x02\x00'
ELFINFO_ARM_MACHINETYPE   = '\x28\x00'
ELFINFO_VERSION_EV_CURRENT = '\x01\x00\x00\x00'
ELFINFO_SHOFF             = 0x00
ELFINFO_RESERVED          = 0x00

# ELF Program Header Types
NULL_TYPE                 = 0x0
LOAD_TYPE                 = 0x1
DYNAMIC_TYPE              = 0x2
INTERP_TYPE               = 0x3
NOTE_TYPE                 = 0x4
SHLIB_TYPE                = 0x5
PHDR_TYPE                 = 0x6
TLS_TYPE                  = 0x7

# Access Type
MI_PBT_RW_SEGMENT                     = 0x0
MI_PBT_RO_SEGMENT                     = 0x1
MI_PBT_ZI_SEGMENT                     = 0x2
MI_PBT_NOTUSED_SEGMENT                = 0x3
MI_PBT_SHARED_SEGMENT                 = 0x4
MI_PBT_RWE_SEGMENT                    = 0x7
#----------------------------------------------------------------------------
# GLOBAL VARIABLES END
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Converts integer to bytes. If length after conversion
# is smaller than given length of byte string, returned value is right-filled
# with 0x00 bytes. Use Little-endian byte order.
#----------------------------------------------------------------------------
def convert_int_to_byte_string(n, l):
    return b''.join([chr((n >> ((l - i - 1) * 8)) % 256) for i in xrange(l)][::-1])

def OPEN(file_name, mode):
    try:
       fp = open(file_name, mode)
    except IOError:
       raise RuntimeError, "The file could not be opened: " + file_name

    # File open has succeeded with the given mode, return the file object
    return fp
	
#----------------------------------------------------------------------------
# Create default elf image.
#----------------------------------------------------------------------------
def create_elf_image( output_file_name,
                       image_dest,
                       sources,
					  ):

	if (output_file_name is None):
		raise RuntimeError, "Requires a ELF header file"

	# Create a elf image.
	elf_fp = OPEN(output_file_name, 'wb')

	# ELf header
	elf_fp.write(ELFINFO_MAG0)
	elf_fp.write(ELFINFO_MAG1)
	elf_fp.write(ELFINFO_MAG2)
	elf_fp.write(ELFINFO_MAG3)
	elf_fp.write(ELFINFO_CLASS_32)
	elf_fp.write(ELFINFO_DATA2LSB)
	elf_fp.write(ELFINFO_VERSION_CURRENT)
	elf_fp.write(''.rjust(9, chr(ELFINFO_RESERVED)))
	elf_fp.write(ELFINFO_EXEC_ETYPE)
	elf_fp.write(ELFINFO_ARM_MACHINETYPE)
	elf_fp.write(ELFINFO_VERSION_EV_CURRENT)
	elf_fp.write(convert_int_to_byte_string(image_dest, 4))
	elf_fp.write(convert_int_to_byte_string(ELF32_HDR_SIZE, 4))
	elf_fp.write(convert_int_to_byte_string(ELFINFO_SHOFF, 4))
	elf_fp.write(''.rjust(4, chr(ELFINFO_RESERVED)))
	elf_fp.write(convert_int_to_byte_string(ELF32_HDR_SIZE, 2))
	elf_fp.write(convert_int_to_byte_string(ELF32_PHDR_SIZE, 2))
	elf_fp.write(convert_int_to_byte_string(len(sources),2))
	elf_fp.write(''.rjust(6, chr(ELFINFO_RESERVED)))
	
	i = 0
	image_size = 0
	offset = ELF32_HDR_SIZE+ELF32_PHDR_SIZE
	for fname in sources:
		#current image_dest is the dest + size of last image.
		image_dest += image_size
		#current offset is last offset + size
		offset += image_size
		image_size = os.stat(fname).st_size      

		# Program Header
		elf_fp.write(convert_int_to_byte_string(LOAD_TYPE, 4))
		elf_fp.write(convert_int_to_byte_string(offset, 4))
		elf_fp.write(convert_int_to_byte_string(image_dest, 4))
		elf_fp.write(convert_int_to_byte_string(image_dest, 4))
		elf_fp.write(convert_int_to_byte_string(image_size, 4))
		elf_fp.write(convert_int_to_byte_string(image_size, 4))
		elf_fp.write(convert_int_to_byte_string(MI_PBT_RWE_SEGMENT, 4))
		elf_fp.write(convert_int_to_byte_string(ELF_BLOCK_ALIGN, 4))
		
	for fname in sources:		
		try:
			file = open(fname, "rb")
		except IOError:
			raise RuntimeError, "The file could not be opened: " + fname
		
		while True:
			bin_data = file.read(65536)
			if not bin_data:
				break
			elf_fp.write(bin_data)
		file.close()

	elf_fp.close()
	return 0

parser = argparse.ArgumentParser(description='manual to this script')
#The --files paramter --files="image1 image2 image3"
parser.add_argument('--files', type=str, default = None)
parser.add_argument('--baseaddr', type=str, default=None)
parser.add_argument('--outimg', type=str, default='boot.elf')
args = parser.parse_args()
#print args.files
#print eval(args.baseaddr)
#print args.outimg

sources = args.files.split(' ')

try:
   image_dest = eval(args.baseaddr)
# Catch exceptions and do not evaluate
except:
   raise RuntimeError, "Invalid image destination address"


#outbase = os.path.splitext(str(args.outimg))[0]

create_elf_image(args.outimg,image_dest,sources)
