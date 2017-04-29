*Define middleware to run when the server application is bootstrapping.*

This hook is where most of the major initialization work happens on the
server. You use this to spin up HTTP/sockets/database/whatever.

<h3>Implementations must return</h3>

A
[middleware hook specification](guide/concepts/#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(next) {
  ...
}
```
