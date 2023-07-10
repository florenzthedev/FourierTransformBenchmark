export EXTRA_CFLAGS="-g"
make clean
make
cd $1
make clean
make
cd ..
gdb loader