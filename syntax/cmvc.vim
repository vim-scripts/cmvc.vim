" Vim syntax file
" Language:	CMVC
" Maintainer:	Dan Sharp <dwsharp at hotmail dot com>
" Last Change:	Thu, 01 Mar 2002 17:30:00 Eastern Standard Time

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore

syn keyword cmvcKeyword assignDate responseDate originLogin originName nuVersionSID
syn keyword cmvcKeyword originArea remoteFamily answer releaseName nuPathName nuAddDate
syn keyword cmvcKeyword scode disttype nuDropDate ownerArea ownerName ownerLogin
syn keyword cmvcKeyword compName versionSID lastUpdate addDate dropDate
syn match cmvcMatchedKeyword "^\(compName\|addDate\|lastUpdate\|endDate\|ownerLogin\)\s"
syn match cmvcMatchedKeyword "^\(ownerName\|ownerArea\|remoteName\|phaseFound\)\s"
syn match cmvcMatchedKeyword "^\(prefix\|name\|reference\|duplicate\|translation\)\s"
syn match cmvcMatchedKeyword "^\(severity\|age\|level\|symptom\|priority\|target\)\s"
syn match cmvcMatchedKeyword "^\(pathName\|baseName\|userLogin\|file mode\|codepage\)\s"
syn match cmvcMatchedKeyword "^\(type\|actual\|userName\|userArea\|baseLevel\|envName\)\s"
syn match cmvcMatchedKeyword "^\(release\|abstract\|phaseInject\|state\)\s"
syn match cmvcMatchedKeyword "\s\s\+file type\s\s\+"

syn match cmvcLabel "^\<[^:0-9"]\+:"

syn match cmvcHeader "^\s\+type\s\+state\s\+addDate\s\+lastUpdate\s\+userLogin\s\+duplicate\s*$"
syn match cmvcHeader "^\s\+addDate\s\+action\s\+userLogin (userName)\s*$"
syn match cmvcHeader "^\s\+versionSID\s\+userLogin\s\+name\s\+type\s\+abstract\s*$"
syn match cmvcHeader "^\s\+user\s\+date\s\+SID\s\+transState\s\+wordCount\s\+newWordCount\s\+eeaWordCount\s\+clarity\s\+inserted\s\+deleted\s\+unchange\s*$"
syn match cmvcHeader "^\s\+releaseName\s\+state\s\+addDate\s\+lastUpdate\s\+target\s*$"
syn match cmvcHeader "^\s\+state\s\+action\s\+userLogin\s\+addDate\s*$"
syn match cmvcHeader "^\s\+levelName\s*$"
syn match cmvcHeader "^\s\+type\s\+SID\s\+pathName\s*$"

syn match cmvcAbstract "^abstract\s\+.\+$" contains=cmvcMatchedKeyword

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
  HiLink cmvcMatchedKeyword	cmvcLabel
  HiLink cmvcHeader		String
  HiLink cmvcAbstract		Statement
  HiLink cmvcNote		Comment

  delcommand HiLink
endif

let b:current_syntax = "cmvc"

"vim: ts=8
