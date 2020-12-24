#!/bin/sh

#
# TclBuildTest installation script
#
# Honours TCLSH DESTDIR PREFIX ALL environment variables
# ALL contains full path to the root all.tcl file to be hardcoded in the launcher scipt
#

set -e

[ -z "$PREFIX" ] && PREFIX=/usr/local
[ -z "$ALL" ] && ALL="$PREFIX/share/test/all.tcl"

[ -z "$DESTDIR" ] || rm -rf "$DESTDIR"

ver=$(echo 'source [file join . tclbuildtest.tcl]; puts [package require tclbuildtest]' | ${TCLSH:-tclsh})
dir="$DESTDIR/$PREFIX/bin"
mkdir -p "$dir"
install tclbuildtest -t "$dir"
sed -i -e "s|ALL=.*\$|ALL='$ALL'|" "$dir/tclbuildtest"


dir="$DESTDIR/$PREFIX/share/doc/tclbuildtest"
mkdir -p "$dir"
install -m444 README.md LICENSE -t "$dir"

dir="$DESTDIR/$PREFIX/share/test"
mkdir -p "$dir"
install -m444 all.tcl -t "$dir"

dir="$DESTDIR/$PREFIX/lib/tclbuildtest$ver"
mkdir -p "$dir"
install -m444 tclbuildtest.tcl -t "$dir"
(
    cd "$dir"
    echo 'pkg_mkIndex .' | ${TCLSH:-tclsh}
)

#