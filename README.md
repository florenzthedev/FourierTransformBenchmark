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

The script will generate the test input files if they do not already exist, create a folder named after the current unix time, and put the results of the test in there.

The prototype the loader program looks for is `int fourier_transform(double complex* X, long N, int aux)`.