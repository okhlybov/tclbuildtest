

# TclBuildTest - a TclTest extension to test source code compilation &amp; running

[TclBuildTest](https://github.com/okhlybov/tclbuildtest) provides a comprehensive set of commands to aid in testing program compilation and running. Technically it is built on top of the [Tcl](http://tcl.tk/)'s built-in [TclTest](https://www.tcl-lang.org/man/tcl/TclCmd/tcltest.htm) unit testing framework.

## Purpose

TclBuildTest is primarily intended (though not limited) to run integration tests in order to ensure the proper state of packaged libraries along with its dependencies by compiling and running the library's supplied sample source code.

## Features

* Self-contained test packages directly runnable with `tclsh`
* System-wide installation with `tclbuildtest` harness launcher script
* Selective constraint-based tests execution
* Test sandboxing to make test packages runnable from read-only locations
* Automatic tools discovery
* External dependencies discovery with PkgConfig
* C/C++/FORTRAN source code compilation
* Sequential, multithreaded and MPI-aware parallel programs execution

  

## Requirements

* UNIX-like environment ([MSYS2](https://www.msys2.org/), [Cygwin](https://www.cygwin.com/), [WSL](https://docs.microsoft.com/windows/wsl/about) included)
* [Tcl 8.6](http://tcl.tk/software/tcltk/8.6.html)+
* [GCC](http://gcc.gnu.org/) toolchain
* [PkgConfig](https://www.freedesktop.org/wiki/Software/pkg-config/) or [equivalent](http://pkgconf.org/)
* MPI SDK/runtime (MSYS2' s [Microsoft MPI](https://docs.microsoft.com/en-us/message-passing-interface/microsoft-mpi) included)

## Tests creation

The package test suite normally resides in the package-specific test directory named `${package}` which contains the following files

* `all.tcl` - a package test launcher

* `*.test` - one or more test descriptors

* supplementary files required by tests, such as sample source codes, input data files etc.

It is customary to have one `.test` file per package named `${package}.test`.

The default package-specific test location is thus `${prefix}/share/test/${package}`.

### all.tcl

This is a short conventionally named module responsible for tests discovery and execution. A common template to be used by the tests is as follows

```tcl
package require tclbuildtest
::tclbuildtest::suite {*}$::argv
```

This code relies upon the system-wide TclBuildTest package. In order for a test package to be self-contained a local package-specific TclBuildTest package can be used. In this case, the `tclbuildtest.tcl` is to be loaded manually and hence `all.tcl` becomes

```tcl
source [file join [file dirname [file normalize [info script]]] tclbuildtest.tcl]
package require tclbuildtest
::tclbuildtest::suite {*}$::argv
```

where the Tcl interpreter is instructed to load the TclBuildTest source directly from a file placed alongside the `all.tcl` currently executed thus effectively bypassing the default Tcl package loading mechanism.

As long as TclBuildTest code is not (yet) stabilized, this variant might be preferable as the package-specific test code can be (or might eventually become) incompatible with the installed system-wide TclBuildTest.



## Tests running

Tests can be run either directly via the Tcl's  `tclsh`  interpreter or the `tclbuildtest` launcher script.

### tclsh

In the first case the Tcl interpreter (normally `tclsh`) is run with the package-specific `all.tcl` as command line argument accompanied with usual TclTest arguments.

### tclbuildtest

The `tclbuildtest` launcher script can be used to run the entire system-wide test harness using root `${prefix}/share/test/all.tcl` as a harness entry point. In this case the TclTest framework accounts for the recursive discovery and execution of the tests found across the test directory hierarchy. Additional command line arguments for the script remain the same.

What differentiates the above two cases is that TclBuildTest spawns a special sanitizer process which does a cleanup job by deleting a staging temporary directory used by sandboxed tests to ensure no stray files are left after the harness execution in spite of test failures, interpreter crashes, SIGHUPs etc.

By default the TclBuildTest runs all tests across the test directory hierarchy. In order to run a specific test package the `ALL` environment variable can be set that is

```shell
ALL=/path/to/all.tcl tclbuildtest ...
```

is (roughly) an equivalent to

```shell
tclsh /path/to/all.tcl ...
```

#### Verbosity options

TclBuildTest borrows all configuration command line and environment properties from TclTest with one notable exception: the verbosity property is enhanced with a flag `x` (or `exec`) controlling the output of the in-test shell commands being executed along with respective standard and error outputs.

For the complete list of the verbosity options refer to the [TclTest](https://www.tcl-lang.org/man/tcl/TclCmd/tcltest.htm#M95) documentation. To start off there are a few use cases below.

The two equivalent commands below print names of the tests being executed

```shell
tclbuildtest -verbose t
```
```shell
tclbuildtest -verbose start
```

In order to additionally trace in-test commands being executed the following is used

```shell
tclbuildtest -verbose tx
```

```shell
tclbuildtest -verbose 'start exec`
```

When no `-verbose` flag is specified a default value of `body error` is in effect which outputs detailed description of test failures.