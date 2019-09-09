#!/bin/bash


URL="git://cnshz-er-git01"
resultfile=$PWD/result.log

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -o <old xml, ex: LE.UM.3.3.2-02200-SDX55.xml>
    -n <new xml, ex: LE.UM.3.3.2-02500-SDX55.xml>
    -r <swi repo xml, ex: amss.xml>
    -w <swi main workspace directory>
    -t [target output dir, default outdir if missing.]
EOF
    exit 1
}

check_missing()
{
    [ $# -ne 3 ] && echo "Please run with parater like: check_missing search searchin \"prompt\"" && return 1
    search=$1
    searchin=$2
    prompt=$3
    
    echo -n "$prompt"

    found=0
    count=0
    for s in $search
    do
        let count+=1
        for si in $searchin
        do
            if [ $s == $si ];then
                let found+=1
                break
            fi        
        done
        if [ $found -eq 0 ];then
            echo -n "\n$s not found in list \"$searchin\""
        fi
    done

    if [ $count -eq $found ];then
        echo ".....[OK]"
        return 0
    fi
    return 1
}

while getopts "o::n:r:t:w:" arg
do
    case $arg in
    o)
        oldxml=$OPTARG
        #echo "oldxml: $oldxml"
        [ ! -f $oldxml ] && echo "$oldxml not exist" && usage
        ;;
    n)
        newxml=$OPTARG
        #echo "newxml: $newxml"
        [ ! -f $newxml ] && echo "$newxml not exist" && usage
        ;;
    r)
        repoxml=$OPTARG
        #echo "repoxml: $repoxml"
        [ ! -f $repoxml ] && echo "$repoxml not exist" && usage
        ;;
    t)
        outdir=$OPTARG
        #echo "outdir: $outdir"
        ;;
    w)
        swiwkdir=$OPTARG
        #echo "swi workspace dir: $swiwkdir"
        [ ! -d $swiwkdir/meta-swi ] && echo "$swiwkdir/meta-swi not exist" && usage
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage
        ;;
    esac
done

if [[ -z $oldxml || -z $newxml || -z $repoxml || -z $swiwkdir ]];then
    echo "Miss paramer" && usage 
fi

maindir=$PWD/
[ -z $outdir ] && outdir="$maindir/outdir"
tmpdir=$maindir/tmp/
rm -rf $tmpdir/
rm -rf $outdir/
rm -f $resultfile
mkdir -p $outdir/
mkdir -p $tmpdir

oldmetalst=`cat $oldxml | grep "meta" | grep -oe "<project name=\S*" |awk -F= '{print $2}' | awk -F'"' '{print $2}'`
newmetalst=`cat $newxml | grep "meta" | grep -oe "<project name=\S*" |awk -F= '{print $2}' | awk -F'"' '{print $2}'`

check_missing "$oldmetalst" "$newmetalst" "Check old meta list in new xml"
[ $? -ne 0 ] && echo "list is not same" && exit 1
check_missing "$newmetalst" "$oldmetalst" "Check new meta list in old xml"
[ $? -ne 0 ] && echo "list is not same" && exit 1

for meta in $oldmetalst
do
    METAPATH=`cat $repoxml  | grep "$meta" | grep -oe "<project name=\S*" | awk -F'"' '{print $2}'`
    METAURL="$URL"/$METAPATH
    old_rev=
    new_rev=
    #echo METAURL:$METAURL
    old_rev=`cat $oldxml  | grep "$meta" | grep -oe "revision=\S*" | awk -F'"' '{print $2}'`
    new_rev=`cat $newxml  | grep "$meta" | grep -oe "revision=\S*" | awk -F'"' '{print $2}'`
    if [[ -z $old_rev || -z $new_rev ]];then
        echo "Missing rev, old_rev:$old_rev, new_rev:$new_rev for $meta"
        exit 1
    fi
    git clone $METAURL $tmpdir/$meta &>/dev/null
    if [ $? -ne 0 ];then
        echo "Git clone for $meta fail, please check"
        exit 1
    fi
   
    [ ! -d $tmpdir/$meta/ ] && echo "$tmpdir/$meta/ not exist, please check" && exit 1

    cd $tmpdir/$meta/
    
    mkdir -p $outdir/$meta
    git format-patch $old_rev..$new_rev -o $outdir/$meta &>/dev/null
    if [ $? -ne 0 ];then
        echo "Git formart-patch for $meta fail, please check"
        exit 1
    fi

    git checkout $new_rev &>/dev/null
    if [ $? -ne 0 ];then
        echo "Git checkout for $meta fail, please check"
        exit 1
    fi


    #search every patch file.
    cd $outdir/$meta
    for patchfile in `find . -name '*.patch'` 
    do
        #search every diff file in patch file to check if it should be updated in swiwkdir.
        for diff_file in `cat $patchfile | grep "^diff --git" | awk '{print $4}'`
        do
            diff_file=${diff_file##b/}
            #echo check $diff_file in $patchfile of $meta
            #echo if it is new file
            cat $patchfile | grep -A1 "^diff --git" | grep -A1 "$diff_file"  | grep "new file" &>/dev/null
            if [ $? -eq 0 ];then
                echo -en "$tmpdir/$meta/$diff_file\n" >> $maindir/newfile.txt
                echo -en "$tmpdir/$meta/$diff_file is new file,refer to $outdir/$meta/$patchfile\n" >> $resultfile
                continue
            fi

            #echo if it is deleted file
            cat $patchfile | grep -A1 "^diff --git" | grep -A1 "$diff_file"  | grep "deleted file" &>/dev/null
            if [ $? -eq 0 ];then
                echo -en "$tmpdir/$meta/$diff_file\n" >> $maindir/delfile.txt
                echo -en "$tmpdir/$meta/$diff_file is deleted file,refer to $outdir/$meta/$patchfile\n" >> $resultfile
                continue
            fi

            #is a normal file, should search in swi workspace dir.
            basediff_file=${diff_file##*/}
            FIND=
            for searchdir in `echo $swiwkdir/meta-*`
            do
                FINDTMP=`find $searchdir/ -name "$basediff_file"`
                [ "x$FINDTMP" != "x" ] && FIND="$FINDTMP $FIND"
            done
            
            if [ "x$FIND" != "x" ];then
                echo "-------------------------------------------------------------------------------------------" >>$resultfile
                echo -en "$tmpdir/$meta/$diff_file\n" >>$maindir/updatefile.txt
                echo -en "$tmpdir/$meta/$diff_file updated,refer to $outdir/$meta/$patchfile\n" >> $resultfile
                echo -en "Should update:\n$FIND\n" >> $resultfile
                echo "============================================================================================" >>$resultfile
            fi
        done
    done
    
    cd $maindir
done

printf -v list_start '%.0s-' {1..120}

echo -en "Files list summary, please get the details from $resultfile\n"
echo $list_start
echo -en "\e[1;32mNew file list:\n"
cat $maindir/newfile.txt
echo -en "\e[0m"


echo $list_start
echo -en "\e[1;31mDeleted file list:\n"
cat $maindir/delfile.txt
echo -en "\e[0m"


echo $list_start
echo -en "\e[1;33mUpdate file list:\n" 
cat $maindir/updatefile.txt 
echo -en "\e[0m"

rm -f $maindir/updatefile.txt $maindir/newfile.txt $maindir/delfile.txt

