# Template {all.tcl} file which is to be put into each test module's directory.
# By default, this file tries to load the system-wide TclBuildTest package.
# In case of need for test-supplied version of the package, either [source]
# the bundled {tclbuildtest.tcl} to force load the specific code or
# alter the $auto_path list to add location of {pkgIndex.tcl,tclbuildtest.tcl}.
# The same scheme is also to be applied to all .test files.
package require tclbuildtest
::tclbuildtest::suite {*}$::argv