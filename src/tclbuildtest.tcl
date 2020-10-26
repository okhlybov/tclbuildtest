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
		}

		proc gnu {} {
			common
			variable cc gcc
			variable cxx g++
			variable fc gfortran
			variable cflags_static -static
			variable ldflags_static -static
		}

		proc msys {} {
			gnu
		}

		proc msmpi {} {
			variable mpicc mpicc
			variable mpicxx mpicxx
			variable mpifort mpifort
		}

		proc mingw {} {
			gnu
			msmpi
		}
	}
	
	namespace export test packages compile run constraint?
	
	# Standard variables which are always defined
	variable variables {pc cc cxx fc mpicc mpicxx mpifort cflags cflags_static ldflags ldflags_static}

	foreach v $variables {namespace upvar environment $v $v}

	proc packages {args} {
		foreach v {pc cflags ldflags} {variable $v}
		if {[constraint? static]} {
			set pcflags --static
		} else {
			set pcflags {}
		}
		variable cflags
		variable ldflags
		lappend cflags [lindex [dict get [run $pc {*}$args --cflags $pcflags] stdout] 0]
		lappend ldflags [lindex [dict get [run $pc {*}$args --libs $pcflags] stdout] 0]
		return {}
	}

	proc run {args} {
		set args [lsqueeze $args]
		set command [join $args]
		try {
			exec -- {*}$args > stdout 2> stderr
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
}