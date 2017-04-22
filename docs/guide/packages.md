<h1>Package system</h1>

Truss is organized into packages which implement hooks.

A package is essentially a node.js module. Exporting a `pkgmanRegister`
function allows Truss to register your package in its package manager. This is
how you can implement hooks, allowing you to augment, modify, and even define
your application's behavior.

The simplest example of a package would be something like:

```javascript
exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('trussPreBootstrap', function() {
    console.log('I hooked into Truss!');
  });
};
```

This package simply hooks into the
[`trussPreBootstrap`](../hooks#trussprebootstrap) hook and logs
a message to the console when that hook is invoked. Obviously this particular
package isn't super useful!

Hooks are how Truss allows packages to implement (or invoke) dynamic behavior.
Hooks can also serve as a form of message passing between packages.

To implement a hook, export a `pkgmanRegister` method which takes a `registrar`
argument, and use the registrar to register your hook:

```javascript
exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('someHook', function() {
    doStuff();
  });

  registrar.registerHook('someOtherHook', function(arg) {
    doOtherStuffWith(arg);
  });
};
```

To invoke a hook, require `pkgman` and use the `invoke` method:

```javascript
var pkgman = require('pkgman');

var results = pkgman.invoke('someOtherHook', arg);
```

Any arguments following the hook name will be passed along to the
implementations. Hooks are invoked synchronously. For more information about
`pkgman`, see [the pkgman documentation](../source/src/pkgman/).
