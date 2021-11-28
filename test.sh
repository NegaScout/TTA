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
BINARY="./main.out" #default binary path. its not main to not overwrite your other binary that might be named "main"
QUIET=""
FLAGS="-O3"
DIFF=""
COMPILATOR=""#gcc # script still compiles, when no compiler is specified
SOURCE_FILES="main.c" #default source file
TEST_DIR="datapub"
DO_C_RETURNS="yes"
PACKAGE_NAME="alg_solution"

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

        COMPILATOR="make" 
        quitable "Compiling using ${COMPILATOR}...\n"
        $COMPILATOR # $COMPILATOR == make 
    elif [ "$COMPILATOR" == "javac" ]; then

        mkdir -p $PACKAGE_NAME
        #cp ${SOURCE_FILES} $PACKAGE_NAME
        echo $SOURCE_FILES | xargs $COMPILATOR
        BINARY="java ${PACKAGE_NAME}.Main"
    else

        quitable "Compiling using ${COMPILATOR} -o ${BINARY} ${SOURCE_FILES} ${FLAGS}...\n"
        $COMPILATOR -o $BINARY $SOURCE_FILES $FLAGS
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

        echo "Up-to-date" | colorize green
        true
    elif [ $LOCAL = $BASE ]; then

        printf "There is new version available. Do you want to pull changes? (y/n) " | colorize green
        read -p "" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] && git pull
            
    elif [ $REMOTE = $BASE ]; then

        true
        echo "Need to push"
    else

        echo "TTA versions are diverged!" | colorize red
    fi
}
remove_cariage_returns(){

    for file in ./$TEST_DIR/*.out; do
	    
        cat "$file" | tr -d '\r' > "tmp"
	    mv "tmp" $file
    done;
}
show_help(){

    printf "Usage: ./test.sh ([OPTION] [ARGS]?)* 
       This script looks for all <test_file>.in, pipes them into your binary and then compares them with <test_file>.out.
       Example of using ./test.sh -d -t 5 -r 3 -o \"./main\" -iR \"test0[1-5].*\"
       Exit code is number of failed tests. 
      -h,               prints help
      -c <COMPILATOR>,  uses specified compilator (default is gcc, use javac for java)
      -s <S_FILES>,     uses specified source files (Use as \"source1.c source2.c\" ..!), default is \"main.c\"
      -F <FLAGS>,       feeds specified flags into compilator args in \"\$COMPILATOR -o \$BINARY \$SOURCE_FILES \$FLAGS\" manner
      -p)               specifies package name (needed for java PACKAGE_NAME.Main execution, did not test without packages)
      -q,               supresses any text outputs
      -o,               target binary AND output binary for COMPILATOR
      -m,               compile with your local Makefile
      -u,               look for update on this script at github
      -d,               prints also the difference in your_output and datapub_output
      -D <TEST_DIR>,    specifies directory with tests, default is \"datapub\"
      -i <TESTS>,       ignore certain tests, where <TESTS> are relative paths in <TEST_DIR> directory, like: (\"test01.in test02.in\")
      -iR <TESTS_R>,    ignore tests in <TEST_DIR> directory with extended regex (grep -w -E <TESTS_R>)  (like \"test1.in\" or \"test0[1-5].*\")
      -r <REPEAT>,      repeat selected tests for <REPEAT> times
      -nW,              doesnt remove all \'\r\' cariage returns characters from all files in <TEST_DIR> (it defaultly does)
      -t <TIMEOUT>,     set timeout for the tests (doesnt inform of timeout, cant get it to work :<)\n"
}

test_outputs(){

    for TEST_FILE in ./$TEST_DIR/*.in; do
    #echo "$TEST_FILE"
        if [ "$IGNORE_TESTS" == "yes" ]; then

            if [ ! "$IGNORE_REGEX" == "" ]; then

                (echo "$TEST_FILE" | grep -E "$IGNORE_REGEX" 1>/dev/null) && continue
            fi
            (echo "${TESTS_TO_IGNORE[*]}"  | grep -w -q "$TEST_FILE") && continue
            
        fi
        quitable ">>> Testing $TEST_FILE "
        DIFF="$(timeout "$TIMEOUT" diff "${TEST_FILE/in/out}" <($BINARY 2>/dev/null <$TEST_FILE) ||  echo "" )"
        if [ "$DIFF" == "" ]; then

            quitable "~ OK\n" | colorize green
        else

            quitable "~ FAILED\n" | colorize red
            #((RETURN++)) this aborts script on
            if [ "$DO_DIFF" == "yes" ]; then

                quitable "Output diff: %s\n" "$DIFF"
                echo ""
            fi
        fi
    done

}

main(){
    set -e
    if [ ! "$COMPILATOR" == "" ]; then

  	    compile
    fi
    
    # this became vroken when adding support for Java
    #ls | grep -E -w "${BINARY##"./"}" &>/dev/null || (quitable "File \'${BINARY##"./"}\' doesnt exist\n" | colorize red; exit 1;)

    if [ ! "$DO_C_RETURNS" == "yes" ]; then

        remove_cariage_returns
    fi

    for i in $(seq $REPEAT);
    do 
        quitable "\nRunning $i...\n"
        test_outputs
    done

    #makes a sound, when script is finished
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
        -s) SOURCE_FILES="$2"; quitable "Using \"$SOURCE_FILES\" source files...\n";shift;;
        -F) FLAGS="$2";shift;;
        -m) MAKE="yes";;#
        -c) COMPILATOR="$2";shift;;
        -p) PACKAGE_NAME="$2"; quitable "Using \"$PACKAGE_NAME\" package name...\n";shift;;
        -u) UPDATE="yes";;#
        -d) DO_DIFF="yes";;#
        -D) TEST_DIR="$2";shift;;
        -t) TIMEOUT="$2"; quitable "Running with timeout = $TIMEOUT\n";shift;;#
        -r) REPEAT="$2"; quitable "Running with repeat = $REPEAT\n";shift;;#
        -nW) DO_C_RETURNS="no";;#
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

