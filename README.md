# ICE40 toys:

## Environment setup

## Icestorm

Directions from [http://www.clifford.at/icestorm/](http://www.clifford.at/icestorm/)

    sudo apt-get install build-essential clang bison flex libreadline-dev \
                         gawk tcl-dev libffi-dev git mercurial graphviz   \
                         xdot pkg-config python python3 libftdi-dev \
                         qt5-default python3-dev libboost-dev libeigen3-dev

    git clone https://github.com/cliffordwolf/icestorm.git icestorm
    cd icestorm
    make -j$(nproc)
    sudo make install
    cd ..

    git clone https://github.com/YosysHQ/yosys.git
    cd yosys
    make -j$(nproc)
    sudo make install
    cd ..

    git clone https://github.com/YosysHQ/nextpnr nextpnr
    cd nextpnr
    cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
    make -j$(nproc)
    sudo make install

## Optional

    git clone https://github.com/cseed/arachne-pnr.git arachne-pnr
    cd arachne-pnr
    make -j$(nproc)
    sudo make install
    cd ..

## This repo

And then get the repo:

    git clone https://github.com/cibomahto/upduino.git
    cd upduino/blink
    make
    sudo make flash


