# This awk program will parse a config file looking for the DEVICES line
# It will count the number of each kind of device and output those results
# Each line from the job cli looks like this:
#<devicename> <state> <usage>
#Where <devicename> looks like a721-1-a
# <state> is either active or deactivated
# <usage> is either Busy or Free
# The output of this script looke like this:
# <devicename>,#active busy,#active free,#deactive busy,#deactive free

BEGIN { 
        result="none";
        getError=0;
        numLines=0;
        printHeader=1;
        errorStr=""
        foundStartTime=0
        foundEndTime=0
}

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s) { return rtrim(ltrim(s)); }

function getISODate(time) {
        time=ltrim(time)
        #printf("time: %s\n",time)
        ISODate="ISODate(\"" time  "Z\")" ;
        #printf("ISODate: %s\n",ISODate);
        return ISODate;
}

/Running easyclean/ {
        if (foundStartTime == 0) {
                foundStartTime=1
                #Capture the start time of this clean
                #printf("Found Start Time\n");
                x=split($0,a,":");
                sTime=a[3] ":" a[4] ":" a[5];
                 #printf("sTIME: %s\n",sTime);
                 #Now that we have a start time, we need to convert this into an ISODate date
                 cleanStartTime=getISODate(sTime);
        }
}


/Clean [pass|fail]/ {
        if (foundEndTime == 0) {
                foundEndTime=1
                #Capture the stop time of this test
                #printf("Found Stop time\n");
                x=split($0,a,":");
                eTime=a[3] ":" a[4] ":" a[5];
                #printf("eTime: %s\n", eTime);
                cleanEndTime=getISODate(eTime);
        }
}

/%easyclean-.-ERROR/ {
        #Add this line to the lines of error
        if (numLines < 10) {
                errorStr=errorStr $0 "+LB+"
                numLines++;
        }
}

/SCRIPT-.-ERROR/ {
        #Add this line to the lines of error
        if (numLines < 10) {
                errorStr=errorStr $0 "+LB+"
                numLines++;
        }
}



# This is the end so print results
END {
        printf(",\"cleanStartTime\": %s,\"cleanEndTime\": %s",cleanStartTime,cleanEndTime);
        printf(",\"cleanError\": \"%s\"",errorStr)
}

