" File:		CMVC.vim (global plugin)
" Last Change:	Mon, 01 Apr 2002 15:53:25 Eastern Standard Time
" Maintainer:	Dan Sharp <dwsharp at hotmail dot com>
" Version:	1.3
"
" NOTE:		This script currently requires Vim 6.  If there is interest
"		in making it 5.x compatible, let me know and I will see what 
"		I can do.
"
" Documentation: {{{
" 
" Installation:	Untar the file into your $VIM/vimfiles (Win32) or ~/.vim
"		(unix) directory, and it will automatically be loaded when
"		you start Vim.  Otherwise, just put it in a directory of your
"		choice and :source it as needed. The syntax should go in the
"		syntax directory.
"
" This script integrates using the IBM Configuration Management Version
" Control (CMVC) application from within Vim.  It provides keyboard shortcuts
" as well as a menu to access common functions such as checking files in and
" out, viewing and responding to defects, etc.
"
" Currently, only the functions I use regularly are implemented.  If you want
" to add others, the API should be fairly straightforward to do so.  Of
" course, I would appreciate receiving any changes you make, so that I can
" incorporate it into the next version (and avoid duplicating the work
" myself).
"
" TODO:	    Here are some other things I want to add when I get around to it:
"	    -	Implement more functions, like Report, to get a list of
"		available defects / files / etc., which you can then view or
"		checkout.
"	    -	Make the script more "plugin-ized", like allowing users to
"		override the default mappings and use their own.
"	    -	Keep a history of releases, components, and families used,
"		then present them in a "confirm" dialog so the user can just
"		pick one instead of retyping it.  Inlcude an "other" button to
"		bring up an "inputdialog" so the user can still enter an
"		unlisted / new value.
"	    -	Add commands to let the functions be used in Command mode.
"
" Changelog:
"	1.0:	Initial Release
"	1.1:	Added syntax file to highlight -view output.
"		Added extra map command for closing -view buffer.
"		Bug fixes
"	1.2:	Now uses full path name when extracting / checking out files.
"		    Instead of putting the file in the current directory and
"		    editing it there (preventing the concurrent editing of files 
"		    with the same name in two different releases), use the -top
"		    option to put the files in the appropriate subdirectory of 
"		    the current directory and edit the file there.
"		Add a help file.
"		Enhance highlighting of -view output.
"		Make script compatible with Johannes Zellner's AutoLoadGen.vim
"		Only load menus when the gui is running.
"		Allow a customizable top-level menu.
"	1.3:	Can checkout / extract a particular version of a file.
"		Can diff two versions of a file.
"		Bug fixes.
" }}}

if exists("loaded_cmvc") || &cp
    finish
endif
let loaded_cmvc = 1

let s:save_cpo = &cpo
set cpo&vim

" Initialization:	    {{{
" Setup initial variables.  If the user has set a global variable, use it.
" Otherwise, check for an environment variable.  If neither are found, set 
" the variable to blank and the user will be prompted for it when needed. 
" ===================================================================

let s:cmvcInitialized = 0

if exists("g:cmvcUserName")
    let s:cmvcUserName = g:cmvcUserName
else
    let s:cmvcUserName = ""
endif

if exists("g:cmvcBecome")
    let s:cmvcBecome = g:cmvcBecome
elseif exists("$CMVC_BECOME")
    let s:cmvcBecome = $CMVC_BECOME
else
    let s:cmvcBecome = ""
endif

if exists("g:cmvcComponent")
    let s:cmvcComponent = g:cmvcComponent
elseif exists("$CMVC_COMPONENT")
    let s:cmvcComponent = $CMVC_COMPONENT
else
    let s:cmvcComponent = ""
endif

if exists("g:cmvcFamily")
    let s:cmvcFamily = g:cmvcFamily
elseif exists("$CMVC_FAMILY")
    let s:cmvcFamily = $CMVC_FAMILY
