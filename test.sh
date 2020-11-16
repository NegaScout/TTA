#!/bin/bash

#Change this to suit your needs! 
#All the necessary tweaks should be available through switches

TIMEOUT=0 #for timeout... use with -t <TIMEOUT>
RETURN=0
REPEAT=1 #for repeated tests... use with -r <REPETITIONS>
DO_DIFF="" # use -d if you want to see the diff
IGNORE_TESTS="" #see help for test ignoring
IGNORE_REGEX="" #see help for test ignoring
TESTS_TO_IGNORE=()
UPDATE=""
BINARY="./main.out" #default binary path
#LANG="C"
QUIET=""
MAKE=""
#COMPILATION=""
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
if [ "$MAKE" == "yes" ]; then
	COMPILATION="m" 
fi

    case $COMPILATION in
        m) make;;
    esac

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
    read -p "" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] && git pull
    	
elif [ $REMOTE = $BASE ]; then
    true
    echo "Need to push"
else
    echo "TTA versions are diverged!"
fi
}
show_help(){

    printf "Usage: ./test.sh ([OPTION] [ARGS]?)* 
       This script looks for all <test_file>.in, pipes them into your binary and then compares them with <test_file>.out.
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
      -t <TIMEOUT>,  set timeout for the tests\n"
}
test_outputs(){

for TEST_FILE in ./datapub/*.in; do

	if [ "$IGNORE_TESTS" == "yes" ]; then

		if [ ! "$IGNORE_REGEX" == "" ]; then
			(echo "$TEST_FILE" | grep -E "$IGNORE_REGEX" 1>/dev/null) && continue
		fi
		(echo "${TESTS_TO_IGNORE[*]}"  | grep -w -q "$TEST_FILE") && continue
		
	fi
	quitable ">>> Testing $TEST_FILE "

    DIFF=$(timeout "$TIMEOUT" diff "${TEST_FILE/in/out}" <($BINARY 2>/dev/null < $TEST_FILE ) ||  echo "TIMED OUT after $TIMEOUT")
	
	if [ "$DIFF" == "" ]; then
		quitable "~ OK\n" | colorize green
	else
		quitable "~ FAILED\n" | colorize red
		((RETURN++))
 		if [ "$DO_DIFF" == "yes" ]; then

			quitable "Output diff: %s\n" "$DIFF"
		fi
	fi
done

}

main(){
set -e
ls | grep -E -w "${BINARY##"./"}" &>/dev/null || (quitable "File \'${BINARY##"./"}\' doesnt exist\n" | colorize red; exit 1;)

compile
for i in $(seq $REPEAT);
do 
	quitable "\nRunning $i...\n"
	test_outputs
done

if [ ! "$QUIET" == "yes" ]; then
    tput bel
fi
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
        -h) show_help; exit 0;;#
        -q) QUIET="yes";;#
        -o) BINARY="$2";shift;;#
        -s) SOURCE_FILES="$2"; quitable "Using $SOURCE_FILES source files...\n";shift;;
        -L) LANG="$2";quitable "Language $LANG...\n";shift;;
        -m) MAKE="yes";;#
        -u) UPDATE="yes";;#
        -d) DO_DIFF="yes";;#
        -t) TIMEOUT="$2"; quitable "Running with timeout = $TIMEOUT\n";shift;;#
        -r) REPEAT="$2"; quitable "Running with repeat = $REPEAT\n";shift;;#
        -i) TESTS_TO_IGNORE+=("$2"); IGNORE_TESTS="yes"; quitable "Ignoring... = '%s'\n" "${TESTS_TO_IGNORE[*]}";shift;;#
        -iR) IGNORE_REGEX="$2"; IGNORE_TESTS="yes"; quitable "Ignoring... = '$IGNORE_REGEX'\n";shift;;#
        
        *) show_help; exit 1 ;;
    esac
    shift
done
(
    main
)

exit $RETURN

