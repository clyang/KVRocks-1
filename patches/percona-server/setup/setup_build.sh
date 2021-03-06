#!/bin/bash -xe
if [ "$#" -ne 2 ]
then
    echo "invalid # of argument"
    echo "use $0 <branch> <the top source directory you want to setup new build>"
    exit 1
fi
BRANCH=$1
SRCTOP=`realpath $2`

# install prerequisite packages
set +e
sudo apt-get install sysstat \
    realpath \
    nvme-cli \
    vim \
    g++ gdb git libboost-all-dev \
    cmake \
    libgflags-dev libgoogle-glog0v5 libjemalloc1 \
    libsnappy-dev libdouble-conversion1v5 \
    libreadline-dev libncurses-dev libz-dev libudev-dev libaio-dev bison libblkid-dev xfslibs-dev \
    libboost-all-dev \
    libevent-dev \
    libdouble-conversion-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libiberty-dev \
    liblz4-dev \
    liblzma-dev \
    libsnappy-dev \
    make \
    zlib1g-dev \
    binutils-dev \
    libjemalloc-dev \
    libssl-dev \
    libc6-dev \
    pkg-config

set -e
mkdir -p $SRCTOP
cd $SRCTOP
git clone git@msl-dc-gitlab.ssi.samsung.com:kvssd/kv-percona-server.git
#git clone git@msl-dc-gitlab.ssi.samsung.com:kvssd/kvdb.git
#git clone ssh://jim.li@105.128.40.38:29418/insdb
#git clone git@msl-dc-gitlab.ssi.samsung.com:kvssd/insdb.git
git clone git@msl-dc-gitlab.ssi.samsung.com:kvssd/KVRocks.git
cd KVRocks
git checkout ${BRANCH}

set -e
# build folly first
mkdir -p $SRCTOP/KVRocks/folly/build
cd $SRCTOP/KVRocks/folly/build
cmake ..
make -j $(nproc)
sudo make install

set -e
cd $SRCTOP/kv-percona-server
git checkout Percona-Server-5.7.20-19
git submodule init
git submodule update
patch -p1 -i $SRCTOP/KVRocks/patches/percona-server/kvrocks-percona-server-5.7.20-19.patch
chmod +x $SRCTOP/kv-percona-server/storage/rocksdb/get_kvdb_files.sh
set +e
mkdir build
cd build
make clean
cmake ..  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DKVROCKS_ROOT_DIR=$SRCTOP/KVRocks -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../../..  -DENABLE_DOWNLOADS=1 -DCMAKE_INSTALL_PREFIX=~/install/myrocks.kv
#make -j $(nproc)
#

~/bin/mk_kvdb.sh ${SRCTOP}