else
    let s:cmvcFamily = ""
endif

if exists("g:cmvcRelease")
    let s:cmvcRelease = g:cmvcRelease
elseif exists("$CMVC_RELEASE")
    let s:cmvcRelease = $CMVC_RELEASE
else
    let s:cmvcRelease = ""
endif

if exists("g:cmvcTop")
    let s:cmvcTop = g:cmvcTop
elseif exists("$CMVC_TOP")
    let s:cmvcTop = $CMVC_TOP
else
    let s:cmvcTop = getcwd()
endif

if exists("g:cmvcUseTop")
    let s:cmvcUseTop = g:cmvcUseTop
else
    let s:cmvcUseTop = 1
endif

if exists("g:cmvcUseTracking")
    let s:cmvcUseTracking = g:cmvcUseTracking
else
    let s:cmvcUseVerbose = 0
endif

function! s:CmvcInitialize()
    echo "Initializing settings from server"
    let initCommand = "Report -general Config" . s:GetParam("family")
		\   . " -select name,description -where \"type in (\'phase\', \'severity\', \'symptom\') order by type\""
    let output = system(initCommand)
    echomsg output
    let s:cmvcInitialized = 1
endfunction
"}}}

" Utility functions:		{{{
" Generally "getters" for various options passed to the
" CMVC commands.  The "getters" are usually paired, one to get the value, and
" another to create the parameter string that is passed to the executable.
" ===================================================================

" Become	    {{{
function! s:Get_become()
    if s:cmvcBecome == ""
	if exists("b:cmvcBecome")
	    let s:cmvcBecome = b:cmvcBecome
	else
	    call s:SetBecome()
	endif
    endif
    return s:cmvcBecome
endfunction
" }}}

function! s:Get_level()
    if s:cmvcUserName == ""
	if exists("b:cmvcLevel")
	    let s:cmvcLevel = b:cmvcLevel
	else
	    let s:cmvcLevel = inputdialog("What level should be used?", s:cmvcLevel)
	endif
    endif
    return s:cmvcLevel
endfunction

function! s:Get_userName()
    if s:cmvcUserName == ""
	if exists("b:cmvcUserName")
	    let s:cmvcUserName = b:cmvcUserName
	else
	    let s:cmvcUserName = inputdialog("What is your user name?", s:cmvcUserName)
	endif
    endif
    return s:cmvcUserName
endfunction

function! s:Get_duplicate()
    if exists("b:cmvcDuplicate")
	let cmvcDuplicate = b:cmvcDuplicate
    else
	let cmvcDuplicate = inputdialog("What is duplicate defect number?")
    endif
    return cmvcDuplicate
endfunction

function! s:Get_answer()
    if exists("b:cmvcAnswer")
	let cmvcAnswer = b:cmvcAnswer
    else
	let cmvcAnswer = inputdialog("What is your answer for this defect?")
    endif
    return cmvcAnswer
endfunction

function! s:GetParam(type)
    execute "let paramValue = s:Get_" . a:type . "()"
    if paramValue == ""
	return ""
    endif
    let returnValue = " -" . a:type . " " . paramValue
    return returnValue
endfunction

" Component	    {{{
function! s:Get_component()
    if s:cmvcComponent == ""
	if exists("b:cmvcComponent")
	    let s:cmvcComponent = b:cmvcComponent
	else
	    call s:SetComponent()
	endif
    endif
    return s:cmvcComponent
endfunction
" }}}

" Family	    {{{
function! s:Get_family()
    if s:cmvcFamily == ""
	if exists("b:cmvcFamily")
	    let s:cmvcFamily = b:cmvcFamily
	else
	    call s:SetFamily()
	endif
    endif
    return s:cmvcFamily
endfunction
" }}}

" Release	    {{{
function! s:Get_release()
    if s:cmvcRelease == ""
	if exists("b:cmvcRelease")
	    let s:cmvcRelease = b:cmvcRelease
	else
	    call s:SetRelease()
	endif
    endif
    return s:cmvcRelease
