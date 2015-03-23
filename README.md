JSMin-Tcl
=========
JSMin-Tcl is a JavaScript minifier written in Tcl. Although inspired by Douglas Crockford's C-based JSMin, it has its own implementation and is **not** simply port. The behavior should be identical to Crockford's JSMin except as described below.

Behavior
--------
JSMin-Tcl removes all unnecessary whitespace from Javascript source code.
It will not rename your variables to shorter names, or "name mangle".

For example:

```
var foo = "bar";
function example(arg0, arg1) {
    console.log("example");
}
```

After minification becomes:
```
var foo="bar";function example(arg0,arg1){console.log("example");}
```

----------

>**NOTE**:
> JSMin-Tcl handles the + and - operators slightly differently than Crockford's JSMin.
>
> JSMin-Tcl removes whitespace surrounding + and - operators unless doing so would place
> several of them together.
>
> The original JSMin does this too, except in a few cases demonstrated below.
> ```
> var a = 1 / +b;
> var foo = "bar"
>   + "baz";
> var foo2 = "bar" +
>   "baz";
> ```
>
> After minification JSMin-Tcl yields:
> ```
> var a=1/+b;var foo="bar"+"baz";var foo2="bar"+"baz";
> ```
>
> However, JSMin yields:
> ```
> var a=1/ +b;var foo="bar"
> +"baz";var foo2="bar"+"baz";
> ```
>
> Both are valid JavaScript but JSMin-Tcl yields a smaller filesize.

Usage
-----
The main proc in JSMin-Tcl is called "minify".can be used as follows:
**Be sure to retain your original source file.**

```
package require jsmin

set fp [open "exampleFile.js"]
jsmin::minify $fp stdout
close $fp
```
