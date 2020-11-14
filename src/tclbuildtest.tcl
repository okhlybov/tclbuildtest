#
# Tcltest extenstion to test source code compilation & running
#
# https://github.com/okhlybov/tclbuildtest
#

package require Tcl 8.6

package require tcltest

package provide tclbuildtest 0.1

namespace eval ::tclbuildtest {
	
	namespace export sandbox test packages compile run constraint?

	# Return a value of the environment variable or {} if no such variable is set
	proc env {var} {
		try {return [set ::env($var)]} on error {} {return {}}
	}

	# PkgConfig detection
	proc pkg-config {} {
		variable pc
		try {set pc} on error {} {
			set pc {}
			foreach x [collect [env PKG_CONFIG] pkg-config pkgconf] {
				if {![catch {exec {*}$x --version}]} {
					set pc $x
					break
				}
			}
		}
		if {$pc == {}} {error {failed to detect PkgConfig or equivalent}}
		return $pc
	}

	# C compiler detection
	proc cc {} {
		variable cc
		try {set cc} on error {} {
			set cc {}
			foreach x [collect [env CC] gcc] {
				if {![catch {exec {*}$x --version}]} {
					set cc $x
					break
				}
			}
		}
		if {$cc == {}} {error {failed to detect C compiler}}
		return $cc
	}

	# C++ compiler detection
	proc cxx {} {
		variable cxx
		try {set cxx} on error {} {
			set cxx {}
			foreach x [collect [env CXX] g++] {
				if {![catch {exec {*}$x --version}]} {
					set cxx $x
					break
				}
			}
		}
		if {$cxx == {}} {error {failed to detect C++ compiler}}
		return $cxx
	}

	# FORTRAN compiler detection
	proc fc {} {
		variable fc
		try {set fc} on error {} {
			set fc {}
			foreach x [collect [env FC] gfortran] {
				if {![catch {exec {*}$x --version}]} {
					set fc $x
					break
				}
			}
		}
		if {$fc == {}} {error {failed to detect FORTRAN compiler}}
		return $fc
	}

	# MPI C compiler detection
	proc mpicc {} {
		variable mpicc
		try {set mpicc} on error {} {
			set mpicc {}
			foreach x [collect [env MPICC] mpicc] {
				if {![catch {exec {*}$x --version}]} {
					set mpicc $x
					break
				}
			}
		}
		if {$mpicc == {}} {error {failed to detect MPI C compiler}}
		return $mpicc
	}

	# MPI C++ compiler detection
	proc mpicxx {} {
		variable mpicxx
		try {set mpicxx} on error {} {
			set mpicxx {}
			foreach x [collect [env MPICXX] mpicxx mpic++ mpiCC] {
				if {![catch {exec {*}$x --version}]} {
					set mpicxx $x
					break
				}
			}
		}
		if {$mpicxx == {}} {error {failed to detect MPI C++ compiler}}
		return $mpicxx
	}

	# MPI FORTRAN compiler detection
	proc mpifc {} {
		variable mpifc
		try {set mpifc} on error {} {
			set mpifc {}
			foreach x [collect [env MPIFC] [env MPIFORT] mpifort mpif90 mpif77] {
				if {![catch {exec {*}$x --version}]} {
					set mpifc $x
					break
				}
			}
		}
		if {$mpifc == {}} {error {failed to detect MPI FORTRAN compiler}}
		return $mpifc
	}

	# Create temporary directory
	proc mktempdir {} {
		set t [file join $::env(TEMP) [file rootname [file tail [info script]]][expr {int(rand()*9999)}]]
		file mkdir $t
		return $t
	}

	# Delete directory tree
	proc rmdir {dir} {
		try {
			file delete -force $dir
		} on error {} {
			exec -ignorestderr nohup sh -c "while \[ -d '$dir' \]; do rm -rf '$dir'; sleep 1; done" > /dev/null 2>@1 &
		}
	}

	proc sandbox {script} {
		variable stagedir [mktempdir]
		try {
			file copy -force {*}[glob -directory [file dirname [file normalize [info script]]] -nocomplain *] $stagedir
			::tcltest::workingDirectory $stagedir
			eval $script
		} finally {
			::tcltest::cleanupTests
			rmdir $stagedir
		}
	}

	proc packages {args} {
		if {[constraint? static]} {set flags --static} else {set flags {}}
		cflags  {*}[lindex [dict get [system [pkg-config] {*}$args --cflags {*}$flags] stdout] 0]
		ldflags {*}[lindex [dict get [system [pkg-config] {*}$args --libs   {*}$flags] stdout] 0]
		return
	}

	proc deduce-language {opts} {
		switch -regexp -nocase [lindex $opts [lsearch -glob -not $opts {-*}]] {
			{\.c$} {return c}
			{\.(cxx|cpp|cc)$} {return c++}
			{\.(f|for|f\d+)$} {return fortran}
			default {error {failed to deduce source language from the command line agruments}}
		}
	}

	proc deduce-compiler-proc {opts} {
		set lang [deduce-language $opts]
		if {[constraint? mpi]} {
			switch $lang {
				c {return mpicc}
				c++ {return mpicxx}
				fortran {return mpifc}
			}
		} else {
			switch $lang {
				c {return cc}
				c++ {return cxx}
				fortran {return fc}
			}
		}
	}

	proc compiler {opts} {
		return [[deduce-compiler-proc [lsqueeze $opts]]]
	}

