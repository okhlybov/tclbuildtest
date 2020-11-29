#!/bin/bash

set -e

echo 'pkg_mkIndex .' | tclsh
pkgver=`echo 'set auto_path .; puts [package require tclbuildtest]' | tclsh`

rm -rf build
mkdir -p build/tclbuildtest/test
cp -r test build/tclbuildtest
cp README.md pkgIndex.tcl tclbuildtest.tcl all.tcl build/tclbuildtest
tar czf tclbuildtest-${pkgver}.tar.gz -C build tclbuildtest

#