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
        jobId="unknown";
        userid="unknown";
        xml="unknown";
        results="aborted";
        #The variable below gets passed in
        #CLEANFile="jobid-seq-number-CLEAN"
        x=split(CLEANFile,a,"-");
        jobId=a[1];
        seq=a[2];
        jobId=jobId"-"seq;
}

/Connect:.*/ {
        #Capture what device this was
        x=split($0,a," ");
        UUT=a[2];
}

/Error.*/ {
        abortStr=abortStr " " $0;
}

/Failed.*:/ {
        abortStr=abortStr " " $0;
}

/error.*/ {
        abortStr=abortStr " " $0;
}

/failed.*/ {
        abortStr=abortStr " " $0;
}

# This is the end so print results
END {
        if (result != "error") {
                printf("%s;%s;%s;%s;%s;%s\n",userid,earmsId,UUT,xml,result,abortStr);
        }
}

