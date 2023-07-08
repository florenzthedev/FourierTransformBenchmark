#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: $0 [filename]";
    exit 1
fi

testID=$(date +%s)
echo "Starting test $testID..."
mkdir $testID

echo "Recording machine information..."
lscpu > "$testID/machine.txt"
lsmem >> "$testID/machine.txt"
uname -a >> "$testID/machine.txt"

read -r startPow endPow < $1
equation=$(sed -n '2p' $1)
for i in $(seq $startPow $endPow); do
  power=$((2**$i))
  echo "Generating size $power test data..."
  gnuplot -e "set table; set samples $power; set dummy x; plot [x=0:16] ($equation);" | awk '!/^#/ && NF {print $2 ",0"}' > "$testID/test${power}.table"
done

echo "Building loader..."
make

for dir in */ ; do
  echo "Entering $dir and running make..."
  cd $dir
  make
  cd ..
done

tail -n +2 $1 | while read -r benchType benchExec benchName
do
  for i in $(seq $startPow $endPow); do
    power=$((2**$i))
    if [ "$benchType" == "L" ]; then
      echo "Loading '$benchExec' and running size $power benchmark for $benchName..."
      ./loader -s "$benchExec" -t "$testID/test${power}.table" >> "$testID/$benchName.txt"
    else
      echo "TODO: Runnable benches..."
    fi
  done
done