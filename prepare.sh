#!/bin/bash
source armgcc_version

# This is the base path of the FreeRTOS BPS
PACKAGE_PATH=${PWD}
# Define the board names supported by the FreeRTOS BSP here
declare -a SUPPORTED_BOARDS=("picocoremx8mp")
declare -a SUPPORTED_SOCS=("fsimx8mp")

if [ ${#SUPPORTED_BOARDS[@]} -ne ${#SUPPORTED_SOCS[@]} ]; then
	printf "SUPPORTED_BOARDS and SUPPORTED_SOCS have to have the same length with matching board and socket\n"
	exit -1
fi

# Array with -D flags for CMake
declare -a CMAKE_DEFINES=()

# Font codes go here
BOLD='\033[1m'
NORMAL='\033[0m'
LIGHT_GREEN='\033[1;32m'
LIGHT_RED='\033[0;31m'

################################################################################
# function: setBuildType()
#
# parameters: $1: build type as character
#
# return: -
#
# description:
# Set the build type to release or debug
#
################################################################################
function setBuildType()
{
  type
  if [[ "$1" ==  "d" ]]; then
    CMAKE_DEFINES+=('-DCMAKE_BUILD_TYPE=Debug')
  elif [[ "$1" == "r" ]]; then
    CMAKE_DEFINES+=('-DCMAKE_BUILD_TYPE=Release')
  else
    printf "Incorrect build type.\b\n"
    exit -1
  fi
}


# Board selection
printf "Choose on of the following boards for which you want to build the examples:\b\n"

count=0
for board in ${SUPPORTED_BOARDS[@]}; do
  count=$((count+1))
  # Format: board_name[number]
  printf "%s[${BOLD}%s${NORMAL}]\t" "$board" "$count"
done

printf "\nEnter number in []-brackets for the corresponding board: "
read board_given
FOUND=false

# Only numerical input allowed!
if [ -n $board_given ] && [[ $board_given =~ ^[0-9]+$ ]]; then
  # Check input for range of valid entries
  if [ $board_given -le ${#SUPPORTED_BOARDS[@]} ]; then
        # Check PCB version for compilation
	if [ "${SUPPORTED_SOCS[$board_given-1]}" = "fsimx8mm" ]; then
                printf "\nPlease choose the production variant V3/V4 (LPDDR4) [1] V5/V6 (DDR3L) [2]: "
                read pcb_version

                if ! [[ $pcb_version =~ ^[1-2]+$ ]]; then
                        printf "\r\nPlease select ${LIGHT_RED}1${NORMAL} or ${LIGHT_RED}2${NORMAL}\n"
                        exit -1
                fi
        fi

	# Path to the example folder for the F&S boards
	chosen_board=${SUPPORTED_BOARDS[$board_given-1]}
 	chosen_soc=${SUPPORTED_SOCS[$board_given-1]}
	PROJECT_PATH="$PACKAGE_PATH/examples/${chosen_soc}"
	if [ "${SUPPORTED_SOCS[$board_given-1]}" = "fsimx6sx" ]; then
		cd $PROJECT_PATH/board_specific_files/${chosen_board}
		createLinks ${chosen_board}
		cd $PACKAGE_PATH
	fi
  else
    printf "You gave ${LIGHT_RED}%s${NORMAL}, but there are only ${LIGHT_GREEN}%s${NORMAL} boards!\b\n" "$board_given" "${#SUPPORTED_BOARDS[@]}"
    exit -1
  fi
else
  echo "No numerical input given!"
  exit -1
fi

# Build type
printf "Do you want a ${BOLD}Release${Normal} or ${BOLD}Debug${NORMAL} build?\b\n"
printf "${BOLD}(r/d)${NORMAL} [default: $default_build_type]: "
read build_type

if [ -n "$build_type" ]; then
  setBuildType $build_type
else
  setBuildType $default_build_type
fi

printf "${LIGHT_GREEN}All set up, starting cmake...${NORMAL}\b\n\n"
# Generate Makefile
cmake -DCMAKE_TOOLCHAIN_FILE="tools/cmake_toolchain_files/armgcc.cmake" -G "Unix Makefiles" -DBOARD:STRING=${chosen_board} -DSOC:STRING=${chosen_soc} ${CMAKE_DEFINES[@]:0} .
# Change default target to install
sed -i.bak '/default\_/s/all/install/g' Makefile && rm Makefile.bak
