" Vim syntax file
" Language:	CMVC
" Maintainer:	Dan Sharp <dwsharp@hotmail.com>
" Last Change:	Thu, 14 Feb 2002 21:37:03 Eastern Standard Time

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore

syn keyword cmvcKeyword assignDate responseDate originLogin originName 
syn keyword cmvcKeyword originArea remoteFamily answer
syn match cmvcKeyword "^\(compName\|envName\|addDate\|lastUpdate\|endDate\|ownerLogin\)"
syn match cmvcKeyword "^\(ownerName\|ownerArea\|remoteName\|phaseFound\|phaseInject\)"
syn match cmvcKeyword "^\(prefix\|name\|reference\|duplicate\|state\)"
syn match cmvcKeyword "^\(severity\|age\|level\|symptom\|priority\|target\|release\)"

syn match cmvcLabel "^\w\+\(\s\+\w\+\)\=:"

syn match cmvcHeader "^\s\+type\s\+state\s\+addDate\s\+lastUpdate\s\+userLogin\s\+duplicate\s*$"
syn match cmvcHeader "^\s\+addDate\s\+action\s\+userLogin (userName)\s*$"

syn match cmvcAbstractKeyword contained "^abstract"
syn match cmvcAbstract "abstract\s\+.\+$" contains=cmvcAbstractKeyword

syn region cmvcNote start="\s\+<Note" end=">\s*$"

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_cmvc_syn_inits")
  if version < 508
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  let did_cmvc_syn_inits = 1

  HiLink cmvcLabel		Function
  HiLink cmvcKeyword		cmvcLabel
  HiLink cmvcAbstractKeyword	cmvcLabel
  HiLink cmvcHeader		String
  HiLink cmvcAbstract		Statement
  HiLink cmvcNote		Comment

  delcommand HiLink
endif

let b:current_syntax = "cmvc"

"vim: ts=8
