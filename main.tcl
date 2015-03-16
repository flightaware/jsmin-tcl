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
} -output {var a=4;var b=5;var c=true&&(b>a);}

test jsmin-1.2 {
	Should remove comments
} -body {
	set fp [open "tests/jsmin-1.2.js"]
	jsmin::minify $fp stdout
	close $fp
} -output {var a=4;var b=5;function foo(){return 1;}}

test jsmin-1.3 {
	Should remove comments between curly braces
} -body {
	set fp [open "tests/jsmin-1.3.js"]
	jsmin::minify $fp stdout
	close $fp
} -output {function(){if(true){if(true){var a=0;}}}
var foo=[{"a":"b"},{"c":"d"}];}

test jsmin-1.4 {
	Should remove whitespace around math operators
} -body {
	set fp [open "tests/jsmin-1.4.js"]
	jsmin::minify $fp stdout
	close $fp
} -output "var a=2/3;var b=a/12;var c=b/a/b/2*1+2/4-b%3;"

test jsmin-1.5 {
	Should ignore whitespace inside quotes
} -body {
	set fp [open "tests/jsmin-1.5.js"]
	jsmin::minify $fp stdout
	close $fp
} -output {var a="foo   bar";var b=' foo baz  ';var c=" nested 'quotes foo'";var d=' nested "quotes foo"';var e=" nested \"quotes foo\"";var foo=' nested \'quotes foo\'';}

test jsmin-1.6 {
	Should ignore regular expressions
} -body {
	set fp [open "tests/jsmin-1.6.js"]
	jsmin::minify $fp stdout
	close $fp
} -output {var foo=/^.*some  regex+$/;var a="foo bar";console.log(a.replace(/foo /g,"bar"));var bar=/d(b+) d/g.exec("cdbb dbsbz");console.log("text "+/d(b+) d/g.lastIndex);if(true&&/d(b+) d/g.exec("cdbb dbsbz"))break;var baz={"a":/r+ e+  gex/};}

test jsmin-1.7 {
	Should remove whitespace between letters and an open quote.
} -body {
	set fp [open "tests/jsmin-1.7.js"]
	jsmin::minify $fp stdout
	close $fp
} -output {function foo(){return"bar";}}

test jsmin-1.8 {
	Should keep newlines if no semicolon present
} -body {
	set fp [open "tests/jsmin-1.8.js"]
	jsmin::minify $fp stdout
	close $fp
} -output {var a=4
var b=5}

cleanupTests
