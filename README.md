# FourierTransformBenchmark
A benchmark collection for comparing implementations of the Fourier transform.

## Usage
`./benchmark.sh [test csv]` where test csv is a file in the following format:
```[smallest input power],[largest input power],[timeout in seconds]
[gnuplot equation]
[test type],[shared object file],[test name],[aux input min],[aux input max]
```
Bottom line is repeated for as many tests as needed.
Test types are currently:
`L` - loaded test, loads a function from a shared object file and runs it, aux input is always 0 for this test type and can be omitted from the csv.
`T` - threaded test, loads a function from a shared object and passes in the range of aux inputs given in the csv.

The script will generate the test input files if they do not already exist, create a folder named after the current unix time, and put the results of the test in there. A tex file for graphing the test results will be  generated as well and the script will try to build it.

This script requires:
`gnuplot` - generates test data.
`timeout` - for making sure tests are reasonable.
`pdflatex` - generates final graph of results.
Tikz, pgfplots, and standalone are used inside of the LaTeX document.

The prototype the loader program looks for is `int fourier_transform(double complex* X, long N, int aux)`.