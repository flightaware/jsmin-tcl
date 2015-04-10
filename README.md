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

**NOTE**:
JSMin-Tcl handles the + and - operators slightly differently than Crockford's JSMin.

JSMin-Tcl removes whitespace surrounding + and - operators unless doing so would place
several of them together.

The original JSMin does this too, except in a few cases demonstrated below.
```javascript
var a = 1 / +b;
var foo = "bar"
  + "baz";
var foo2 = "bar" +
  "baz";
```

After minification JSMin-Tcl yields:
```javascript
var a=1/+b;var foo="bar"+"baz";var foo2="bar"+"baz";
```

However, JSMin yields:
```javascript
var a=1/ +b;var foo="bar"
+"baz";var foo2="bar"+"baz";
```

Both are valid JavaScript but JSMin-Tcl yields a smaller filesize.

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
```
package require jsmin

set in [::tcl::chan::string $js]
set out [::tcl::chan::variable outstring]
jsmin::minify $in $out
```
