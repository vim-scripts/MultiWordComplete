" MultiWordComplete.vim Insert mode completion that completes a sequence of
" words based on anchor characters for each word.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - MultiWordComplete.vim autoload script
"
" Copyright: (C) 2010-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.008	03-Sep-2012	Add value "b" (other listed buffers) to the
"				plugin's 'complete' option offered by
"				CompleteHelper.vim 1.20.
"	007	20-Aug-2012	Split off functions into separate autoload
"				script and documentation into dedicated help
"				file.
"	006	19-Oct-2011	Add CompleteHelper#JoinMultiline() processor
"				option after the flattening of newlines has been
"				removed from the default processing in
"				CompleteHelper. We do not want to keep newlines
"				in the completion results, as this completion is
"				about sequences of words.
"	005	30-Sep-2011	Use <silent>.
"				Comment out debugging info.
"	004	04-Mar-2010	Implemented optional setting of a mark at the
"				findstart position. If this is done, the
"				completion base is automatically removed if no
"				matches were found: As the base just consists of
"				a sequence of anchor characters, it isn't
"				helpful for further editing when the completion
"				failed. (Taken from CamelCaseComplete.vim.)
"	003	04-Mar-2010	Treating non-alphabetic keyword anchors like
"				numbers.
"	002	03-Mar-2010	Added special handling of numbers.
"	001	26-Feb-2010	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_MultiWordComplete') || (v:version < 700)
    finish
endif
let g:loaded_MultiWordComplete = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:MultiWordComplete_complete')
    let g:MultiWordComplete_complete = '.,w,b'
endif
if ! exists('g:MultiWordComplete_FindStartMark')
    " To avoid clobbering user-set marks, we use the obscure "last exit point of
    " buffer" mark.
    " Setting of mark '" is only supported since Vim 7.2; use last jump mark ''
    " for Vim 7.0 and 7.1.
    let g:MultiWordComplete_FindStartMark = (v:version < 702 ? "'" : '"')
endif


"- mappings --------------------------------------------------------------------

inoremap <silent> <Plug>(MultiWordPostComplete) <C-r>=MultiWordComplete#RemoveBaseKeys()<CR>
inoremap <silent> <expr> <Plug>(MultiWordComplete) MultiWordComplete#Expr()
if ! hasmapto('<Plug>(MultiWordComplete)', 'i')
    imap <C-x>w <Plug>(MultiWordComplete)
    execute 'imap <C-x>w <Plug>(MultiWordComplete)' . (empty(g:MultiWordComplete_FindStartMark) ? '' : '<Plug>(MultiWordPostComplete)')
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
