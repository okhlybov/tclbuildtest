# TclBuildTest - a TclTest extension to test source code compilation &amp; running

[TclBuildTest](https://github.com/okhlybov/tclbuildtest) provides a set of commands to aid in testing the program compilation and running.

Technically it is built on top of the Tcl's standard [TclTest](https://www.tcl-lang.org/man/tcl/TclCmd/tcltest.htm) unit testing framework.

## Purpose

TclBuildTest is primarily intended (but not limited) to run integration tests to ensure proper state of packaged libraries along with its dependencies by compiling and running the library's supplied sample source code.

## Tests creation

The package test suite normally resides in the package-specific test directory named `${package}` which contains the following files

1. `all.tcl` - a package test launcher
2. `*.test` - one or more test descriptors
3. supplementary files required by tests, such as sample source codes, input data files etc.

It is customary to have one `.test` file per package named `${package}.test`.

The default package-specific test location is thus `${prefix}/share/test/${package}`.

## Tests running

Tests can be run either directly via `tclsh` or using the `tclbuildtest` launcher script.

### Tclsh

In the first case the Tcl interpreter is run with the package-specific `all.tcl` as command line argument equipped with usual TclTest arguments.

### TclBuildTest

The `tclbuildtest` script can be used to run the entire system-wide test harness using the root `${prefix}/share/test/all.tcl` as an entry point. In this case the TclTest framework accounts for the recursive discovery and execution of the tests found within the terst directory hierarchy. Additional command line arguments for the script remain the same.

What differentiates the above two cases is that the `tclbuildtest` script spawns a special sanitizer process which does a cleanup job by deleting a staging temporary directory used by sandboxed tests to ensure no stray files are left after the harness execution in spite of test failures, interpreter crashes, SIGHUPs etc.

