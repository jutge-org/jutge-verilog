#!/bin/bash

set -e

prefix=/usr/local
njobs=2
sudo=sudo

# Prepare system and install dependencies
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install build-essential curl gperf cmake byacc flex -y

# Download stuff
if [[ ! -f verilog-0.8.7.tar.gz ]]; then
	curl "https://www.cs.upc.edu/~jspedro/cv/verilog-0.8.7.tar.gz" -o verilog-0.8.7.tar.gz
fi
if [[ ! -f verilog-0.8.7-patches.tar.gz ]]; then
	curl "https://www.cs.upc.edu/~jspedro/cv/verilog-0.8.7-patches.tar.gz" -o verilog-0.8.7-patches.tar.gz
fi
if [[ ! -f NuSMV-2.6.0.tar.gz ]]; then
	curl "http://nusmv.fbk.eu/distrib/NuSMV-2.6.0.tar.gz" -o NuSMV-2.6.0.tar.gz
fi

# Unpack stuff
tar xvf verilog-0.8.7.tar.gz
tar xvf verilog-0.8.7-patches.tar.gz
tar xvf NuSMV-2.6.0.tar.gz

# Build Icarus Verilog
pushd verilog-0.8.7
for p in ../patches/*; do
	patch -p1 < "$p"
done

./configure --prefix=$prefix
make -j $njobs
popd

# Build NuSMV
pushd NuSMV-2.6.0/NuSMV
sed -i -e 's/add_subdirectory(doc)//' CMakeLists.txt # No docs
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix ..
make -j $njobs
popd

# Install stuff
pushd verilog-0.8.7
$sudo make install
popd

pushd NuSMV-2.6.0/NuSMV/build
$sudo make install
popd

cat > nusmv-user.conf <<EOF
functor:synth2
functor:synth
functor:syn-rules
-t:dll
flag:DLL=/tmp/jutge-javier-tgt-nusmv/nusmv.tgt
EOF
$sudo install nusmv-user.conf $prefix/lib/ivl-0.8/nusmv-user.conf

