#!/bin/bash


TIMEOUT=0
RETURN=0
REPEAT=1
DO_DIFF=""
IGNORE_TESTS=""
TESTS_TO_IGNORE=()
# Binarka:
PROGRAM=./main.out
LANG="C"
SOURCE_FILES="main.c utils.c utils.h"
compile(){

    case $LANG in
        C) compile_c;;
    esac

}
compile_c(){
# Progtest kompilace:
gcc -g "$SOURCE_FILES" -o "$PROGRAM" -lm -std=c99  #2>/dev/null

# Test kompilace:
if [[ $? != 0 ]]; then
	echo "Chyba pri kompilaci."
	exit 1
fi

}

show_help(){

    printf "Usage: ./hw02.sh [OPTION] [PATH_TO_INSERT]\
    \n  -h,            prints help\
    \n  -d,            prints also diff\
    \n  -i,            ignore certain tests - (maybe with regex?) - NOT YET IMPLEMENTED - gotta provide even ./ for now can handle multiple ignores\n
    \n  -r <REPEAT>,   repeat test (useful for unit values errors)\n
    \n  -t <TIMEOUT>,  set timeout for tests\n"
}
test_outputs(){

# Pro vsechny soubory s nazvem "*in.txt"...
for TEST_FILE in ./datapub/*.in; do
	
	if [ "$IGNORE_TESTS" == "yes" ]; then
		#špatn 
		(echo "${TESTS_TO_IGNORE[*]}"  | fgrep -q "$TEST_FILE") && continue
		
	fi
	echo -n ">>> Testing $TEST_FILE "
 
	# Zjisti rozdil mezi vystupem programu a vzorovym vystupem a uloz ho do promenne $DIFF
	DIFF=$(timeout "$TIMEOUT" diff "${TEST_FILE/in/out}" <($PROGRAM 2>/dev/null < $TEST_FILE ) ||  echo "TIMED OUT after $TIMEOUT")
	if [ "$DIFF" == "" ]; then
		echo "- OK" | colorize green
	else
		echo "- FAILED" | colorize red
		RETURN=1
 		if [ "$DO_DIFF" == "yes" ]; then
		# Vypis obsah testovaciho vstupu (tedy data, ktera chybu zpusobila)
		# Vypis rozdil mezi vystupem programu a vzorovym vystupem
			printf "Output diff: $DIFF\n"
		fi
	fi
done

# Smaz binarku:
rm -f program.out

}

innit(){
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h) show_help; exit 0;;
        -d) DO_DIFF="yes";;
        -t) TIMEOUT="$2"; printf "Running with timeout = $TIMEOUT\n";shift;;
        -r) REPEAT="$2"; printf "Running with repeat = $REPEAT\n";shift;;
        -i) TESTS_TO_IGNORE+=("$2"); IGNORE_TESTS="yes"; printf "Ignoring... = '%s'\n" "${TESTS_TO_IGNORE[*]}";shift;;
        *) show_help; exit 1 ;;
    esac
    shift
done
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

innit
main

exit $RETURN

