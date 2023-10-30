#! /bin/sh
[ -d "$HOME/.ipe/ipelets" ] || mkdir -p "$HOME/.ipe/ipelets"
cp -- *.lua "$HOME/.ipe/ipelets/"
