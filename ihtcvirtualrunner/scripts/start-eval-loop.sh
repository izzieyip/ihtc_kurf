#!/bin/bash

#
# This script can be used to execute the virtualized GIPS-based solution for all of the IHTC 2024 instances.
#
# It assumes that in the current directory there is a folder called
# `ihtc2024_competition_instances` containing all instance files.
#
# Example: `./start-eval-loop.sh $randomSeed $callback       $parameter       $preprocessing $globalTimeOut $constraintCleanup`
#                                0           ./callback.json ./parameter.json nogt           7200           u
#                                $1          $2              $3               $4             $5             $6
#
# If you have any questions, feel free to write us an email.
#
# @author Maximilian Kratz (maximilian.kratz@es.tu-darmstadt.de)
#

set -e

# Configuration taken by the arguments
export randomSeed=$1
export callback=$2
export parameter=$3
export preprocessing=$4
export globalTimeOut=$5
export constraintCleanUp=$6

if [ -z "$randomSeed" ]; then
    echo "Missing parameter for random seed."
    exit 1
fi
if [ -z "$callback" ]; then
    echo "Missing parameter for callback JSON path."
    exit 1
fi
if [ -z "$parameter" ]; then
    echo "Missing parameter for parameter JSON path."
    exit 1
fi
if [ -z "$preprocessing" ]; then
    echo "Missing parameter for preprocessing configuration."
    exit 1
fi
if [ -z "$globalTimeOut" ]; then
    echo "Missing parameter for global timeout."
    exit 1
fi
# No parameter check for constraint clean up on purpose

# Executes the `start-args-gips.sh` script
function run {
    echo "Running: $1"
    # Arguments of the `start-args-gips.sh` script
    # ./i01.json ./i01_solution.json 0 ./callback.json ./parameter.json gt u
    # $1         #$2                 $3 $4             $5               $6 $7
    timeout $globalTimeOut ./start-args-gips.sh "$1" "$2" $randomSeed $callback $parameter $preprocessing $constraintCleanUp
    if [ $? -eq 124 ]; then
        echo "Global timelimit of ${globalTimeOut}s violated. GIPS run was killed before finishing."
    fi
}

echo "#"
echo "# => Eval loop script start."
echo "#"

for ((i=1;i<=30;i++));
do
    if [ $i -lt 10 ]; then
        echo "./ihtc2024_competition_instances/i0$i.json"
        run "./ihtc2024_competition_instances/i0$i.json" "./ihtc2024_competition_instances/i0${i}_solution.json"
    else
        echo "./ihtc2024_competition_instances/i$i.json"
        run "./ihtc2024_competition_instances/i$i.json" "./ihtc2024_competition_instances/i${i}_solution.json"
    fi
done

echo "#"
echo "# => Eval loop script done."
echo "#"
