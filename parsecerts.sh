#!/bin/sh

usage()
{
    echo "Usage:"
    echo "      $0 certs.bin"
    exit 1
}


[ $# -ne 1 ] && usage

[ ! -f $1 ] && echo "$1 not exist" && usage

ccfile=$1

outdir=`dirname $ccfile`

#get Attestation cert
openssl x509 -inform der -in $ccfile -outform der -out $outdir/at.der
[ $? -ne 0 ] && echo "openssl error" && exit 1
#change to pem
openssl x509 -inform der -in $outdir/at.der -outform pem -out $outdir/at.pem
[ $? -ne 0 ] && echo "openssl error" && exit 1
size=`stat -c %s  $outdir/at.der`

#get attestation CA cert.
dd if=$ccfile of=$outdir/atca.bin bs=1 skip=$size
openssl x509 -inform der -in $outdir/atca.bin -outform der -out $outdir/atca.der
[ $? -ne 0 ] && echo "openssl error" && exit 1
#change to pem
openssl x509 -inform der -in $outdir/atca.der -outform pem -out $outdir/atca.pem
[ $? -ne 0 ] && echo "openssl error" && exit 1
size=`stat -c %s $outdir/atca.der`

#get root CA cert.
dd if=$outdir/atca.bin of=$outdir/rootca.bin bs=1 skip=$size
openssl x509 -inform der -in $outdir/rootca.bin -outform der -out $outdir/rootca.der
[ $? -ne 0 ] && echo "openssl error" && exit 1
#change to pem
openssl x509 -inform der -in $outdir/rootca.der -outform pem -out $outdir/rootca.pem
[ $? -ne 0 ] && echo "openssl error" && exit 1
size=`stat -c %s $outdir/rootca.der`

#get pad.
dd if=$outdir/rootca.bin of=$outdir/pad.bin bs=1 skip=$size

openssl dgst -sha256 $outdir/rootca.der
openssl dgst -sha384 $outdir/rootca.der