endfunction
" }}}

" Convenience method.  Most File operations require Family and Release
" parameters.  This method combines them.  Just saves typing later.
function! s:GetFileCheckingParams()
    return s:GetParam("family") . s:GetParam("release")
endfunction

" Owner		{{{
function! s:Get_owner()
    return inputdialog("Who should be the owner?")
endfunction
" }}}

" Defect	    {{{
function! s:Get_defect()
    if !exists("b:defectNum")
	let defectNum = inputdialog("What defect do you want?")
    else
	let defectNum = b:defectNum
    endif
    return defectNum
endfunction
" }}}

" Tester	    {{{
function! s:Get_tester()
    if !exists("b:tester")
	let tester = inputdialog("Who was the tester?")
    else
	let tester = b:tester
    endif
    return tester
endfunction
" }}}

" tag		    {{{
function! s:Get_tag()
    if !exists("b:tag")
	let tagDir = inputdialog("What tag do you want?")
    else
	let tagDir = b:tag
    endif
    return tagDir
endfunction
" }}}

" Top		    {{{
function! s:Get_top()
    if !exists("b:top")
	let topDir = inputdialog("What directory do you want?")
    else
	let topDir = b:top
    endif
    return topDir
endfunction
" }}}

" Remarks	    {{{
function! s:Get_remarks()
    let remarks = ""
    " Start reading remarks from the third line, since the first two contain
    " the instructions and a blank line.
    normal 3G
    let lineNum = 3
    while lineNum <= line("$")
	let remarks = remarks . getline(lineNum) . " "
	let lineNum = lineNum + 1
    endwhile
    return escape(remarks, '"')
endfunction
" }}}

" Abstract	    {{{
function! s:Get_abstract()
    let abstract = inputdialog("Enter the abstract for this defect:")
    return '"' . escape(abstract, '!"') . '"'
endfunction
" }}}

" Filename	    {{{
function! s:Get_fileName()
    if exists("b:fileName")
	let fileName = inputdialog("What file do you want?", b:fileName)
    else
	let fileName = inputdialog("What file do you want?")
    endif
    return fileName
endfunction
" }}}

" File Version	    {{{
function! s:Get_version()
    if exists("b:fileVersion")
	let fileVersion = inputdialog("What version of the file do you want?", b:fileVersion)
    else
	let fileVersion = inputdialog("What version of the file do you want?")
    endif
    return fileVersion
endfunction
" }}}

function s:OpenScratchBuffer(bufName)
    if !bufexists(a:bufName)
	execute "edit " . a:bufName
    else
	" If the buffer already exists, switch to it and delete the current
	" contents to refresh the display.
	execute "buffer " . a:bufName
	normal ggdG
    endif
    set buftype=nofile
    set bufhidden=hide
    set noswapfile
endfunction

" Most commands send data to the server and expect no reply.  When specifying
" the -view option to a command, though, we want to display the output in a
" new buffer.  Open a scratch buffer and read in the data returned by the view
" command.
function s:View(object, target, extraParams)
    let bufName = "(" . a:object . "-" . a:target . ")"
    call s:OpenScratchBuffer(bufName)
    execute "silent 0r !" . a:object . " -view " . a:target . a:extraParams . " -long"
    " Set the filetype to cmvc to load the CMVC syntax file and jump to the
    " top of the file.
    setf cmvc
    normal gg
endfunction

" Many operations allow the user to add remarks about the action they are
" performing.  For these operations, split open a scratch buffer where the
" user can enter these comments.  When the window is closed, execute the 
" specified command, passing the data entered in this buffer, then remove
" the buffer.
function! s:OpenCommentsWindow(object, action, params)
    new 
    set buftype=nofile
    set bufhidden=unload
    set nobuflisted
    set noswapfile
    " Setup the command to execute when the user closes the comments window.
