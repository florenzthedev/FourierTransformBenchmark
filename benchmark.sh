#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: $0 [filename]";
    exit 1
fi

testID=$(date +%s)
echo "Starting test $testID..."
mkdir $testID

echo "Recording machine information..."
date > "$testID/machine.txt"
lscpu >> "$testID/machine.txt"
lsmem >> "$testID/machine.txt"
uname -a >> "$testID/machine.txt"

IFS=',' read -r startPow endPow timeoutTime < $1
equation=$(sed -n '2p' $1)
for i in $(seq $startPow $endPow); do
  power=$((2**$i))
  echo "Generating size $power test data..."
  gnuplot -e "set table; set samples $power; set dummy x; plot [x=0:16] ($equation);" | awk '!/^#/ && NF {print $2 ",0"}' > "$testID/test$power.table"
done

echo "Building loader..."
make

for dir in */ ; do
  if [[ $dir =~ ^[0-9]+$ ]]; then
    continue
  fi
  echo "Entering $dir and running make..."
  cd $dir
  make
  cd ..
done

tail -n +3 $1 | while IFS=',' read -r benchType benchExec benchName
do
  for i in $(seq $startPow $endPow); do
    power=$((2**$i))
    if [ "$benchType" == "L" ]; then
      echo "Loading '$benchExec' and running size $power benchmark for $benchName..."
      timeout $timeoutTime ./loader -s "$benchExec" -t "$testID/test$power.table" >> "$testID/$benchName.txt"
      if [ $? -eq 124 ]; then
        echo "Timeout at $timeoutTime seconds, recording..."
        echo "$power,$timeoutTime" >> "$testID/$benchName.txt"
      fi
    else
      echo "TODO: Runnable benches..."
    fi
  done
done

echo "Cleaning up test files..."
rm $testID/*.table