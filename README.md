# TTA
Testing tool for assignments with known input and output.

Usage: ./test.sh ([OPTION] [ARGS]?)*

      -h,            prints help
      
      -u,            pulls newest version from origin
      
      -s,            specify source files (main.c is default)
      
      -L,            choose language (just "C" for now)
      
      -d,            prints also difference in your_output and datapub_output
      
      -i <TESTS>,    ignore certain tests, where <TESTS> are relative paths in datapub directory ("test01.in test02.in")
      
      -iR <TESTS_R>, ignore tests in datapub directory with extended regex <TESTS_R> (like "test1.\.in" or "test0[1-5].\.in")
      
      -r <REPEAT>,   repeat tests (useful for not innitialized variables errors)
      
      -t <TIMEOUT>,  set timeout for tests
      
If there is some issue, please let me know using git Issues.
