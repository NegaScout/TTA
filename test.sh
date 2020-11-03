#!/bin/bash

#Change this to suit your source codes! OR USE -s <source_files>
SOURCE_FILES="main.c" 

TIMEOUT=0 #for timeout... use with -t <TIMEOUT>
RETURN=0
REPEAT=1 #for repeated tests... use with -r <REPETITIONS>
DO_DIFF="" # use -d if you want to see the diff
IGNORE_TESTS="" #for see help for test ignoring
IGNORE_REGEX="" #for see help for test ignoring
TESTS_TO_IGNORE=()
# Binarka:
BINARY="./main.out" 
LANG="C"


compile(){

    case $LANG in
        C) compile_c;;
    esac

}
compile_c(){
# Progtest kompilace:
gcc -g $SOURCE_FILES -o $BINARY -lm -std=c99  #2>/dev/null

# Test kompilace:
if [[ $? != 0 ]]; then
	echo "There was an error during compilation..."
	exit 1
fi

}

show_help(){

    printf "Usage: ./test.sh ([OPTION] [ARGS]?)*
      -h,            prints help
      -s,            specify source files (main.c is default)
      -L,            choose language (just \"C\" for now)
      -d,            prints also difference in your_output and datapub_output
      -i <TESTS>,    ignore certain tests, where <TESTS> are relative paths in datapub directory (\"test01.in test02.in\")
      -iR <TESTS_R>, ignore tests in datapub directory with extended regex <TESTS_R> (like \"test1.\.in\" or \"test0[1-5].\.in\")
      -r <REPEAT>,   repeat tests (useful for not innitialized variables errors)
      -t <TIMEOUT>,  set timeout for tests\n"
}
test_outputs(){

# Pro vsechny soubory s nazvem "*.in" ve složce datapub...
for TEST_FILE in ./datapub/*.in; do
	
	if [ "$IGNORE_TESTS" == "yes" ]; then
		#špatn 
		if [ ! "$IGNORE_REGEX" == "" ]; then
			(echo "$TEST_FILE" | grep -E "$IGNORE_REGEX" 1>/dev/null) && continue
		fi
		(echo "${TESTS_TO_IGNORE[*]}"  | fgrep -q "$TEST_FILE") && continue
		
	fi
	echo -n ">>> Testing $TEST_FILE "
 
	DIFF=$(timeout "$TIMEOUT" diff "${TEST_FILE/in/out}" <($PROGRAM 2>/dev/null < $TEST_FILE ) ||  echo "TIMED OUT after $TIMEOUT")
	if [ "$DIFF" == "" ]; then
		echo "- OK" | colorize green
	else
		echo "- FAILED" | colorize red
		RETURN=1
 		if [ "$DO_DIFF" == "yes" ]; then
		# Vypis rozdil mezi vystupem programu a vzorovym vystupem
			printf "Output diff: $DIFF\n"
		fi
	fi
done

# Smaz binarku:
rm -f "$BINARY"

}

#if no args were passed just do plain run
main(){
compile
for i in $(seq $REPEAT);
do 
	printf "\nRunning...\n"
	test_outputs
done
tput bel
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h) show_help; exit 0;;
        -s) SOURCE_FILES="$2"; printf "Using %s source files...\n" "$SOURCE_FILES";shift;;
        -L) LANG="$2";printf "Language %s...\n" "$LANG";shift;;
        -d) DO_DIFF="yes";;
        -t) TIMEOUT="$2"; printf "Running with timeout = $TIMEOUT\n";shift;;
        -r) REPEAT="$2"; printf "Running with repeat = $REPEAT\n";shift;;
        -i) TESTS_TO_IGNORE+=("$2"); IGNORE_TESTS="yes"; printf "Ignoring... = '%s'\n" "${TESTS_TO_IGNORE[*]}";shift;;
        -iR) IGNORE_REGEX="$2"; IGNORE_TESTS="yes"; printf "Ignoring... = '%s'\n" "$IGNORE_REGEX";shift;;
        
        *) show_help; exit 1 ;;
    esac
    shift
done

main

exit $RETURN

