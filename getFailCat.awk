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
        #printf("jobId,Seq,sTime,eTime,UUT,title,xml,swver,result,errorStr\n");
}

function ltrim(s) { gsub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { gsub(/[ \t\r\n]+$/, "", s); return s }
function trim(s) { return rtrim(ltrim(s)); }

function getISODate(time) {
        n=split(time,t," ");
        y=t[6];
        if (t[2] == "Jan") {m="01";}
        if (t[2] == "Feb") {m="02";}
        if (t[2] == "Mar") {m="03";}
        if (t[2] == "Apr") {m="04";}
        if (t[2] == "May") {m="05";}
        if (t[2] == "Jun") {m="06";}
        if (t[2] == "Jul") {m="07";}
        if (t[2] == "Aug") {m="08";}
        if (t[2] == "Sep") {m="09";}
        if (t[2] == "Oct") {m="10";}
        if (t[2] == "Nov") {m="11";}
        if (t[2] == "Dec") {m="12";}
        d=t[3];
        ts=t[4];
        ISODate="ISODate(\"" y "-" m "-" d "T" ts "Z\")" ;
        #printf("ISODate: %s\n",ISODate);
        return ISODate;
}

/test_suite =.*/ {
        #Capture jobID information along with test case number and platform
        #printf("Found job ID, Seq, Title, plat type\n");
        x=split($0,a,"=");
        x=split(a[2],b,"-");
        jobId=trim(b[1]);
        Seq=b[2];
        x=split(b[4],c,"_");
        title=c[1];
        platType=c[2];
}
/    S\/W version    :/ {
        #Capture the software version
        #printf("Found Software Version\n");
        x=split($0,a,":");
        swver=a[2];
}
/    Start time   :/ {
        #Capture the start time of this test
        #printf("Found Start Time\n");
        x=split($0,a,":");
        sTime=a[2] ":" a[3] ":" a[4];
        #Now that we have a start time, we need to convert this into an ISODate date
        sTime=getISODate(sTime);
}

/    Stop time    :/ {
        #Capture the stop time of this test
        #printf("Found Stop time\n");
        x=split($0,a,":");
        eTime=a[2] ":" a[3] ":" a[4];
        eTime=getISODate(eTime);
}

/Passed.*:/ {
        #Count the number of passed tests
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Passed\n");
                result="passed"
        }
}

/Passx.*:/ {
        #Count the number of passed with exceptions
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Passx\n");
                result="passx"
        }
}

/Failed.*:/ {
        #Count the number of Failed tests
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Failed\n");
                result="failed"
        }
}

/Aborted.*:/ {
        #Count the number of aborted tests
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Aborted\n");
                result="aborted"
        }
}

/Blocked.*:/ {
        #Count the number of blocked tests
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Blocked\n");
                result="blocked"
        }
}

/Skipped.*:/ {
        #Count the number of skipped tests
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Skipped\n");
                result="skipped"
        }
}

/Errored.*:/ {
        #Count the number of errored tests
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Errored\n");
                if (result == "aborted") {
                } else {
                        result="error"
                }
        }
}

/Unknown.*:/ {
        #Count the number of unknown errors
        x=split($0,a,":");
        if (a[2] == " 1") {
                #printf("Found Unknown\n");
                result="unknown"
        }
}

/Test arguments.*:/ {
        #Get the test case information
        #printf("Found Test agruments\n");
        # Get UUt info
        x=split($0,a,"name");
        y=split(a[2],b," ");
        UUT=b[1];
        # Get XML file info
        z=split($0,a,"rel-1.0");
        x=split(a[2],b," ");
        xml=b[1];
        gsub(/\//,"",xml);
}

/Error info.*:/ {
        #Get the error details
        if (result == "error" || result == "aborted") {
                #printf("Found Error info\n");
                x=split($0,a,/Error info.*:/);
                getError=1;
                next
        }
}

/\[error-.*\]/ {
        # Build a string of the error information
        #printf("Found [error]\n");
        if (result == "failed" || result == "aborted") {
                errorStr=errorStr " " $0
                next;
        }
}

/\[fail-.*\]/ {
        # Build a string of the error information
        #printf("Found [error]\n");
        if (result == "failed" || result == "aborted") {
                errorStr=errorStr " " $0
                next;
        }
}

/job Devices Used->/ {
        #Record all of the devices used for the test
        x=split($0,a,/->/);
        devices=a[2]
}

#Default print the error lines
{
        # Ugh ATS has a different format for the report file
        # Based on the type of error
        # So if this is an "failed" test get the error information differently
        if (getError == 1) {
                if (numLines < 10) {
                        errorStr=errorStr " " $0;
                        numLines++;
                }
        }
}

# This is the end so print results
END {
        if ((result == "failed") || (result == "aborted") || (result == "error") || (result == "passed")) {
                errorStr=trim(errorStr)
                gsub(/"/,"'",errorStr);
                gsub(/\//,"//",errorStr);
                gsub(/\\/,"\\\\",errorStr);
                gsub(/\r/,"",errorStr);
                printf(",\"sTime\": %s,\"eTime\": %s, \"devices\": \"%s\",",sTime,eTime,devices);
                printf("\"UUT\": \"%s\",\"Title\": \"%s\",\"xml\": \"%s\",\"swver\": \"%s\",\"result\":\"%s\",",UUT,title,xml,swver,result);
                printf("\"errorStr\": \"%s\"",errorStr);
        }
}

