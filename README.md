Qsearch
=======

Qsearch is a simple plugin which uses [The Silver Searcher](https://github.com/ggreer/the_silver_searcher) to make
searching files for text recursively (below the current working
directory) "quicker". Quicker, at least than the built in :vimgrep
command. This search is **not regex capable, yet**. For regex searches,
use the built in :vimgrep for now.

Results of searches are loaded into the quickfix list along with
some feedback displaying number of results found. The quickfix
window is opened automatically. Just scroll to the file you would
like to open and hit enter. The buffer will load into the current
buffer window if empty, or a new tab otherwise.

Mappings
--------

The basic idea is to be able to search a codebase based on the current
"word" under the cursor.

You can extend this by selecting text visually and issuing the search
command key combination while in visual mode.

This does not work linewise or blockwise visual selection.

Mapping:

    <leader>s

**TODO**: Allow for customization of search command key mapping.

Lastly, you can issue a search from the command line with

Mapping:

    :Qsearch {query}

Configuration
-------------

If you want certain files and directories ignored, add them to the .agignore
file in the root of your source tree.
