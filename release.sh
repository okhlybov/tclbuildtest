#!/bin/bash

set -e

echo 'pkg_mkIndex .' | ${TCLSH:-tclsh}
ver=$(echo 'source [file join . tclbuildtest.tcl]; puts [package require tclbuildtest]' | ${TCLSH:-tclsh})
pkg=tclbuildtest-$ver
prefix=stage/$pkg

rm -rf stage
mkdir -p $prefix/test
cp -r test $prefix
cp README.md LICENSE pkgIndex.tcl tclbuildtest.tcl all.tcl install.sh tclbuildtest $prefix
tar czf $pkg.tar.gz -C stage $pkg

#