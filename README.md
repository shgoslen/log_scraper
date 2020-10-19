# log_scraper
This is a set of bash and awk scripts to categorize various errors, failures and other things
It produces a summary of the past 24 hours worth log test logs to try to see if there are
patterns in the errors or failures to help determine the overall health of devices in a testbed
or if a certain test seems to be failing consistently and so needs to be fixed. It can generated
both CSV files for import into XL, or JSON based files that can be imported into a Mongo DB
so that queries can be made to the Mongo DB to further search for patterns that may indicate
other issues with the testbeds
