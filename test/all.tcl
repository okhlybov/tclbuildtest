# Template {all.tcl} file which is to be put into each test module's directory
lappend auto_path [file join [file dirname [file normalize [info script]]] ..]
package require tclbuildtest
::tclbuildtest::suite {*}$argv