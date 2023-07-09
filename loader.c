#include <complex.h>
#include <dlfcn.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef int (*ft_func_ptr)(double complex *, long, int);
#define INIT_BLOCK_SIZE 128
#define MAX_LINE_SIZE 1024

int main(int argc, char *argv[]) {
  // Process arguments
  const char *library_filename = NULL, *table_filename = NULL;
  int carg;
  bool print_results = false;
  while ((carg = getopt(argc, argv, "ps:t:")) != -1) {
    switch (carg) {
      case 's':
        library_filename = optarg;
        break;
      case 't':
        table_filename = optarg;
        break;
      case 'p':
        print_results = true;
      case '?':
        // Error message already printed out
        exit(EXIT_FAILURE);
      default:
        abort();
    }
  }

  if (library_filename == NULL || table_filename == NULL) {
    printf(
        "Usage: %s -s [library_filename] -l [table_filename] [-p]\n"
        "\t-s [library_filename]: name of shared object file to load. \n"
        "\t-l [table_filename]: name of table of values to load.\n"
        "\t-p: optional, print results.\n", argv[0]);
    return EXIT_FAILURE;
  }

  void *library_handle = dlopen(library_filename, RTLD_LAZY);
  if (!library_handle) {
    fprintf(stderr, "Error: could not open shared object file '%s'\n",
            library_filename);
    return EXIT_FAILURE;
  }

  ft_func_ptr ft_func = dlsym(library_handle, "fourier_transform");
  if (!ft_func) {
    fprintf(stderr,
            "Error: could not locate fourier_transform symbol in shared object "
            "file '%s'\n",
            library_filename);
    return EXIT_FAILURE;
  }

  FILE *fp = fopen(table_filename, "r");
  if (fp == NULL) {
    fprintf(stderr, "Error: could not open file '%s'\n", table_filename);
    return EXIT_FAILURE;
  }

  int N = 0;
  double complex *x = malloc(sizeof(double complex) * INIT_BLOCK_SIZE);
  if (x == NULL) {
    fprintf(stderr, "Error: memory allocation failed.\n");
    return EXIT_FAILURE;
  }
  double temp_real, temp_imag;
  int allocated = INIT_BLOCK_SIZE;

  // using fgets means we get the whole line, this is useful if excel wants to
  // add extra commas to our file
  char line[MAX_LINE_SIZE];
  while (fgets(line, MAX_LINE_SIZE, fp)) {
    sscanf(line, "%lf,%lf", &temp_real, &temp_imag);
    if (N == allocated) {
      x = realloc(x, (allocated *= 2) * sizeof(double complex));
      if (x == NULL) {
        fprintf(stderr, "Error: memory allocation failed.\n");
        return EXIT_FAILURE;
      }
    }
    x[N++] = CMPLX(temp_real, temp_imag);
  }
  fclose(fp);

  // pad with zeros to next nearest power of two
  while (N < allocated) x[N++] = 0;

  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
  int result = (*ft_func)(x, N, 0);
  clock_gettime(CLOCK_MONOTONIC, &end);
  if (result) {
    fprintf(stderr, "Error: called function failed.\n");
    return EXIT_FAILURE;
  }
  double elapsed = (end.tv_sec - start.tv_sec);
  elapsed += (end.tv_nsec - start.tv_nsec) / 1000000000.0;
  printf("%d,%f\n", N, elapsed);

  if(print_results){
    for(int j = 0; j < N; j++)
      printf("%f,%fi\n", creal(x[j]), cimag(x[j]));
  }

  dlclose(library_handle);
  return 0;
}