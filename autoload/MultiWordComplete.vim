" MultiWordComplete.vim Insert mode completion that completes a sequence of
" words based on anchor characters for each word.
"
" DEPENDENCIES:
"   - CompleteHelper.vim autoload script
"   - CompleteHelper/Repeat.vim autoload script
"
" Copyright: (C) 2010-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.010	30-Jul-2013	Initialize s:repeatCnt because it not only
"				caused errors in the tests, but also when used
"				in AutoComplPop.
"	009	15-Jul-2013	Add support for repeat of completion.
"	008	15-Jul-2013	Don't accept an empty base; this will just show
"				all keyword matches and work like the built-in
"				completion.
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

function! s:GetCompleteOption()
    return (exists('b:MultiWordComplete_complete') ? b:MultiWordComplete_complete : g:MultiWordComplete_complete)
endfunction

function! s:IsAlpha( expr )
    return (a:expr =~# '^\a\+$')
endfunction
function! s:BuildRegexp( base )
    " Each alphabetic character is an anchor for the beginning of a word.
    " All other (keyword) characters must just match at that position.
    let l:anchors = map(split(a:base, '\zs'), 'escape(v:val, "\\")')

    " Assemble all regexp fragments together to build the full regexp.
    " There is a strict regexp which is tried first and a relaxed regexp to fall
    " back on.
    let l:regexpFragments = []
    let l:currentFragment = ''
    let l:i = 0
    while l:i < len(l:anchors)
	let l:anchor = l:anchors[l:i]
	let l:previousAnchor = get(l:anchors, l:i - 1, '')
	let l:nextAnchor = get(l:anchors, l:i + 1, '')

	if s:IsAlpha(l:anchor)
	    " If an anchor is alphabetic, match a word fragment that starts with
	    " the anchor.
	    if l:i > 0 && s:IsAlpha(l:previousAnchor)
		call add(l:regexpFragments, l:currentFragment)
		let l:currentFragment = ''
	    endif
	    let l:currentFragment .= l:anchor . '\k*'
	else
	    " If an anchor is a non-alphabetic character, match either a word
	    " fragment that starts with the it, or just match the it.
	    if ! empty(l:currentFragment)
		" This may (cardinality = *) be a new word fragment starting
		" with the non-letter. Because of the different cardinality, directly
		" append this here to the current fragment instead of relying on
		" the eventual joining of word fragments.
		let l:currentFragment .= '\%(\k\@!\_.\)*'
	    endif
	    if s:IsAlpha(l:nextAnchor)
		" An alphabetic anchor following a non-alphabetic one may either
		" immediately match after it (like any other non-alphabetic
		" keyword character, creating a joint anchor). Or it may
		" represent a word fragment of its own. In this case, we
		" directly append the next alphabetic anchor here instead of
		" relying on the eventual joining of word fragments.
		let l:currentFragment .= l:anchor . '\%(\k*\%(\k\@!\_.\)\+\)\?' . l:nextAnchor . '\k*'

		" The next anchor has already been processed, skip it in the
		" loop.
		let l:i += 1
	    else
		let l:currentFragment .= l:anchor . '\k*'
	    endif
	endif
	let l:i += 1
    endwhile
    if ! empty(l:currentFragment)
	call add(l:regexpFragments, l:currentFragment)
    endif

    if len(l:regexpFragments) == 0
	let l:regexpFragments = ['\k\+']
    endif

    " Anchor the entire regexp at the start of a word.
    let l:regexp = '\<' . join(l:regexpFragments, '\%(\k\@!\_.\)\+')
"****D echomsg '****' l:regexp
    return l:regexp
endfunction
let s:repeatCnt = 0
function! MultiWordComplete#MultiWordComplete( findstart, base )
    if s:repeatCnt
	if a:findstart
	    return col('.') - 1
	else
	    let l:matches = []
	    call CompleteHelper#FindMatches(l:matches, '\V\<' . escape(s:fullText, '\') . '\zs\%(\k\@!\.\)\+\k\+', {'complete': s:GetCompleteOption()})
	    return l:matches
	endif
    endif

    if a:findstart
	" Locate the start of the keyword that represents the initial letters.
	let l:startCol = searchpos('\k\+\%#', 'bn', line('.'))[1]
	if l:startCol == 0
	    return -1   " No base before the cursor; cancel the completion with an error message.
	endif

	if ! empty(g:MultiWordComplete_FindStartMark)
	    " Record the position of the start of the completion base to allow
	    " removal of the completion base if no matches were found.
	    let l:findstart = [0, line('.'), l:startCol, 0]
	    call setpos(printf("'%s", g:MultiWordComplete_FindStartMark), l:findstart)
	endif

	return l:startCol - 1 " Return byte index, not column.
    elseif ! empty(a:base)
	let l:regexp = s:BuildRegexp(a:base)
	if empty(l:regexp) | throw 'ASSERT: A regexp should have been built.' | endif

	" Find keywords matching the prepared regexp. Use a case-insensitive
	" search if there is a chance that it will yield matches (i.e. if the
	" first search wasn't case-insensitive yet).
	let l:options = {'complete': s:GetCompleteOption(), 'processor': function('CompleteHelper#JoinMultiline')}
	let l:matches = []
	call CompleteHelper#FindMatches(l:matches, l:regexp, l:options)
	if empty(l:matches) && (! &ignorecase || (&ignorecase && &smartcase && a:base =~# '\u'))
	    echohl ModeMsg
	    echo '-- User defined completion (^U^N^P) -- Case-insensitive search...'
	    echohl None
	    call CompleteHelper#FindMatches(l:matches, '\c' . l:regexp, l:options)
	endif
	let s:isNoMatches = empty(l:matches)
	return l:matches
    else
	return []
    endif
endfunction

function! MultiWordComplete#RemoveBaseKeys()
    return (s:isNoMatches && ! empty(g:MultiWordComplete_FindStartMark) ? "\<C-e>\<C-\>\<C-o>dg`" . g:MultiWordComplete_FindStartMark : '')
endfunction
function! MultiWordComplete#Expr()
    set completefunc=MultiWordComplete#MultiWordComplete

    let s:repeatCnt = 0 " Important!
    let [s:repeatCnt, l:addedText, s:fullText] = CompleteHelper#Repeat#TestForRepeat()
    return "\<C-x>\<C-u>"
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
