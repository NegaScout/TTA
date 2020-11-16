# TTA
Testing tool for assignments with known input and output.

Usage: ./test.sh ([OPTION] [ARGS]?)*

       This script looks for all <test_file>.in, pipes them into your binary and then compares them with <test_file>.out.
       Example of using ./test.sh -d -t 5 -r 3 -o \"./main\" -iR \"test0[1-5].*\"
       Exit code is number of failed tests. 
       
      -h,            prints help
      -q,            supresses any text outputs
      -o,            target binary
      -m,            compile with your local Makefile
      -u,            look for update on this script at github
      -d,            prints also the difference in your_output and datapub_output
      -i <TESTS>,    ignore certain tests, where <TESTS> are relative paths in 'datapub' directory, like: (\"test01.in test02.in\")
      -iR <TESTS_R>, ignore tests in 'datapub' directory with extended regex (grep -w -E <TESTS_R>)  (like \"test1.in\" or \"test0[1-5].*\")
      -r <REPEAT>,   repeat selected tests for <REPEAT> times
      -t <TIMEOUT>,  set timeout for the tests
      
If there is some issue, please let me know using git Issues.
