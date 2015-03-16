lappend auto_path "."
package require jsmin

jsmin::minify "script.js" "script.min.js"
