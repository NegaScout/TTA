# TTA
Testing tool for assignments with known input and output.

Usage: ./test.sh ([OPTION] [ARGS]?)*

       This script looks for all ./datapub/<test_file>.in, pipes them into your binary and then compares them with ./datapub/<test_file>.out.
       Example of using ./test.sh -d -t 5 -r 3 -o "./main" -iR "test0[1-5].*"
       Exit code is number of failed tests. 
       
      -h,               prints help
      -c <COMPILATOR>,  uses specified compilator (default is gcc)
      -s <S_FILES>,     uses specified source files (Use as \"source1.c source2.c\" ..!), default is \"main.c\"
      -F <FLAGS>,       feeds specified flags into compilator args in \"\$COMPILATOR -o \$SOURCE_FILES \$BINARY \$FLAGS\" manner
      -q,               supresses any text outputs
      -o,               target binary AND output binary for COMPILATOR
      -m,               compile with your local Makefile
      -u,               look for update on this script at github
      -d,               prints also the difference in your_output and datapub_output
      -i <TESTS>,       ignore certain tests, where <TESTS> are relative paths in 'datapub' directory, like: (\"test01.in test02.in\")
      -iR <TESTS_R>,    ignore tests in 'datapub' directory with extended regex (grep -w -E <TESTS_R>)  (like \"test1.in\" or \"test0[1-5].*\")
      -r <REPEAT>,      repeat selected tests for <REPEAT> times
      -t <TIMEOUT>,     set timeout for the tests (doesnt inform of timeout, cant get it to work :<)
      
If there is some issue, please let me know using git Issues.
