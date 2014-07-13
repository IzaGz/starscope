Database Format
===============

The StarScope database format has gone through a couple of iterations over the
last year, but the current one is pretty nice and I don't see it changing again
in the near future. We magically read old formats and convert them, so we only
document the current version here.

The basic format of the database is [gzipped](https://en.wikipedia.org/wiki/Gzip)
text. Gzip is a common compression algorithm; most languages include support for
it by default, and it is readable on effectively every platform. Underneath the
compression, the file has three lines:
 * version number
 * metadata
 * databases

Version Number
--------------

This is just the ascii character '5'. If the format changes signficantly, it
will be increased, but that is unlikely.

Metadata
--------

This is a [JSON](https://en.wikipedia.org/wiki/Json) object. Keys include:
 * `:paths` - the paths containing the files to scan
 * `:excludes` - the paths and patterns to exclude from scanning
 * `:files` - the files previously scanned (including things like last-modified
   time)
 * `:version` - The StarScope version which wrote the database (not the same as
   the database format version).

Databases
---------

This is also a [JSON](https://en.wikipedia.org/wiki/Json) object. The keys are
table names, and the values are the tables themselves. Each table is an array of
records, and each record is itself a JSON object. The only keys that are
guaranteed are `:file` (the file the record is from) and `:name` an array
containing the individual components of the fully-scoped name.
