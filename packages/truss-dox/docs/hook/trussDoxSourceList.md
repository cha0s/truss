*Provide sources for documentation processing.*

This hook allows packages to define source files that will be processed into
markdown during the documentation build process.

**NOTE**: All paths are relative from the directory containing
[`Gruntfile.coffee`](source/Gruntfile).

<h3>Implementations must return</h3>

An array of [glob patterns](guide/concepts#glob-patterns).
