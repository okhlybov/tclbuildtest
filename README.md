# TclBuildTest - a TclTest extension to test source code compilation &amp; running

[TclBuildTest](https://github.com/okhlybov/tclbuildtest) provides a set of commands to aid in testing the program compilation and running.

Technically it is built on top of the Tcl's standard [TclTest](https://www.tcl-lang.org/man/tcl/TclCmd/tcltest.htm) unit testing framework.

## Purpose

TclBuildTest is primarily intended (but not limited) to ensure proper installation of packaged libraries by compiling and running the library's supplied sample source code.

## Test creation

The package test suite normally resides in the package test directory which contains a numer of files:

1. `all.tcl` - a package test launcher
2. `*.test` - one or more test descriptors
3. supplimentary files required by tests, such as sample source codes etc.

## Test running

