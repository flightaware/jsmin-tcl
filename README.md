JSMin-Tcl
=========
JSMin-Tcl is a JavaScript minifier written in Tcl. Although inspired by Douglas Crockford's C-based JSMin, it has its own implementation and is **not** simply port. The behavior should be identical to Crockford's JSMin except as described below.

Behavior
--------
JSMin-Tcl removes all unnecessary whitespace from Javascript source code.
It will not rename your variables to shorter names, or "name mangle".

For example:

```javascript
var foo = "bar";
function example(arg0, arg1) {
    console.log("example");
}
```

After minification becomes:
```javascript
var foo="bar";function example(arg0,arg1){console.log("example");}
```

Usage
-----
Minification is done using the "minify" proc in JSMin-Tcl. **Be sure to retain your original source file. Minification cannot be undone.**
```tcl
jsmin::minify inputChannel outputChannel
```

Example:

```tcl
package require jsmin

set fp [open "exampleFile.js"]
jsmin::minify $fp stdout
close $fp
```

If you want to directly pass a string of JavaScript and store the result in a variable you can do so like this:
```tcl
package require jsmin

set in [::tcl::chan::string $js]
set out [::tcl::chan::variable outstring]
jsmin::minify $in $out
```
