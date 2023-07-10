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

echo "Initializing graph..."
echo "\documentclass[tikz]{standalone}
\usepackage{pgfplots}
\pgfplotsset{compat=1.17, 
cycle list={
        {red, mark=*, thick},
        {blue, mark=*, thick},
        {green, mark=*, thick},
        {orange, mark=*, thick},
        {purple, mark=*, thick},
        {brown, mark=*, thick},
        {black, mark=*, thick},}
        }

\begin{document}
\begin{tikzpicture}
\begin{axis}[xmode=log,log basis x={2}, xlabel={Input Dataset Size}, ylabel={Seconds}]" > "$testID/graph.tex"

IFS=',' read -r startPow endPow timeoutTime < $1
equation=$(sed -n '2p' $1)
for i in $(seq $startPow $endPow); do
  power=$((2**$i))
  if [ ! -f "test$power.table" ]; then
    echo "Generating size $power test data..."
    gnuplot -e "set table; set samples $power; set dummy x; plot [x=0:16] ($equation);" | awk '!/^#/ && NF {print $2 ",0"}' > "test$power.table"
  fi
done

echo "Building loader..."
make

for dir in */ ; do
  dir_comp=${dir%/}
  if [[ $dir_comp =~ ^[0-9]+$ ]]; then
    continue
  fi
  echo "Entering $dir and running make..."
  cd $dir
  make
  cd ..
done

echo "\legend{" > "$testID/legend.tex"
tail -n +3 $1 | while IFS=',' read -r benchType benchExec benchName auxStart auxEnd
do
  if [ "$benchType" == "L" ]; then
    echo "${benchName}," >> "$testID/legend.tex"
    echo "\addplot table[col sep=comma,header=false,x index=0,y index=1] {${benchName}.txt};" >> "$testID/graph.tex"
  elif [ "$benchType" == "T" ]; then
    for j in $(seq $auxStart $auxEnd); do
      echo "${benchName}_${j}," >> "$testID/legend.tex"
      echo "\addplot table[col sep=comma,header=false,x index=0,y index=1] {${benchName}_${j}.txt};" >> "$testID/graph.tex"
    done
  fi
  for i in $(seq $startPow $endPow); do
    power=$((2**$i))
    if [ "$benchType" == "L" ]; then
      echo "Loading '$benchExec' and running size $power benchmark for $benchName..."
      timeout $timeoutTime ./loader -s "$benchExec" -t "test$power.table" >> "$testID/$benchName.txt"
      if [ $? -eq 124 ]; then
        echo "Timeout at $timeoutTime seconds, recording..."
        echo "$power,$timeoutTime" >> "$testID/$benchName.txt"
        break
      fi
    elif [ "$benchType" == "T" ]; then
      for j in $(seq $auxStart $auxEnd); do
        echo "Loading '$benchExec' and running size $power benchmark for $benchName with auxillary input $j..."
        timeout $timeoutTime ./loader -s "$benchExec" -t "test$power.table" -a $j >> "$testID/${benchName}_${j}.txt"
        if [ $? -eq 124 ]; then
          echo "Timeout at $timeoutTime seconds, recording..."
          echo "$power,$timeoutTime" >> "$testID/${benchName}_${j}.txt"
          break
        fi
      done
    fi
  done
done

echo "Generating graph..."
legend=$(<"$testID/legend.tex")
rm "$testID/legend.tex"
legend="${legend::-1}}"
legend="${legend//_/\\_}"
echo "$legend" >> "$testID/graph.tex"
echo "\end{axis}
\end{tikzpicture}
\end{document}" >> "$testID/graph.tex"
cd "$testID/"
pdflatex graph.tex > /dev/null
cd ..