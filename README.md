# TTA
Testing tool for assignments with known input and output.

Usage: ./test.sh ([OPTION] [ARGS]?)*

      -h,            prints help
      
      -s,            specify source files (main.c is default)
      
      -L,            choose language (just "C" for now)
      
      -d,            prints also difference in your_output datapub_output
      
      -i <TESTS>,    ignore certain tests, where <TESTS> are relative paths in datapub dir
      
      -iR <TESTS_R>, ignore tests in datapub dir with regex <TESTS_R>
      
      -r <REPEAT>,   repeat tests (useful for not innitialized variables errors)
      
      -t <TIMEOUT>,  set timeout for tests
