#
# Tcltest extenstion to test source code compilation & running
#
# https://github.com/okhlybov/tclbuildtest
#

package provide tclbuildtest 0.1

package require Tcl 8.6
package require tcltest

namespace eval ::tclbuildtest {
	
	namespace eval environment {
		
		namespace export setup auto gnu msys mingw

		# Return name of the proc currently executed
		proc current {} {
			return [namespace tail [dict get [info frame [expr {[info frame]-1}]] proc]]
		}

		proc auto {} {
			try {
				switch -glob $::env(MSYSTEM) {
					MSYS {msys}
					MINGW* {mingw}
					default {error}
				}
			} on error {} {
				gnu
			}
		}

		proc common {} {
			variable pc pkg-config
			variable compile-count 0
		}

		proc gnu {} {
			common
			variable cc gcc
			variable cxx g++
			variable fc gfortran
			variable cflags {}
			variable ldflags {}
			variable cflags_static -static
			variable cflags_openmp -fopenmp
			variable ldflags_static -static
			variable ldflags_openmp -fopenmp
			variable environment [current]
		}

		# proc cygwin

		proc msys {} {
			gnu
			variable environment [current]
		}

		proc msmpi {} {
			variable mpicc mpicc
			variable mpicxx mpicxx
			variable mpifc mpifort
			variable cflags_mpi {}
			variable ldflags_mpi {}
		}

		proc mingw {} {
			gnu
			msmpi
			variable environment [current]
		}
	}
	
	namespace export test packages compile run constraint?
	
	# Standard variables which are always defined
	variable variables {
		pc cc cxx fc mpicc mpicxx mpifc
		compile-count
		cflags cflags_static cflags_mpi cflags_openmp ldflags ldflags_static ldflags_mpi ldflags_openmp
	}

	foreach v $variables {namespace upvar environment $v $v}

	proc packages {args} {
		foreach v {pc cflags ldflags} {variable $v}
		if {[constraint? static]} {set pcf --static} else {set pcf {}}
		lappend cflags [lindex [dict get [run $pc {*}$args --cflags $pcf] stdout] 0]
		lappend ldflags [lindex [dict get [run $pc {*}$args --libs $pcf] stdout] 0]
		return
	}

	proc deduce-language {args} {
		switch -regexp -nocase [lindex $args [lsearch -glob -not $args {-*}]] {
			{\.c$} {return c}
			{\.(cxx|cpp|cc)$} {return c++}
			{\.(f|for|f\d+)$} {return fortran}
			default {error {failed to deduce source language from the command line agruments}}
		}
	}

	proc deduce-compiler {args} {
		set lang [deduce-language {*}$args]
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

	proc compiler {args} {
		foreach v {cc cxx fc mpicc mpicxx mpifc} {variable $v}
		return [subst $[deduce-compiler {*}$args]]
	}

	proc compile {args} {
		foreach v {
			compile-count
			cflags cflags_static cflags_mpi cflags_openmp ldflags ldflags_static ldflags_mpi ldflags_openmp
		} {variable $v}
		set cf $cflags
		set lf $ldflags
		if {[constraint? static]} {
			set cf [concat $cf $cflags_static]
			set lf [concat $lf $ldflags_static]
		}
		if {[constraint? mpi]} {
			set cf [concat $cf $cflags_mpi]
			set lf [concat $lf $ldflags_mpi]
		}
		if {[constraint? openmp]} {
			set cf [concat $cf $cflags_openmp]
			set lf [concat $lf $ldflags_openmp]
		}
		run {*}[concat [compiler {*}$args] -o [set prog "test[incr compile-count]"] $cf $args $lf]
		return $prog
	}

	proc run {args} {
		set args [lsqueeze $args]
		set command [join $args]
		try {
			exec -ignorestderr -- {*}$args > stdout 2> stderr
			set options {}
			set status 0
			set code ok
		} trap CHILDSTATUS {results options} {
			set status [lindex [dict get $options -errorcode] 2]
			set code error
		} finally {
			try {
				set stdout [read-file stdout]
				set stderr [read-file stderr]
			} finally {
				file delete -force stdout stderr
			}
		}
		return -code $code [dict create command $command status $status stdout $stdout stderr $stderr options $options]
	}

	proc constraint? {ct} {
		variable constraints
		expr {[lsearch $constraints $ct] >= 0}
	}

	proc test {cts env script} {
		variable variables; foreach v $variables {variable $v}
		variable constraints [lsqueeze $cts]
		namespace eval environment $env
		eval $script
	}

	proc read-file {file} {
		set f [open $file r]
		try {
			return [split [read -nonewline $f] \n]
		} finally {
			close $f
		}
	}

	proc lsqueeze {list} {
		set out [list]
		foreach x $list {
			if {$x != {}} {lappend out $x}
		}
		return $out
	}
}