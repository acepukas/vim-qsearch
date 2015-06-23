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

" BuffersList Function
" ===================

fun! BuffersList()
  let all = range(0, bufnr('$'))
  let res = []
  for b in all
    if buflisted(b)
      call add(res, bufname(b))
    endif
  endfor
  return res
endfun

let s:cmdMain = 'ag --column --nocolor --nogroup -s'
let s:wordOpt = '-w'
let s:literalOpt = '-Q'
let s:separator = '--'

fun! qsearch#search(sub)
  let l:cmd = [
    \ s:cmdMain,
    \ s:separator,
    \ shellescape(a:sub) ]
  call qsearch#runSearch(a:sub, join(l:cmd, ' '))
endfun

fun! qsearch#searchOpen(sub)
  let l:cmd = [
    \ s:cmdMain,
    \ s:separator,
    \ shellescape(a:sub),
    \ call BuffersList()]
  call qsearch#runSearch(a:sub, join(l:cmd, ' '))
endfun

fun! qsearch#searchLiteral(sub)
  let l:cmd = [
    \ s:cmdMain,
    \ s:literalOpt,
    \ s:separator,
    \ shellescape(a:sub) ]
  call qsearch#runSearch(a:sub, join(l:cmd, ' '))
endfun

fun! qsearch#searchLiteralWord(sub)
  let l:cmd = [
    \ s:cmdMain,
    \ s:wordOpt,
    \ s:literalOpt,
    \ s:separator,
    \ shellescape(a:sub) ]
  call qsearch#runSearch(a:sub, join(l:cmd, ' '))
endfun

fun! qsearch#searchLiteralOpen(sub)
  let l:cmd = [
    \ s:cmdMain,
    \ s:literalOpt,
    \ s:separator,
    \ shellescape(a:sub),
    \ call BuffersList()]
  call qsearch#runSearch(a:sub, join(l:cmd, ' '))
endfun

fun! qsearch#searchLiteralWordOpen(sub)
  let l:cmd = [
    \ s:cmdMain,
    \ s:wordOpt,
    \ s:literalOpt,
    \ s:separator,
    \ shellescape(a:sub),
    \ call BuffersList()]
  call qsearch#runSearch(a:sub, join(l:cmd, ' '))
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

fun! qsearch#runSearch(sub, cmd)

  " set error/quickfix format (corresponds 
  " to output from grep command)
  setlocal errorformat=%f:%l:%c:%m

  " echom l:searchCmdFull
  let l:result = system(a:cmd)

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

" search recursively for text entered at command prompt
command! -nargs=1 Qsearch call qsearch#searchLiteral(<q-args>)

command! -nargs=1 QsearchWord call qsearch#searchLiteralWord(<q-args>)

" search recursively for text entered at command prompt
command! -nargs=1 QsearchRegex call qsearch#search(<q-args>)

" search recursively for word under character. This command will yank the inner
" word text object and pass it to the QsearchWord search command.
nnoremap <unique> <leader>s "zyiw :exe ':QsearchWord ' . @z<cr>

" Search recursively for visually selected text using literal search.
vnoremap <unique> <leader>s "zy :exe ':Qsearch ' . @z<cr>

" restore previous line continuation settings
let &cpo = s:cpo_save
