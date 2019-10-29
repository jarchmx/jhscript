#!/bin/sh

usage()
{
    echo "Usage:"
    echo "  $0 img_file type[sha256/sha384] pri_key_file"
    exit 1  
}
[ $# -ne 3 ] && usage

img=$1
type=$2
key=$3

[ ! -f $img ] && echo "$img not exist" && usage 
[ ! -f $key ] && echo "$key not exist" && usage 
[[ $type != "sha256" && $type != "sha384" ]] && usage

sign_opt="-pkeyopt digest:$type -pkeyopt rsa_padding_mode:pkcs1"

cp $img $img.nonsecure
openssl dgst -$type -binary $img.nonsecure > $img.$type
openssl pkeyutl -sign -in $img.$type -inkey $key -out $img.sig $sign_opt

dd if=/dev/zero of=$img.sig.padded bs=2048 count=1
dd if=$img.sig of=$img.sig.padded conv=notrunc
cat $img.nonsecure $img.sig.padded > $img.secure

echo "Using the below command to verify"
echo "openssl pkeyutl -verify  -in $img.$type  -sigfile $img.sig  -pubin -inkey $key.pub $sign_opt"
echo "openssl pkeyutl -verify  -in $img.$type  -sigfile $img.sig -inkey $key $sign_opt"


