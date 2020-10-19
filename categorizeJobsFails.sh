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
basedir3="/auto/performance/ats/ats5.3.0_C3_svn_production/ats_easy/archive"
cleanDir="/auto/jobs/jobs/testlog-new"
runDir="/auto/performance/tools/failures"
logFile=${runDir}/logs/log.txt


getDateTime()
{
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
                7) M="Jul" ;;
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
    #   m="0"$m
    #fi
    #echo "Year: $y, SY: $sy, Month: $m, Month: $M, Day: $d"
   dir=$sy-$m
   ymd=$y$M$d
   echo "YMD: $ymd, dir: $dir" >> $logFile
}

writeJobID()
{
    echo "writeJobID:" >> $logFile
    e=`echo $1 | cut -d "/" -f10 | cut -d"-" -f1-2`
    eID=`echo $e | cut -d"-" -f1`
    eSeq=`echo $e | cut -d"-" -f2`
    echo "jobD: $eID, Seq: $eSeq" >> $logFile
    echo -n "{\"jobId\":\"$eID\",\"Seq\":\"$eSeq\"" >> $outFile
}

writeJsonEnd()
{
   echo "}" >> $outFile
}

processLogFile()
{
        echo "processLogFile:" >> $logFile
        # Now that we have found a file, unzip the directory into a tempdir
        rm -rf /tmp/work
        mkdir /tmp/jobwork
        cp $1 /tmp/jobwork
        zf=`ls /tmp/jobwork/*`
        echo "zf: $zf"
        unzip $zf -d /tmp/jobwork > /dev/null
        rslt=$?
        #echo "rslt: $rslt"
        if [ $rslt -eq 0 ]; then
                reportfile=`ls /tmp/jobwork/*.report`
                echo "reportfile: $reportfile" >> $logFile
                # Process the report file with awk
                gawk -f /auto/performance/tools/failures/getFailCat.awk $reportfile >> $outFile
                # Now we need to clean up the tmp dir
        else
                echo "Result: $rslt, Can not process $zf" >> $logFile
        fi
}

processCleanFile()
{
        echo "processCleanFile:" >> $logFile
        e=`echo $1 | cut -d "/" -f10 | cut -d"-" -f1-2`
        #echo $e
        part1=`echo $e | cut -c1-5`
        #echo "part1: $part1"
        part2=`echo $e | cut -c6-7`
        #echo "part2: $part2"
        part3=`echo $e | cut -c8-9`
        #echo "part3: $part3"
        part4=`echo $e | cut -d"-" -f2`
        #echo "part4: $part4"
        oddDir="$part1/$part2/$part3-$part4"
        #echo "oddDir: $oddDir"
        fullCleanDir="$cleanDir/$oddDir/clean"
        echo "fullCleanDir: $fullCleanDir" >> $logFile
        #Now copy the clean log to a temp dir
        rm -rf /tmp/jobwork
        mkdir /tmp/jobwork
        cp $fullCleanDir/Clean_log.gz /tmp/jobwork
        gunzip /tmp/jobwork/Clean_log.gz
        rslt=$?
        if [ $rslt -eq 0 ]; then
            gawk -f /auto/performance/tools/failures/getCleanTimes.awk /tmp/cleanwork/Clean_log >> $outFile
        else
            echo "Can not process $fullCleanDir" >> $logFile
        fi
}

processOrphanCleanList()
{
        echo "!*!*!*!*!*!*!*!*!*!*!*!*!*!" >> $logFile
        echo "processOrphanCleanList:" >> $logFile
        for cd in $orphanDirs; do
                part1=`echo $cd | cut -c1-5`
                echo "part1: $part1" >> $logFile
                part2=`echo $cd | cut -c6-7`
                echo "part2: $part2" >> $logFile
                part3=`echo $cd | cut -c8-9`
                echo "part3: $part3" >> $logFile
                part4=`echo $cd | cut -d"-" -f2`
                echo "part4: $part4" >> $logFile
                oddDir="$part1/$part2/$part3-$part4"
                echo "EARMS STUFF: $part1$part2$part3-$part4/junk" >> $logFile
                echo -n "{\"jobId\":\"$part1$part2$part3\",\"Seq\":\"$part4\"" >> $outFile
                #writeEarmsID "/a/a/a/a/a/a/a/a/$part1$part2$part3-$part4/junk"
                echo "oddDir: $oddDir" >> $logFile
                fullCleanDir="$cleanDir/$oddDir/clean"
                echo "fullCleanDir: $fullCleanDir" >> $logFile
                #Now copy the clean log to a temp dir
                rm -rf /tmp/jobwork
                mkdir /tmp/jobwork
                cp $fullCleanDir/Clean_log.gz /tmp/jobwork
                gunzip /tmp/jobwork/Clean_log.gz
                rslt=$?
                if [ $rslt -eq 0 ]; then
                    gawk -f /auto/performance/tools/failures/getCleanTimes.awk /tmp/cleanwork/Clean_log >> $outFile
                else
                    echo "Can not process $fullCleanDir" >> $logFile
                fi
                writeJsonEnd
        done
}


