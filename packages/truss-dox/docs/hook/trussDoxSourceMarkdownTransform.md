*Provide Transform implementations to convert sources to markdown.*

This hook allows packages to define `Transform`s that will process sources into
markdown during the documentation build process. A `Transform` is a subclass
of
[`stream.Transform`](https://nodejs.org/api/stream.html#stream_class_stream_transform).

<h3>Implementations must return</h3>

An object containing the following keys:

* `extensions`: A String Array of file extensions this `Transform` operates on
  e.g. `['coffee', 'yml']`.
* `Transform`: A subclassed
  [`stream.Transform`](https://nodejs.org/api/stream.html#stream_class_stream_transform)
  whose constructor is passed two arguments:
    * `processor`: The
      [`SourcesProcessor`](source/packages/truss-dox/dynamic/processor/sources)
      operating on the source.
    * `stream`: The source file
      [`stream`](https://nodejs.org/api/stream.html#stream_stream).
