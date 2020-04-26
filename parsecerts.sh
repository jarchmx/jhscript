#!/bin/sh

usage()
{
    echo "Usage:"
    echo "      $0 signed_file"
    exit 1
}

[ ! -f $1 ] && echo "$1 not exist" && usage

signed_file=$1

#param#1 3 levels certs(6144 bytyes)
parse_3level_cert()
{

    ccfile=$1

    #get Attestation cert
    openssl x509 -inform der -in $ccfile -outform der -out $outdir/at.der
    [ $? -ne 0 ] && echo "openssl error" && exit 1
    #change to pem
    openssl x509 -inform der -in $outdir/at.der -outform pem -out $outdir/at.pem
    [ $? -ne 0 ] && echo "openssl error" && exit 1
    size=`stat -c %s  $outdir/at.der`
    openssl x509 -in $outdir/at.pem -pubkey -noout -inform pem >$outdir/at.pub
    
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
    
    #openssl dgst -sha256 $outdir/rootca.der
    #openssl dgst -sha384 $outdir/rootca.der
    rhash_sha256=`openssl dgst -sha256 ./rootca.der | awk -F'=' '{print $2}' |awk '{print $1}'`
    rhash_sha384=`openssl dgst -sha384 ./rootca.der | awk -F'=' '{print $2}' |awk '{print $1}'`
    echo "root hash of sha256:$rhash_sha256"
    echo "root hash of sha384:$rhash_sha384"
}

signedfile_fullpath=`realpath $signed_file`
signedfile_dir=`dirname $signedfile_fullpath`
signedfile_base=`basename $signedfile_fullpath | awk -F'.' '{print $1}'`

outdir="$signedfile_dir/parse_out/"

rm -rf $outdir
mkdir -p $outdir
cd $outdir

pil-splitter.py $signedfile_fullpath $signedfile_base

sign_seg="$signedfile_base".b01
b01size=$(stat -c %s $sign_seg)
cc_skip=`expr $b01size - 6144`
dd if=$sign_seg of=cc.bin bs=1 skip=$cc_skip
sig_skip=`expr $cc_skip - 104`
dd if=$sign_seg of=sig bs=1 skip=$sig_skip count=103
dd if=$sign_seg of=sign_data bs=1 count=$sig_skip
openssl dgst -sha384 -binary sign_data >hash

parse_3level_cert cc.bin

openssl pkeyutl -verify -in hash -sigfile sig -pubin -inkey at.pub