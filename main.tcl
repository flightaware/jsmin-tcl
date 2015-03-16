lappend auto_path "."
package require tcltest
package require jsmin

namespace import ::tcltest::*

test jsmin-1.1 {
	Should remove newlines and spaces
} -body {
	set fp [open "tests/jsmin-1.1.js"]
	jsmin::minify $fp stdout
	close $fp
} -output "var a=4;var b=5;"

test jsmin-1.2 {
	Should remove comments
} -body {
	set fp [open "tests/jsmin-1.2.js"]
	jsmin::minify $fp stdout
	close $fp
} -output "var a=4;var b=5;function foo(){return 1;}"

test jsmin-1.3 {
	Should remove comments between closing curly braces
} -body {
	set fp [open "tests/jsmin-1.3.js"]
	jsmin::minify $fp stdout
	close $fp
} -output "function(){if(true){if(true){var a=0;}}}"

test jsmin-1.4 {
	Should remove whitespace around math operators
} -body {
	set fp [open "tests/jsmin-1.4.js"]
	jsmin::minify $fp stdout
	close $fp
} -output "var a=2/3;var b=a/12;var c=b/a/b/2*1+2/4-b%3;"

cleanupTests
