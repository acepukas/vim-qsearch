"
" qsearch.vim - Lets you search recursively for strings within the current file
"               system tree using ag (The Silver Searcher). You can filter by
"               file extensions and exclude directories from search.
"
"               Searching can be invoked from the <leader>s mapping in normal
"               or visual mode. Cursor must be over the word your intending to
"               search for. Rules of the search depend on whether the search was
"               initiated from visual mode or normal mode.
"
"               To manually search for a custom literal string:
"
"                 :Qsearch search term
"
"               Where the search term can be any string, including spaces.
"
"               To search using a regular expression (ag compatible):
"
"                 :QsearchRegex your regex here
"
" Author:       Aaron Cepukas
"
" Version:      1.7
"
" Release Notes:
"
"               1.7
"                 - all seaches now case sensitive
"
"               1.6
"                 - Searches initiation from normal mode with cursor over word
"                   will restrict search using word boundry.
"
"               1.5
"                 - Accounting for ag (Silver Searcher) literal mode.
"                   Can search using regular express now.
"
"               1.4:
"                 - Using The Silver Searcher instead of grep.
"
"               1.3:
"                 - using -- before positional args for the grep command.
"                 Prevents a string like "-ad-" from borking grep
"
"               1.2:
"                 - Proper escaping of double quotes for :Qsearch args
"                 (<q-args>)
"
"               1.1:
"                 - can exclude individual files AND use GLOB wildcards for
"                   exclusion
"
"               1.0:
"                 - initial version
"
" ------------------------------------------------------------------------------

" Plugin Loaded Check
" ===================

if exists("g:loaded_Qsearch") || &cp
  finish
endif
let g:loaded_Qsearch=1

" if save line continuation setting
" and restore it after script is loaded
" This is so that line continuation is supported
let s:cpo_save = &cpo
set cpo&vim

" Helper Functions
" ================

fun! qsearch#DisplayFeedback(subject, result)

  " get number of results for feedback message
  let l:numOfResults = len(split(a:result, '\n'))

  " Output feedback indicating search term and number of results found
  echom "Searched for " . a:subject . " : Found " . l:numOfResults . " result(s)."

endfun

" Search Function
" ===============

" Arguments: literal: numeric boolean used to determine if search should be
"                     literal string search or regex based.
"
"            word:    numeric boolean used to determine if search should be
"                     restricted to word boundries or not.
"
"            sub:     string subject of search.

fun! qsearch#Search(literal, word, sub)

  " set error/quickfix format (corresponds 
  " to output from grep command)
  setlocal errorformat=%f:%l:%c:%m

  " construct grep command from needed components
  let l:searchCmd = []
  call add(l:searchCmd, 'ag --column --nocolor --nogroup')

  " case sensitive searching
  call add(l:searchCmd, '-s')

  " -w flag is for word boundry
  if a:word
    call add(l:searchCmd, '-w')
  endif

  " -Q flag means the search will be a literal string search and not regex
  "  based
  if a:literal
    call add(l:searchCmd, '-Q')
  endif

  " THIS CLI OPTION MUST BE THE LAST OPTION!
  " double dash prevents a string like "-ad-"
  " being interperated as an option argument.
  call add(l:searchCmd, '--')

  call add(l:searchCmd, shellescape(a:sub))

  " capture results of grep command
  let l:searchCmdFull = join(l:searchCmd, ' ')

  " echom l:searchCmdFull
  let l:result = system(l:searchCmdFull)

  " give feed back about search and results
  call qsearch#DisplayFeedback(a:sub, l:result)

  " populate quickfix list with output from grep 
  " command but don't jump to first error/item
  cgetexpr l:result

  " open quick fix list
  copen

endfun

" Key Commands
" ============

" These commands are used to initiate the search function
" in different ways depending on the context.

" search recursively for word under character.
" This command will yank the inner word text object
" and pass it to the QsearchSearch search function.
nnoremap <unique> <leader>s "zyiw :call qsearch#Search(1, 1, @z)<cr>

" search recursively for visually selected text
vnoremap <unique> <leader>s "zy :call qsearch#Search(1, 0, @z)<cr>

" search recursively for text entered at command prompt
command! -nargs=1 Qsearch call qsearch#Search(1, 0, <q-args>)

" search recursively for text entered at command prompt
command! -nargs=1 QsearchRegex call qsearch#Search(0, 0, <q-args>)

" restore previous line continuation settings
let &cpo = s:cpo_save
