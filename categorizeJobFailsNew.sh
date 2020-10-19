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
basedir="/auto/performance/ats/ats5.2.0_C1_svn_production/ats_easy/archive"
#basedir2="/auto/performance/ats/ats5.3.0_C1_svn_production/ats_easy/archive"
basedir3="/auto/performance/ats/ats5.4.0_C3_svn_production/ats_easy/archive"
dir=`date +%y-%m`
day=`date +%d`
#echo "Day: $day"
day=`expr $day - 1`
if [ $day -lt 10 ]; then
        day="0"$day
fi
ym=`date +%Y%b`
ymd=$ym$day
echo "YMD: $ymd"

#Create the categorization file
outFile="/auto/performance/tools/failures/csv/jobFailAb_$ymd.csv"
#touch $outFile

# Now build list of file to process
files=`find $basedir/$dir | grep $ymd`
#echo "files: $files"
#files2=`find $basedir2/$dir | grep $ymd`
files3=`find $basedir3/$dir | grep $ymd`
#echo "files3: $files3"
fls=`echo $files $files3`
#echo "fls: $fls"


# Now loop through all the zip files in the directory, looking for the
# TIMS: Failures message
for f in $fls; do
        # Now that we have found a file, unzip the directory into a tempdir
        rm -rf /tmp/jobwork
        mkdir /tmp/jobwork
        cp $f /tmp/jobwork
        zf=`ls /tmp/jobwork/*`
        echo "zf: $zf"
        unzip $zf -d /tmp/jobwork > /dev/null
        rslt=$?
        #echo "rslt: $rslt"
        if [ $rslt -eq 0 ]; then
                dr=`ls /tmp/jobwork/`
                reportfile=`ls /tmp/jobwork/*.report`
                echo "reportfile: $reportfile"
                if [ $reportfile == "" ]; then
                        #Since the report file is missing, this must be an abort so look at the clean files
                        echo "Directory: $dr"
                        cleanFiles=`ls /tmp/work/Clean_console_log*`
                        CLEAN=`ls /tmp/jobwork/*CLEAN*`
                        echo "CLEAN: $CLEAN"
                        for c in cleanFiles; do
                                #echo "Clean file: $c"
                                awk -v CLEANFile="$CLEAN" -f /auto/performance/tools/failures/getAbort.awk $c >> $outFile
                        done
                else
                        continue
                fi
                #echo "reportfile: $reportfile"
                # Process the report file with awk
                awk -f /users/sgoslen/JOBS/jobFails/getFailCat.awk $reportfile >> $outFile
                # Now we need to clean up the tmp dir
        else
                echo "Result: $rslt, Can't process $zf"
        fi
done

