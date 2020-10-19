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
}

/CLI Arguments.*/ {
        #Capture jobID information
        #printf("Found CLI Arguments\n");
        x=split($0,a,"Job/");
        y=split(a[2],b,"-");
        jobId=b[1]"-"b[2];
}

/Job submitter.*:/ {
        #printf("Found Job submitter\n");
        #Get the job submitter information
        x=split($0,a,":");
        userid=a[2]
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
                result="abort"
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
                result="error"
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
        xml=a[2];
}

/.*fw_get_platform_info: Platform:.*/ {
        #Get the platform type:
        x=split($0,a,"Platform:");
        plat=a[2];
}

/.*fw_script: s\/w version:.*/ {
        #Get the software version information
        x=split($0,a,"version:");
        z=split(a[2],b," ");
        swv=b[2];
}


/.*fw_tgen_find_ndr/ {
        #In this case we are looking for the NDR Iteration Details
        printf("%s\n",$0);
}

/.*fw_tgen_is_ndr_met/ {
        #In this case we are looking for the NDR Iteration Details
        printf("%s\n",$0);
}



#Default print the error lines
{
        # Ugh ATS has a different format for the report file
        # Based on the type of error
        # So if this is an "failed" test get the error information differently
        if (getError == 1) {
                if (printHeader == 1) {
                        printf("%s;%s;%s;%s;%s;",userid,jobId,UUT,xml,result);
                        printHeader=0;
                }
                printf("%s",$0);
                numLines++;
                if (numLines == 10) {
                        numLines=0;
                        getError=0;
                        printf("\n");
                } 
        }
}

# This is the end so print results
END {
        if (result != "error") {
                printf("%s;%s;%s;%s;%s;%s;%s;%s\n",userid,jobId,UUT,plat,swv,xml,result,errorStr);
        }
}