Contains() {
#See if $2 is in $1
    #echo "1: $1"
    #echo "2: $2"
    #[[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]] && return 0 || return 1
    [[ $1 =~ $2 ]] && return 0 || return 1
}

createOrphanCleanList()
{
echo "createOrphanCleanList:" >> $logFile
#The input is the list of log files to process today
#For each log file, pull out only the job ID number as this should be
#enough to find all of the clean files for each sequence number in that set of jobs
#Then see if we can find the clean files for each sequence number
#Then see if the sequence number matches the log files if not then its an orphan so we need
#to add this jobid and seq number to a list for later processing
eIDs=""
eIDsSeq=""
orphanDirs=""

for f in $fls; do
        e=`echo $f | cut -d "/" -f10 | cut -d"-" -f1-2`
        eID=`echo $e | cut -d"-" -f1`
        #echo $e
        eSeq=`echo $e | cut -d"-" -f2`
        #add the job ID to the job ID list, and have a separate list for both job IDS and seqs
        eIDs="$eIDs$eID\n"
        eIDsSeq="$eIDsSeq $e"
done
echo -e "eIDS:$eIDs" >> $logFile
echo "eIDsSeq:$eIDsSeq" >> $logFile
eIDs=`echo -e $eIDs | sort -n -u -`
echo "unique eIDs: $eIDs" >> $logFile
#Now that we have a list of these for each job ID see if we can find all of its clean files
for eID in $eIDs; do
        part1=`echo $eID | cut -c1-5`
        #echo "part1: $part1"
        part2=`echo $eID | cut -c6-7`
        #echo "part2: $part2"
        part3=`echo $eID | cut -c8-9`
        #echo "part3: $part3"
        #Create a list of the directories 
        cleanDirs=`ls -d $cleanDir/$part1/$part2/$part3*`
        echo $cleanDirs >> $logFile
        #Now see if the job id and seq number are in the list of eIDsSeq
        for cd in $cleanDirs; do
                eidseq=`echo $cd | cut -d"/" -f6-8 | tr -d "/"` 
                #echo "eidseq: $eidseq"
                rc=$(Contains $eIDsSeq $eidseq)
                if [ "$rc" = 0 ]; then
                        #This is not an orphan
                        z=""
                else
                        #This is an ophan so add to list
                        orphanDirs="$ophanDirs $eidseq"
                fi
        done
done
echo "orphanDirs: $orphanDirs" >> $logFile
}

processExecLog()
{
echo "processExecLog:" >> $logFile
#The file "lives" here:
#/auto/jobs/testlog-new/50100/88/24-1/job/501008824-1-1182177.execlog.gz 
#cleanDir="/auto/jobdata-9a/testlog-new"
        e=`echo $1 | cut -d "/" -f10 | cut -d"-" -f1-2`
        #echo $e
        part1=`echo $e | cut -c1-5`
        #echo "part1: $part1"
        part2=`echo $e | cut -c6-7`
        #echo "part2: $part2"
        part3=`echo $e | cut -c8-9`
        #echo "part3: $part3"
        part4=`echo $e | cut -d"-" -f2`
        #echo "part4: $part4"
        oddDir="$part1/$part2/$part3-$part4"
        #echo "oddDir: $oddDir"
        fulljobDir="$cleanDir/$oddDir/job"
        echo "fulljobDir: $fulljobDir" >> $logFile
        #Now copy the clean log to a temp dir
        rm -rf /tmp/jobwork
        mkdir /tmp/jobwork
        cp $fulljobDir/*.execlog.gz /tmp/jobwork/execlog.gz
        gunzip /tmp/jobwork/execlog.gz
        rslt=$?
        if [ $rslt -eq 0 ]; then
            gawk -f /auto/performance/tools/failures/getExecLogInfo.awk /tmp/cleanwork/execlog >> $outFile
        else
            echo "Can not process $fullExecDir" >> $logFile
        fi
}


#Create the categorization file
echo "****************************************" >> $logFile
getDateTime
outFile="/auto/performance/tools/failures/csv/jobFailCat_$ymd.json"
touch $outFile

# Now build list of files to process
#files=`find $basedir/$dir | grep $ymd`
#echo "files: $files"
#files2=`find $basedir2/$dir | grep $ymd`
files3=`find $basedir3/$dir | grep $ymd`
#echo "files3: $files3"
fls=`echo $files3`
echo "!!!!!!!!!!!!" >> $logFile
echo "fls: $fls" >> $logFile
echo "!!!!!!!!!!!!" >> $logFile

createOrphanCleanList

# Now loop through all the zip files in the directory, looking for the
# TIMS: Failures message
for f in $fls; do
        # Now that we have found a file, process each result 
        writejobID $f
        processLogFile $f
        processCleanFile $f
        processExecLog $f
        writeJsonEnd
        #processOrphanCleanList 
        #writeJsonEnd 
done
processOrphanCleanList
#Now get this into mongo
#Convert tabs to spaces
sed -e 's/\t/ /g' $outFile > $outFile.txt
mv $outFile.txt $outFile
mongoimport -v --db=test --collection=failures --type=json --file=$outFile >> $logFile

