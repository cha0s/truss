*Define assets to serve to the client application.*

Packages may come bundled with JavaScript or CSS assets. This hook is how you
can provide them to the client application.

Asset middleware takes `assets` as its first argument. This is an object with
the following properties:

* ((Object or String) Array) `scripts` - A list of script assets.
* ((Object or String) Array) `stylesheets` - A list of sylesheet assets.

Scripts and stylesheets may be specified in object form:

* `type`: Either `remote` or `inline`.
* `data`: If `type` is `remote`, then the `src`/`href` URL to find the
  script/style sheet (respectively). If `type` is `inline`, then the actual
  script/style sheet content.

If a script or style sheet is specified as a string, then it is normalized
to object form. `type` is assumed to be `remote`, and the string value becomes
the value of `data` in the object.

**NOTE**: This hook lets you serve assets, but will not automatically copy
them from your package to the `frontend` directory where they will be served.
You'll need to implement the
[`trussServerGruntConfig`](hooks/#trussservergruntconfig) hook for that.

<h3>Implementations must return</h3>

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(req, assets, next) {
  ...
}
```
