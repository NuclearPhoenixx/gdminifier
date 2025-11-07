# Minifier Plugin for Godot 4.x

This is a very basic minifier plugin for Godot 4. From looking around I found some files where manual "minification" on a production/release export would yield some results. It should not break any exports since it only removes safe whitespace and comments.

Be aware, though, that this script only minifies by a tiny fraction (YMMV). Mainly I wanted to do this, because why not, and also to strip comments and newlines from `.gdshader` files (since comments from `.gd` files are stripped by Godot itself fortunately).

## Features

- Minifies all `.json` files by removing all applicable whitespace.
- Minifies all `.gdshader` files by removing all comments, empty lines and newlines.
- Minifies all `.tres` files by removing empty lines.

## Broken Stuff

- Minifying `.gd` files: Since they're exported as `.gdc` in a compressed format, it's not that trivial to minify. It would be awesome to have some function in the future that strips all newlines and empty lines from those files.
- Minifying `.tscn` files by stripping empty lines analog to `.tres`, but for whatever reason, the exported game size increases after this.
- Minifying `.import` files: same as above, but removing empty lines analog to `.tres` files completely broke the export.

## Future Improvements

- Potentially add minifying to custom function and variable names in `.gdshader` and `.gd` files (could also be used as obfuscation).
- Maybe add other custom files, such as `.xml`.
 