"    let mapCommand = ":call <SID>Execute('" . a:object . "', '" . a:action
"	\ . "', '" . a:params . "' . <SID>GetParam('remarks') ) <bar> bw<CR>"
    let mapCommand = ":3,$w !" . a:object . " -" . a:action . " " . a:params . " -remarks  - "
    echomsg mapCommand

    " Map the common write commands to call execute() and then wipeout the
    " buffer.
    execute "cmap <silent> <buffer> wq " . mapCommand . "<CR> :bw <CR>"
    execute "nmap <silent> <buffer> ZZ " . mapCommand . "<CR> :bw <CR>"

    " Tell the user what to do, and put them in insert mode.
    let @a = "Please enter your remarks below... Use <ESC>ZZ or <ESC>:wq to exit"
    put! a
    put =''
    normal G
    startinsert
endfunction

" All commands except -view have the same execution syntax.  This is just
" a central routine to easily allow global modification of the final command
" (like adding the -verbose flag, for example).
function! s:Execute(object, action, params)
    let commandLine = a:object . " -" . a:action . " " . a:params
    if s:cmvcUseVerbose == "1"
	let commandLine = commandLine . " -verbose"
    endif
    "echomsg commandLine
    let output = system(commandLine)
    if output != ""
	" Cut off the trailing character before displaying it.
	let output = strpart(output, 0, strlen(output)-1)
        echomsg output
    endif
endfunction

function! s:GetFileToDiff(num, fileName)
    " Use the Report command to determine the full pathname of the desired
    " file.  This allows the user to specify file.ext to actually edit
    " path/to/file.ext instead.
    let fileCommand = "Report -general FileView" . s:GetParam("family")
	\ . " -select versionSID -where \"nuPathName like '%" . a:fileName 
	\ . "' and releaseName='" . s:Get_release() . "'\""
    let results = system(fileCommand)
    if results == ""
	return
    endif
    
    " Cut off the trailing ^@ from the returned results.
    let b:fileVersion = strpart(results, stridx(results, '|') + 1, strlen(results) - 1)

    let command = "File -extract " . a:fileName . " -stdout" . s:GetFileCheckingParams() . s:GetParam("version") . " > " . getcwd() . "\\test1"
    call s:OpenScratchBuffer( a:num . "-" . a:fileName )
    set nobuflisted
    execute "silent! 0r !" . command
endfunction

" }}}

" Main operation functions: the "external API"	    {{{
" ===================================================================

" Work with files in the repository.
function! s:FileCommand(action)
    let fileName = s:Get_fileName()
    if fileName == ""
	return
    endif

    if a:action == "view"
	call s:View( "File", fileName, s:GetFileCheckingParams() )
	let b:fileName = fileName
    elseif a:action == "checkin" || a:action == "create"
	let params =  expand("%") . s:GetFileCheckingParams()
	if s:cmvcUseTracking == 1 "Also for undo, rename, recreate, promote, link, delete
	    let params = params . s:GetParam("defect")
	endif
	if a:action == "create"
	    let params = params . s:GetParam("component")
	endif
	call s:OpenCommentsWindow("File", a:action, params )
    elseif a:action == "checkout" || a:action == "extract"
	let topParam = ""

	" Use the Report command to determine the full pathname of the desired
	" file.  This allows the user to specify file.ext to actually edit
	" path/to/file.ext instead.
	let fileCommand = "Report -general FileView" . s:GetParam("family")
	    \ . " -select nuPathName,versionSID -where \"nuPathName like '%" . fileName 
	    \ . "' and releaseName='" . s:Get_release() . "'\""
	let results = system(fileCommand)
	if results == ""
	    return
	endif
	
	" Split the results into the filename and version number and
	" cut off the trailing ^@ from the returned results.
	let fileName = strpart(results, 0, stridx(results, '|'))
	let b:fileVersion = strpart(results, stridx(results, '|') + 1)
	let b:fileVersion = strpart(b:fileVersion, 0, strlen(b:fileVersion) - 1)

	if s:cmvcUseTop == 1
	    let topParam = " -top " . s:cmvcTop
	    if s:cmvcTop != getcwd()
		execute "cd " . s:cmvcTop
	    endif
	endif
	call s:Execute("File", a:action, fileName . s:GetFileCheckingParams() . s:GetParam("version") . topParam)
	execute "edit " . fileName
    elseif a:action == "diff"
	" CMVC command line functionality doesn't directly support a 'diff' command.
	" This is a convenience implementation I have added, similar to the
	" diff action available with the CMVC GUI.
	call s:GetFileToDiff(1, fileName)
	call s:SetRelease()	" Let the user select a different release, if desired.
	call s:GetFileToDiff(2, fileName)

	" Activate diff mode for the two new buffers.
	diffthis
	execute "silent! vertical diffsplit 1-" . fileName
    elseif a:action == "unlock" || a:action == "lock"
	call s:Execute("File", a:action, fileName . s:GetFileCheckingParams())
    endif
endfunction

" Work with defects in the repository
function! s:DefectCommand(action)
    if a:action == "open"
	let params = s:GetParam("family") . s:GetParam("component") . s:GetParam("abstract")
		\    s:GetParam("release") . s:GetParam("become") . s:GetParam("level")
	call s:OpenCommentsWindow("Defect", a:action, params)
    else
	let defectNum = s:Get_defect()
	if defectNum == ""
	    return
	endif
	if a:action == "view"
	    call s:View("Defect", defectNum, s:GetParam("family"))
	    let b:defectNum = defectNum
	elseif a:action == "cancel" || a:action == "design" || a:action == "recall" ||
	    \  a:action == "recall" || a:action == "reopen" || a:action == "review" ||
	    \  a:action == "size"   || a:action == "verify" || a:action == "assign" ||
	    \  a:action == "note"   || a:action == "return"
	    let params = defectNum . s:GetParam("family") . s:GetParam("become")
	    if a:action == "assign"
		let params = params . s:GetParam("owner") . s:GetParam("component")
	    elseif a:action == "note"
		let params = params . s:GetParam("tag")
	    elseif a:action == "return"
		let choice = confirm("How should this be returned?", "&Duplicate\n&Answer...")
		if choice == 1
		    let params = params . s:GetParam("duplicate")
		elseif choice == 2
		    let params = params . s:GetParam("answer")
		endif
	    endif
	    call s:OpenCommentsWindow("Defect", a:action, params)
	endif
    endif
endfunction

" Work with tracks in the repository
function! s:TrackCommand(action)
    let defectNum = s:Get_defect()
    if defectNum == ""
	return
    endif
    let b:defectNum = defectNum

    let params = s:GetFileCheckingParams()

    if a:action == "view"
	call s:View("Track", s:GetParam("defect"), params)
	let b:defectNum = defectNum
    elseif a:action == "create" || a:action == "integrate" || a:action == "cancel" ||
        \  a:action == "review" || a:action == "complete"  || a:action == "test" ||
	\  a:action == "commit" || a:action == "consider"  || a:action == "fix"
	let params = params . s:GetParam("defect") . s:GetParam("become")
	if a:action == "create"
	    let params = params . s:GetParam("owner") . s:GetParam("target") . s:GetParam("level")
	endif
	call s:Execute( "Track", a:action, s:GetParam("defect") . params)
    endif
endfunction

" Related to defects, allows you to work with verification records.
function! s:VerifyCommand(action)
    let defectNum = s:Get_defect()
    if defectNum == ""
	return
    endif

    let params = s:GetParam("defect") . s:GetParam("family") . s:GetParam("become") . s:getParam("tester")
    if a:action == "assign"
	let params = params . s:GetParam("owner")
	call s:Execute( "VerifyCm", a:action, params)
    else
	call s:OpenCommentsWindow("VerifyCm", a:action, params)
    endif
endfunction

" Login in and out of CMVC servers when required.
function! s:CmvcLogCommand(action)
    let params = s:Get_userName() . s:GetParam("family")
    if a:action == "in"
	let params = params . " -noprompt " . inputsecret( "What is your password?" )
    endif
    call s:Execute("cmvclog", a:action, params)
endfunction

" Related to working with files, indicates whether a defect number must be
" associated with a command to modify a file.
function! s:SetTracking()
    let s:cmvcUseTracking = confirm("Do you want to enable tracking?", "&Yes\n&No")
endfunction

" A few quik methods to let users change the predefined values.
function! s:SetBecome()
    let s:cmvcBecome = inputdialog("Who should I become?", s:cmvcBecome)
endfunction

function! s:SetComponent()
    let s:cmvcComponent = inputdialog("What component should be used?", s:cmvcComponent)
endfunction

function! s:SetFamily()
    let s:cmvcFamily = inputdialog("What family should be used?", s:cmvcFamily)
endfunction

function! s:SetRelease()
    let s:cmvcRelease = inputdialog("What release should be used?", s:cmvcRelease)
endfunction

function! s:SetVerbose()
    let s:cmvcUseVerbose = confirm("Do you want verbose output?", "&Yes\n&No")
endfunction

function! s:SetTop()
    let s:cmvcUseTop = confirm("Do you want to use the Top option?", "&Yes\n&No")
    if s:cmvcUseTop == 1
	let s:cmvcTop = inputdialog("What directory should be the top?", s:cmvcTop)
    endif
endfunction

function! CMVC(object, action)
    " Use this to initialize settings for phase, symptom, etc.
    "if s:cmvcInitialized == 0
    "    call s:CmvcInitialize()
    "endif
    if stridx(a:object, "Set") == -1
	execute "call <SID>" . a:object . "Command('" . a:action . "')"
    else
	execute "call <SID>" . a:object . "()"
    endif
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

if exists('g:autoload') | finish | endif " used by the autoload generator

" Mappings		{{{
" ===================================================================

" Defects		    {{{
map <silent> <Leader>dvi :call CMVC("Defect", "view")<CR>
map <silent> <Leader>dop :call CMVC("Defect", "open")<CR>
map <silent> <Leader>das :call CMVC("Defect", "assign")<CR>
map <silent> <Leader>dac :call CMVC("Defect", "accept")<CR>
map <silent> <Leader>dve :call CMVC("Defect", "verify")<CR>
map <silent> <Leader>dca :call CMVC("Defect", "cancel")<CR>
map <silent> <Leader>dre :call CMVC("Defect", "reopen")<CR>
map <silent> <Leader>dan :call CMVC("Defect", "note")<CR>
"	}}}

" Files		{{{
map <silent> <Leader>fci :call CMVC("File", "checkin")<CR>
map <silent> <Leader>fco :call CMVC("File", "checkout")<CR>
map <silent> <Leader>fcr :call CMVC("File", "create")<CR>
map <silent> <Leader>fdi :call CMVC("File", "diff")<CR>
map <silent> <Leader>fex :call CMVC("File", "extract")<CR>
map <silent> <Leader>fvi :call CMVC("File", "view")<CR>
map <silent> <Leader>flo :call CMVC("File", "lock")<CR>
map <silent> <Leader>ful :call CMVC("File", "unlock")<CR>
map <silent> <Leader>fud :call CMVC("File", "undo")<CR>
"	}}}

" Tracks	    {{{
map <silent> <Leader>tcr :call CMVC("Track", "create")<CR>
map <silent> <Leader>tvi :call CMVC("Track", "view")<CR>
map <silent> <Leader>tin :call CMVC("Track", "integrate")<CR>
map <silent> <Leader>tca :call CMVC("Track", "cancel")<CR>
map <silent> <Leader>tre :call CMVC("Track", "review")<CR>
map <silent> <Leader>tcp :call CMVC("Track", "complete")<CR>
map <silent> <Leader>tte :call CMVC("Track", "test")<CR>
map <silent> <Leader>tcm :call CMVC("Track", "commit")<CR>
map <silent> <Leader>tcn :call CMVC("Track", "consider")<CR>
map <silent> <Leader>tfi :call CMVC("Track", "fix")<CR>
"	}}}

" Verify Commands	    {{{
map <silent> <Leader>vab    :call CMVC("Verify", "abstain")<CR>
map <silent> <Leader>vac    :call CMVC("Verify", "accept")<CR>
map <silent> <Leader>vas    :call CMVC("Verify", "assign")<CR>
map <silent> <Leader>vre    :call CMVC("Verify", "reject")<CR>
"	}}}

" General settings	    {{{
map <silent> <Leader>str :call CMVC("SetTracking", "")<CR>
map <silent> <Leader>sfa :call CMVC("SetFamily", "")<CR>
map <silent> <Leader>sre :call CMVC("SetRelease", "")<CR>
map <silent> <Leader>sco :call CMVC("SetComponent", "")<CR>
map <silent> <Leader>sbe :call CMVC("SetBecome", "")<CR>
map <silent> <Leader>sve :call CMVC("SetVerbose", "")<CR>
map <silent> <Leader>sto :call CMVC("SetTop", "")<CR>
"	}}}

map <silent> <Leader>lin :call CMVC("CmvcLog", "in")<CR>
map <silent> <Leader>lou :call CMVC("CmvcLog", "out")<CR>

"   }}}

" Menus			{{{
" ===================================================================
" Do not bother loading the menus if the user is running console vim.
if has("gui_running")

    " Determine the prefix for the menus.  Must be done here to work for the
    " autoloading feature.
    if !exists("g:cmvcUsePluginMenu")
	let s:cmvcUsePluginMenu = 0
    endif

    if !exists("g:cmvcTopLevelMenu")
	if s:cmvcUsePluginMenu == 1
	    let s:cmvcTopLevelMenu = "Plugin."
	else
	    let s:cmvcTopLevelMenu = ""
	endif
    endif

    let menuCommandPrefix = 'amenu <silent> <script> ' . s:cmvcTopLevelMenu . 'CMVC.'

" Defects		    {{{
execute menuCommandPrefix . '&Defects.&View<TAB>\\dvi :call CMVC("Defect", "view")<CR>'
execute menuCommandPrefix . '&Defects.&Open<TAB>\\dop :call CMVC("Defect", "open")<CR>'
execute menuCommandPrefix . '&Defects.A&ssign<TAB>\\das  :call CMVC("Defect", "assign")<CR>'
execute menuCommandPrefix . '&Defects.A&ccept<TAB>\\dac  :call CMVC("Defect", "accept")<CR>'
execute menuCommandPrefix . '&Defects.&Verify<TAB>\\dve  :call CMVC("Defect", "verify")<CR>'
execute menuCommandPrefix . '&Defects.&Cancel<TAB>\\dca  :call CMVC("Defect", "cancel")<CR>'
execute menuCommandPrefix . '&Defects.&Reopen<TAB>\\dre  :call CMVC("Defect", "reopen")<CR>'
execute menuCommandPrefix . '&Defects.Add\ &Note<TAB>\\dan  :call CMVC("Defect", "note")<CR>'
"	}}}

" Files			    {{{
execute menuCommandPrefix . '&Files.Check\ &In<TAB>\\fci  :call CMVC("File", "checkin")<CR>'
execute menuCommandPrefix . '&Files.Check\ &Out<TAB>\\fco :call CMVC("File", "checkout")<CR>'
execute menuCommandPrefix . '&Files.Create<TAB>\\fcr :call CMVC("File", "create")<CR>'
execute menuCommandPrefix . '&Files.Diff<TAB>\\fdi :call CMVC("File", "diff")<CR>'
execute menuCommandPrefix . '&Files.&Extract<TAB>\\fex :call CMVC("File", "extract")<CR>'
execute menuCommandPrefix . '&Files.&View<TAB>\\fvi :call CMVC("File", "view")<CR>'
execute menuCommandPrefix . '&Files.&Lock<TAB>\\flo :call CMVC("File", "lock")<CR>'
execute menuCommandPrefix . '&Files.&Unlock<TAB>\\ful :call CMVC("File", "unlock")<CR>'
execute menuCommandPrefix . '&Files.&Undo<TAB>\\fud :call CMVC("File", "undo")<CR>'
"	}}}

" Tracks		    {{{
execute menuCommandPrefix . '&Tracks.&Create<TAB>\\tcr :call CMVC("Track", "create")<CR>'
execute menuCommandPrefix . '&Tracks.&View<TAB>\\tvi :call CMVC("Track", "view")<CR>'
execute menuCommandPrefix . '&Tracks.&Integrate<TAB>\\tin :call CMVC("Track", "integrate")<CR>'
execute menuCommandPrefix . '&Tracks.&Cancel<TAB>\\tca :call CMVC("Track", "cancel")<CR>'
execute menuCommandPrefix . '&Tracks.&Review<TAB>\\tre :call CMVC("Track", "review")<CR>'
execute menuCommandPrefix . '&Tracks.Complete<TAB>\\tcp :call CMVC("Track", "complete")<CR>'
execute menuCommandPrefix . '&Tracks.&Test<TAB>\\tte :call CMVC("Track", "test")<CR>'
execute menuCommandPrefix . '&Tracks.Commit<TAB>\\tcm :call CMVC("Track", "commit")<CR>'
execute menuCommandPrefix . '&Tracks.Consider<TAB>\\tcn :call CMVC("Track", "consider")<CR>'
execute menuCommandPrefix . '&Tracks.&Fix<TAB>\\tfi :call CMVC("Track", "fix")<CR>'
"	}}}

" Verify Commands	    {{{
execute menuCommandPrefix . '&Verify.A&bstain<TAB>\\vab	:call CMVC("Verify", "abstain")<CR>'
execute menuCommandPrefix . '&Verify.A&ccept<TAB>\\vac	:call CMVC("Verify", "accept")<CR>'
execute menuCommandPrefix . '&Verify.A&ssign<TAB>\\vas	:call CMVC("Verify", "assign")<CR>'
execute menuCommandPrefix . '&Verify.&Reject<TAB>\\vre	:call CMVC("Verify", "reject")<CR>'
"	}}}

" General settings	    {{{
execute menuCommandPrefix . 'Set\ &Tracking<TAB>\\str	:call CMVC("SetTracking", "")<CR>'
execute menuCommandPrefix . 'Set\ &Family<TAB>\\sfa	:call CMVC("SetFamily", "")<CR>'
execute menuCommandPrefix . 'Set\ &Release<TAB>\\sre	:call CMVC("SetRelease", "")<CR>'
execute menuCommandPrefix . 'Set\ &Component<TAB>\\sco	:call CMVC("SetComponent", "")<CR>'
execute menuCommandPrefix . 'Set\ &Become<TAB>\\sbe	:call CMVC("SetBecome", "")<CR>'
execute menuCommandPrefix . 'Set\ &Verbose<TAB>\\sve	:call CMVC("SetVerbose", "")<CR>'
execute menuCommandPrefix . 'Set\ To&p<TAB>\\sto	:call CMVC("SetTop", "")<CR>'
"	}}}

execute menuCommandPrefix . 'Login<TAB>\\lin	:call CMVC("CmvcLog", "in")<CR>'
execute menuCommandPrefix . 'Logout<TAB>\\lou	:call CMVC("CmvcLog", "out")<CR>'

endif
"   }}}
