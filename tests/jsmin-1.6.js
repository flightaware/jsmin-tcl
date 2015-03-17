var foo = /^.*some  regex+$/;
var a = "foo bar";
console.log(a.replace(/foo /g, "bar"));
var bar = /d(b+) d/g.exec("cdbb dbsbz");
console.log("text " + /d(b+) d/g.lastIndex);
if (true && /d(b+) d/g.exec("cdbb dbsbz")) break;
var baz = {"a": /r+ e+  gex/};
var arg = true &&
    /^\[a (b)\]$/.test();
