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
UPDATE=0
# Binarka:
BINARY="./main.out" 
LANG="C"
QUIET=""

quitable(){
if [ ! "$QUIET" == "yes" ]; then
    printf "$*"
fi
}
check_for_dependencies(){

dpkg -l | grep -E -w "colorize" &>/dev/null || COLORIZE="no"
if [ "$COLORIZE" == "no" ]; then
	read -p "Colorize package might not be installed. Do you want to install this dependency? (y/n)" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] && INSTALL="yes"
	
	if [ "$INSTALL" == "yes" ]; then
		(sudo apt-get update && sudo apt-get install colorize) && (echo "Colorized installed succesfully.") | colorize green
	else echo "This script needs colorize to work. Exiting."; exit 1
	fi
fi

}
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
    [[ $QUIET -eq  "yes" ]] && printf "There was an error during compilation..."
	#echo "There was an error during compilation..."
	exit 1
fi

}

check_for_updates(){
#!/bin/sh
ls -a | grep ".git" || (echo "Script is not in git clone folder, cant check for updates..." && exit 1)
git remote update &>/dev/null
UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "Up-to-date"
    true
elif [ $LOCAL = $BASE ]; then
    printf "There is new version available. Do you want to pull changes? (y/n) " | colorize green
    #read -p CONSENT
    read -p "" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] && git pull
    	
    	#(echo "$TEST_FILE" | grep -F -E "$IGNORE_REGEX" 1>/dev/null) && continue
    #fi
elif [ $REMOTE = $BASE ]; then
    true
    echo "Need to push"
else
    echo "TTA versions are diverged!"
fi
}
show_help(){

    printf "Usage: ./test.sh ([OPTION] [ARGS]?)* 
       Exit code is number of failed tests.
      -h,            prints help
      -q,            supresses any text outputs
      -s,            specify source files (main.c is default)
      -L,            choose language (just \"C\" for now)
      -u,            look for updates 
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
			(echo "$TEST_FILE" | grep -F -E "$IGNORE_REGEX" 1>/dev/null) && continue
		fi
		(echo "${TESTS_TO_IGNORE[*]}"  | grep -F -q "$TEST_FILE") && continue
		
	fi
	quitable ">>> Testing $TEST_FILE "
 
	DIFF=$(timeout "$TIMEOUT" diff "${TEST_FILE/in/out}" <($BINARY 2>/dev/null < $TEST_FILE ) ||  echo "TIMED OUT after $TIMEOUT")
	if [ "$DIFF" == "" ]; then
		quitable "~ OK\n" | colorize green
	else
		quitable "~ FAILED\n" | colorize red
		((RETURN++))
 		if [ "$DO_DIFF" == "yes" ]; then
		# Vypis rozdil mezi vystupem programu a vzorovym vystupem
			quitable "Output diff: %s\n" "$DIFF"
		fi
	fi
done

# Smaz binarku:


}

#if no args were passed just do plain run
main(){
compile
for i in $(seq $REPEAT);
do 
	quitable "\nRunning $i...\n"
	test_outputs
done
tput bel
}
check_for_dependencies
(
  # this flag will make to exit from current subshell on any error inside check_for_updates
  set -e
  if [ "$UPDATE" == "yes" ]; then
  	check_for_updates
  fi
  
)
for arg in "$@";
do 
 	if [ "$arg" == "-q" ]; then
		QUIET="yes"
	fi
done

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h) show_help; exit 0;;
        -q) QUIET="yes";;
        -s) SOURCE_FILES="$2"; quitable "Using $SOURCE_FILES source files...\n";shift;;
        -L) LANG="$2";quitable "Language $LANG...\n";shift;;
        -u) UPDATE="yes";shift;;
        -d) DO_DIFF="yes";;
        -t) TIMEOUT="$2"; quitable "Running with timeout = $TIMEOUT\n";shift;;
        -r) REPEAT="$2"; quitable "Running with repeat = $REPEAT\n";shift;;
        -i) TESTS_TO_IGNORE+=("$2"); IGNORE_TESTS="yes"; quitable "Ignoring... = '%s'\n" "${TESTS_TO_IGNORE[*]}";shift;;
        -iR) IGNORE_REGEX="$2"; IGNORE_TESTS="yes"; quitable "Ignoring... = '$IGNORE_REGEX'\n";shift;;
        
        *) show_help; exit 1 ;;
    esac
    shift
done

main
rm -f "$BINARY"

exit $RETURN

