This page explains various concepts and conventions used in Truss.

# Middleware hook specification

Truss invokes various hooks
([`trussServerBootstrapMiddleware`](../hooks#trussserverbootstrapmiddleware),
and more...) which allow packages to define middleware to be dispatched during
various processes.

Middleware hooks return a specification that looks like:

```javascript
{
  label: 'What the middleware functions do',
  middleware: [

    function(args..., next) {

      // Do stuff with args...
      next();
    },

    function(args..., next) {

      // Do stuff with args...
      next();
    }
  ]
}
```

The `label` exists only to provide debugging information so you can see if any
of your middleware are having problems by checking the debug console logs.

The `middleware` are applied serially, meaning the first function in the array
is dispatched first, followed by the second, etc.

See the
[middleware module](../source/src/middleware#defining-middleware)
for even more information about defining middleware.

# Glob patterns

Truss uses glob patterns to define path specifications for various purposes
(see:
[`trussDoxSourceList`](../source/packages/truss-dox#implements-hook-trussdoxsourcelist)'s
implementation for instance). Glob patterns can be as simple as e.g. `*.html`
to match all HTML files.

Read more about glob patterns and how they are used by `node-glob` &mdash; the
module providing this API to Truss &mdash; here:
[https://github.com/isaacs/node-glob#glob-primer](https://github.com/isaacs/node-glob#glob-primer)
