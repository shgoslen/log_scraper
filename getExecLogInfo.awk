# This awk program parses the Exec log for a job looking for a few things
# such as the devices used in the job

BEGIN { 
        result="none";
        getError=0;
        numLines=0;
        printHeader=1;
        #printf("jobId,Seq,sTime,eTime,UUT,title,xml,swver,result,errorStr\n");
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

/set: JOB_DEVICES_USED.*/ {
        s = split($0, d, "=");
        r = d[2];
        u = split(r, z, " ");
        devicesUsed = z[1];
}

/set: JOB_TESTBED_USED.*/ {
        s = split($0, d, "=");
        r = d[2];
        u = split(r, z, " ");
        testbedUsed = z[1];
}

/set: JOBG_NUM_JOBS_IN_REQUEST.*/ {
        s = split($0, d, "=");
        r = d[2];
        u = split(r, z, " ");
        numJobsInRequest  = z[1];
}

/set: TGEN_VERSION.*/ {
        s = split($0, d, "=");
        r = d[2];
        u = split(r, z, " ");
        ixiaVersion = z[1];
        gsub(/"/,"",tgVersion)
}

/rerun     .*/ {
        s = split($0, d, "=");
        r = d[2];
        u = split(r, z, " ");
        rerun = z[1];
}



# This is the end so print results
END {
        printf(",\"devicesUsed\": %s,\"testbed\": %s",devicesUsed,testbedUsed);
        printf(",\"jobsInRequest\": %s,\"tgenVersion\": \"%s\"",numJobsInRequest,tgVersion);
        printf(",\"rerun\": %s",rerun);
        
}

