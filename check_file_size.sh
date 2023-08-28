#!/bin/sh
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2023, Javier Polo Cozar"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

LS=`which ls`
CUT=`which cut`
# we need bc installed to do unit conversion
BC=`which bc`

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to monitor a local system file size (Bytes,Kbytes,MBytes, GBytes)"
    echo ""
    echo "$PROGNAME  -f filename [-u/--unit <unit type>] [-w/--warning <warning limit size>] [-c/--critical <critical limit size>]"
    echo ""
    echo "Examples: $PROGNAME -f /etc/hosts.allow"
    echo " $PROGNAME -f /etc/hosts.allow -w 10 -c 15 -u Mb"
    echo ""
    echo "Options:"
    echo " -f filename: name of file to check its size (full path)"
    echo " --version: program version"
    echo "  --help: displays this help message"
    echo "  --warning|-w <warning limit (same size unit)>): Sets a warning level for size. Default is: off"
    echo "  --critical|-c <critical limit (same size unit)>): Sets a critical level for size. Default is: off"
    echo "  --unit|-u [b|B|Kb|KB|Mb|MB|Gb|GB]: Sets output in specific format: Kb, Mb or Gb. Default is: b (Bytes)"
    echo ""

    exit $ST_UK
}

if test -z "$1" 
then
	echo "No command-line arguments."
	print_help
	exit $ST_UK 

else

# By default, output is given in Bytes
unit=b

while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $ST_UK
            ;;
        --version)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
     --unit|-u)
	    unit=$2
	    shift
	    ;;
        --warning|-w)
            warn=$2
            shift
            ;;
        --critical|-c)
            crit=$2
            shift
            ;;
     -f)
        filename=$2
        shift
        ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
    esac
    shift
done
fi

get_file_size(){

if [ -f $filename ]; then
sizeB=`$LS -l $filename|cut -d" " -f5`
else
echo "No such file $filename"
exit $ST_UK

fi
}

do_unit_conversion() {
case "$unit" in
    b|B)
    size=$sizeB
    ;;
    Kb|KB)
    size=$(echo "scale=2;$sizeB / 1024"|$BC)
    ;;
    Mb|MB)
    size=$(echo "scale=2;$sizeB / 1048576"|$BC)
    ;;
    Gb|GB)
    size=$(echo "scale=2;$sizeB /1073741824"|$BC)
    ;;
    *)    
    echo "Unkown unit type: $unit"
        print_help
        exit $ST_UK
        ;;
    
esac
}

do_output() {
output="Filesize: $size $unit"
}

do_perfdata() {
	perfdata="Filesize=$size$unit;$warn;$crit;"
}

val_wcdiff() {
    if [ ${warn} -gt ${crit} ]
    then
        wcdiff=1
    fi
}


if [ "$BC" = "" ]
then
        echo "\nbc application must be previously installed. Try to execute next command if you are in a debian based linux:\n"
        echo "$ sudo apt-get install bc\n"
        echo "\nIf you are in a red hat based linux, you could try with:\n"
        echo "$ sudo yum install bc\n"
        exit $ST_UK
fi

if [ -n "$warn" -a -n "$crit" ]
then
    val_wcdiff
    if [ "$wcdiff" = 1 ]
    then
		echo "Please adjust your warning/critical thresholds. "
		echo "The warning must be lower than the critical level!"
        exit $ST_UK
    fi
fi

 do_final_output() {
 if [ -n "$warn" ] && [ -n "$crit" ]; then

    # We need awk to compare float number   
    if awk "BEGIN {exit !(($size >= $warn)&&($size<$crit))}"
     then
 		echo "WARNING - ${output} | ${perfdata}"
         exit $ST_WR

    elif awk "BEGIN {exit !($size >= $crit)}" 
    then 
 		echo "CRITICAL - ${output} | ${perfdata}"
         exit $ST_CR
     else
 		echo "OK - ${output} | ${perfdata}"
         exit $ST_OK
     fi
 else
       if [ -n "$warn" ]; then
   if awk "BEGIN {exit !($size >= $warn)}"
        then
		echo "WARNING - ${output} | ${perfdata}"
		exit $ST_WR
	else 
		echo "OK - ${output}|${perfdata}"
		exit $ST_OK
	fi
      elif [ -n "$crit" ]; then
   if awk "BEGIN {exit !($size >= $crit)}" 
    then
		echo "CRITICAL - ${output} |${perfdata}"
		exit $ST_CR
	else
	echo "OK - ${output} | ${perfdata}"
    	exit $ST_OK
	fi
     else
	echo "OK - ${output}|${perfdata}"
	exit $ST_OK
     fi
	
fi
}

get_file_size
do_unit_conversion
do_output
do_perfdata
do_final_output



