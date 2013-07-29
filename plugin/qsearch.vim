"
" qsearch.vim -   Lets you search recursively for strings within the current file
"               system tree using GNU grep. You can filter by file extensions 
"               and exclude directories from search.
"
"               Searching can be invoked from the <leader>s combination. Rules
"               of the search depend on whether the search was initiated from 
"               visual mode or normal mode.
"
"               Also, the search can be initiated via the custom command :Vim
"               
"                 :Vim searchTerm
"
"               Where the search term can be any string, including spaces.
"               
"               Currently this does not support regular expression searching.
"
" Author:       Aaron Cepukas
"
" Version:      1.3
"
" Release Notes:
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

" RegexEscape will escape strings that are to be searched
" against within a regex, preventing characters with special
" meaning from interfering with the search
fun! qsearch#RegexEscape(sub)

  let l:sub = substitute(a:sub,"\\.","\\\\.",'g')
  let l:sub = substitute(l:sub,"\[","\\\\[",'g')
  let l:sub = substitute(l:sub,"\n","\\n",'g')
  let l:sub = substitute(l:sub,"\/","\\\\/",'g')
  let l:sub = substitute(l:sub,"\*","\\\\*",'g')

  return l:sub

endfun

fun! qsearch#FormatSubject(mode,sub)

  " escape any regex chars with special meaning
  let l:subject = qsearch#RegexEscape(a:sub)

  " if the search was done with the cursor over a word
  " which in normal mode, we want to set word boundaries
  " on either side of the word
  if a:mode ==# 'normal'
    let l:subject = '\b' . l:subject . '\b'
  elseif a:mode ==# 'visual'
    let l:subject = l:subject
  endif

  " shellescape subject for use in bash/zsh/etc shell
  let l:subject = shellescape(l:subject)

  return l:subject

endfun

fun! qsearch#GetIncludeFileTypes()

  if !exists("g:QsearchIncludeFileTypes")
    return ''
  endif

  " string used for building include string
  let l:incTemplate = '"--include=\"*.".v:val."\""'

  " format included file types list for grep command
  let l:fileTypesList = split(g:QsearchIncludeFileTypes)
  let l:fileTypesList = map(l:fileTypesList,l:incTemplate)
  let l:fileTypes = join(l:fileTypesList,' ')

  return l:fileTypes

endfun

fun! qsearch#GetExcludeFiles()

  if !exists("g:QsearchExcludeFiles")
    return ''
  endif

  " string used for building include string
  let l:incTemplate = '"--exclude=\"".v:val."\""'

  " format included file types list for grep command
  let l:filesList = split(g:QsearchExcludeFiles)
  let l:filesList = map(l:filesList,l:incTemplate)
  let l:filesStr = join(l:filesList,' ')

  return l:filesStr

endfun

fun! qsearch#GetExcludeDirs()

  if !exists("g:QsearchExcludeDirs")
    return ''
  endif

  " format excluded directories list for grep command
  let l:dirs = substitute(g:QsearchExcludeDirs,' ',',','g')
  let l:dirs = '--exclude-dir={'.l:dirs.'}'

  return l:dirs

endfun

fun! qsearch#DisplayFeedback(subject,result)

  " get number of results for feedback message
  let l:numOfResults = len(split(a:result,'\n'))

  " Output feedback indicating search term and number of results found
  echom "Searched for " . a:subject . " : Found " . l:numOfResults . " result(s)."

endfun

" Search Function
" ===============

fun! qsearch#Search(mode,sub)

  " set error/quickfix format (corresponds 
  " to output from grep command)
  setlocal errorformat=%f:%l:%m

  " construct grep command from needed components
  let l:grepCmd = []
  call add(l:grepCmd,'grep -Rn')
  call add(l:grepCmd,qsearch#GetIncludeFileTypes())
  call add(l:grepCmd,qsearch#GetExcludeFiles())
  call add(l:grepCmd,qsearch#GetExcludeDirs())

  " double dash prevents a string like "-ad-"
  " being interperated as an option argument
  call add(l:grepCmd,'--')

  call add(l:grepCmd,qsearch#FormatSubject(a:mode,a:sub))
  call add(l:grepCmd,'.')

  " capture results of grep command
  let l:grepCmdFull = join(l:grepCmd,' ')

  " echom l:grepCmdFull
  let l:result = system(l:grepCmdFull)

  " give feed back about search and results
  call qsearch#DisplayFeedback(a:sub,l:result)
  
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
" and pass it to the QsearchSearch search function along
" with the mode that the command was invoked from.
nnoremap <unique> <leader>s "zyiw :call qsearch#Search("normal",@z)<cr>

" search recursively for visually selected text
vnoremap <unique> <leader>s "zy :call qsearch#Search("visual",@z)<cr>

" search recursively for text entered at command prompt
command! -nargs=1 Qsearch call qsearch#Search("visual", <q-args>)

" restore previous line continuation settings
let &cpo = s:cpo_save
