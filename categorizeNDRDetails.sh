#!/usr/bin/sh
# This will search a directory of zip files for any job faillures
# It will attempt to categorize job aborts, errors and fails
# The idea bein to show different kinds of failures and get a frequency count
# of each type of failure.
#
# May need an awk script to process each results file
# The awk script would look for and capture the following:
# Job submitter : get the full user id
# Test arguments : Possibly capture the whole line, but really just need UUT info and xml file
# Error info :  capture the first 100 bytes of this data
# The awk scipt will append to a file that is based on date the following information
# userid; UUT; xml file; abort|error|fail; error info
#
# It is expected that this will be run once a day in a cron job
#
# First get today's date so that we can look at the correct logs directory
# Actually we look at the previous day's directory
#basedir="/auto/performance/ats/ats5.2.0_C1_svn_production/ats_easy/archive"
#basedir2="/auto/performance/ats/ats5.3.0_C1_svn_production/ats_easy/archive"
basedir3="/auto/performance/ats/ats5.4.0_C3_svn_production/ats_easy/archive"
m=`date +%m`
y=`date +%Y`
d=`date +%e`
M=`date +%b`
sy=`date +%y`
#echo "Year: $y, SY: $sy, Month: $m, Month: $M, Day: $d"
if [ $d == "1" ]; then
        #So this is the first day of the month, but we need yesterday's logs
        #Do some funky date calculations
        case $m in
                01) d=31 ;;
                02) d=31 ;;
                03) d=28 ;;
                04) d=31 ;;
                05) d=30 ;;
                06) d=30 ;;
                07) d=30 ;;
                08) d=31 ;;
                09) d=31 ;;
                10) d=30 ;;
                11) d=31 ;;
                12) d=30 ;;
        esac
        m=`expr $m - 1`
        if [ $m -eq 0 ]; then
                m=12
        fi
        case $m in 
                1) M="Jan" ;;
                2) M="Feb" ;;
                3) M="Mar" ;;
                4) M="Apr" ;;
                5) M="May" ;;
                6) M="Jun" ;;
                7) M="July" ;;
                8) M="Aug" ;;
                9) M="Sept" ;;
                10) M="Oct" ;;
                11) M="Nov" ;;
                12) M="Dec" ;;
        esac
else
        d=`expr $d - 1`
fi
if [ $d -lt 10 ]; then
        d="0"$d
fi
#if [ $m -lt 10 ]; then
#       m="0"$m
#fi
#echo "Year: $y, SY: $sy, Month: $m, Month: $M, Day: $d"
dir=$sy-$m
ymd=$y$M$d
#echo "YMD: $ymd, dir: $dir"

#Create the categorization file
outFile="/auto/performance/tools/failures/jobFailCat_$ymd.csv"
#touch $outFile

# Now build list of files to process
#files=`find $basedir/$dir | grep $ymd`
#echo "files: $files"
#files2=`find $basedir2/$dir | grep $ymd`
files3=`find $basedir3/$dir | grep $ymd`
#echo "files3: $files3"
fls=`echo $files3`
#echo "fls: $fls"


# Now loop through all the zip files in the directory, looking for the
# TIMS: Failures message
for f in $fls; do
        # Now that we have found a file, unzip the directory into a tempdir
        rm -rf /tmp/jobwork
        mkdir /tmp/jobwork
        cp $f /tmp/jobwork
        zf=`ls /tmp/jobwork/*`
        #echo "zf: $zf"
        unzip $zf -d /tmp/jobwork > /dev/null
        rslt=$?
        #echo "rslt: $rslt"
        if [ $rslt -eq 0 ]; then
                reportfile=`ls /tmp/jobwork/*.report`
                #echo "reportfile: $reportfile"
                # Process the report file with awk
                outFile="/auto/performance/tools/failures/NDRDETAIL/$zf_$ymd.txt"
                awk -f /auto/performance/tools/failures/getNDRDetail.awk $reportfile >> $outFile
                # Now we need to clean up the tmp dir
        else
                echo "Result: $rslt, Can't process $zf"
        fi
done