	proc cppflags {args} {
		variable cppflags
		try {set cppflags} on error {} {
			set cppflags [lsqueeze [env CPPFLAGS]]
			if {![constraint? debug]} {lappend cppflags -DNDEBUG}
		}
		lappend cppflags {*}$args
	}

	proc deduce-compile-flags {opts} {
		switch [deduce-language $opts] {
			c {return cflags}
			c++ {return cxxflags}
			fortran {return fflags}
		}
	}
	
	# Common constraints-specific compilation flags
	proc common-cflags {args} {
		if {[constraint? openmp]} {lappend args -fopenmp}
		if {[constraint? thread]} {lappend args -pthreads}
		if {![constraint? debug]} {lappend args -O2}
		return $args
	}

	proc cflags {args} {
		variable cflags
		try {set cflags} on error {} {
			set cflags [lsqueeze [common-cflags [env CFLAGS]]]
		}
		lappend cflags {*}$args
	}

	proc cxxflags {args} {
		variable cxxflags
		try {set cxxflags} on error {} {
			set cxxflags [lsqueeze [common-cflags [env CXXFLAGS]]]
		}
		lappend cxxflags {*}$args
	}

	proc fflags {args} {
		variable fflags
		try {set fflags} on error {} {
			set fflags [lsqueeze [common-cflags [env FFLAGS]]]
		}
		lappend fflags {*}$args
	}

	proc ldflags {args} {
		variable ldflags
		try {set ldflags} on error {} {
			set ldflags [lsqueeze [env LDFLAGS]]
			if {[constraint? static]} {lappend ldflags -static}
			if {[constraint? openmp]} {lappend ldflags -fopenmp}
			if {[constraint? thread]} {lappend ldflags -pthreads}
		}
		lappend ldflags {*}$args
	}

	proc libs {args} {
		variable libs
		try {set libs} on error {} {
			set libs [lsqueeze [env LIBS]]
			if {[constraint? c++]} {lappend libs -lstdc++}
			if {[constraint? fortran]} {lappend libs -lgfortran -lquadmath}
		}
		lappend libs {*}$args
	}

	proc compile {args} {
		variable compile-count
		set args [lsqueeze $args]
		system {*}[concat \
			[compiler $args] \
			-o [set prog test[incr compile-count]] \
			[cppflags] \
			[[deduce-compile-flags $args]] \
			$args \
			[ldflags] \
			[libs] \
		]
		return $prog
	}

	proc run {args} {
	}

	proc system {args} {
		variable system-count
		incr system-count
		set stdout stdout${system-count}
		set stderr stderr${system-count}
		set args [lsqueeze $args]
		set command [join $args]
		try {
			exec -ignorestderr -- {*}$args > $stdout 2> $stderr
			set options {}
			set status 0
			set code ok
		} trap CHILDSTATUS {results options} {
			set status [lindex [dict get $options -errorcode] 2]
			set code error
		} finally {
			try {
				set out [read-file $stdout]
				set err [read-file $stderr]
			} finally {
				file delete -force $stdout $stderr
			}
		}
		return -code $code [dict create command $command status $status stdout $out stderr $err options $options]
	}

	# Standard predefined constraints
	foreach ct {
		c c++ fortran
		single double
		real complex
		openmp thread hybrid mpi
		static
		debug
	} {::tcltest::testConstraint $ct 1}

	# Construct a scalar type ID from the constraints
	proc x {} {
		if {[constraint? complex]} {
			if {[constraint? double]} {return z}
			if {[constraint? single]} {return c}
		} else {
			if {[constraint? double]} {return d}
			if {[constraint? single]} {return s}
		}
		error {failed to contstruct the scalar type}
	}

	# Construct an execution model ID from the constraints
	proc y {} {
		if {[constraint? mpi]} {return m}
		if {[constraint-any? openmp thread]} {return t}
		if {[constraint? hybrid]} {return h}
		return s
	}

	# Construct an build type ID from the constraints
	proc z {} {
		if {[constraint? debug]} {return g}
		return o
	}

	# Construct a 3-letter build code from the constraints
	proc xyz {} {
		 return [x][y][z]
	}

	proc constraint-any? {args} {
		foreach ct $args {
			if {[constraint? $ct]} {return 1}
		}
		return 0
	}

	proc constraint-all? {args} {
		foreach ct $args {
			if {![constraint? $ct]} {return 0}
		}
		return 1
	}

	proc constraint? {ct} {
		variable constraints
		expr {[lsearch $constraints $ct] >= 0}
	}

	# Test failure is triggered by throwing an exception
	::tcltest::customMatch exception {return 1; #}

	#
	proc test {cts script} {
		variable compile-count 0
		variable system-count 0
		variable constraints [lsqueeze $cts]
		foreach v {cppflags cflags cxxflags fflags ldflags libs} {variable $v; catch {unset $v}}
		::tcltest::test -constraints $constraints -body $script -match exception
	}

	proc read-file {file} {
		set f [open $file r]
		try {
			return [split [read -nonewline $f] \n]
		} finally {
			close $f
		}
	}

	# Return a new list from the specified list entries squashing {} values
	proc lsqueeze {list} {
		set out [list]
		foreach x $list {
			if {$x != {}} {lappend out $x}
		}
		return $out
	}

	# Return a new list from the specified arguments squashing {} values
	proc collect {args} {
		lsqueeze $args
	}
}