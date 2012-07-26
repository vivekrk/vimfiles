"*****************************************************************************
"** Name:      SnippetsMgr.vim - handle code snippets                       **
"**                                                                         **
"** Type:      global VIM plugin for Vim 7                                  **
"**                                                                         **
"** Author:    Christian Habermann                                          **
"**            christian (at) habermann-net (point) de                      **
"**                                                                         **
"** License:   GNU General Public License 2 (GPL 2) or later                **
"**                                                                         **
"**            This program is free software; you can redistribute it       **
"**            and/or modify it under the terms of the GNU General Public   **
"**            License as published by the Free Software Foundation; either **
"**            version 2 of the License, or (at your option) any later      **
"**            version.                                                     **
"**                                                                         **
"**            This program is distributed in the hope that it will be      **
"**            useful, but WITHOUT ANY WARRANTY; without even the implied   **
"**            warrenty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      **
"**            PURPOSE.                                                     **
"**            See the GNU General Public License for more details.         **
"**                                                                         **
"** Version:   1.01.00                                                      **
"**            tested under Windows (gvim 7.0)                              **
"**                                                                         **
"** History:   1.01.00,  19. Nov. 2006                                      **
"**              Indentation of snippets added. Thanks to Roman Roelofson   **
"**              for the inspiration.                                       **
"**            1.00.00,  26. Oct. 2006                                      **
"**              initial version                                            **
"**                                                                         **
"*****************************************************************************
"** Description:                                                            **
"**   This script helps to work with code snippets. It provides functions   **
"**   to insert, edit, create, delete and rename code snippets.             **
"**   Snippets are files that can be loaded into the active buffer          **
"**   (e.g. programmers can easily add a template function header when      **
"**   writing a new function or add often used codes).                      **
"**                                                                         **
"**   To invoke the snippets manager, press <leader>sm                      **
"**     Memory aid: sm (s)nippets(m)anager                                  **
"**   In the current window a list of code snippets will be shown. To       **
"**   copy a snippet into the buffer in which SnippetsMgr was invoked,      **
"**   move cursor over a snippet and press <enter>. That's it.              **
"**                                                                         **
"**   Simple and not very useful code snippets are provided with this       **
"**   script. See them as examples and as starting point to write own ones. **
"**   Code snippets are very personal. To use them in an efficient way you  ** 
"**   will have to write your owns.                                         **
"**                                                                         **
"**                                                                         **
"**   Installation:                                                         **
"**   =============                                                         **
"**   Just copy this script into Vim's plugin directory, for details see    **
"**   Vim help ':help plugin'.                                              **
"**   Copy the directory 'snippets' to your vimfiles directory and set      **
"**   the path to it (configuration see below).                             **
"**                                                                         **
"**   Configuration:                                                        **
"**   =============                                                         **
"**   To configure SnippetsMgr you may set the following variables in your  **
"**   vimrc-file. If they are not set, defaults will be taken.              **
"**                                                                         **
"**     - Mapping <Plug>smgr_MapSnippetsManager                             **
"**       mapping to start SnippetsMgr                                      **
"**       default:                                                          **
"**         nmap <silent> <unique> <leader>sm <Plug>smgr_MapSnippetsManager **
"**                                                                         **
"**     - Variable g:smgr_snippetsPath                                      **
"**       path to search for snippets files (suffix *.smg)                  **
"**       default:                                                          **
"**         let g:smgr_snippetsPath = $VIM."/vimfiles/snippets"             **
"**                                                                         **
"**     - Variable g:smgr_shiftWidth                                        **
"**       This variable defines how much to indent code when loading        **
"**       a snippet independent from Vim's option 'shiftwidth'.             **
"**       Default: use Vim's option 'shiftwidth'                            **
"**                                                                         **
"**   Module prefix is smgr_                                                **
"**                                                                         **
"**   Happy viming...                                                       **
"*****************************************************************************
    

" before doing anything, check whether vim version is ok
if ( v:version < 700 )
    echoerr "sorry, need Vim version 7.0 or newer"
    finish
endif


" allow user to avoid loading this plugin and prevent loading twice
if exists ("loaded_smgr")
    finish
endif

let loaded_smgr = 1




"*****************************************************************************
"************************** C O N F I G U R A T I O N ************************
"*****************************************************************************

" the mappings:
if !hasmapto('<Plug>smgr_MapSnippetsManager')
    nmap <silent> <unique> <Leader>sm <Plug>smgr_MapSnippetsManager
endif

nmap <silent> <unique> <script> <Plug>smgr_MapSnippetsManager   :call <SID>smgr_StartSnippetsManager()<CR>


if !exists('g:smgr_snippetsPath')
    let g:smgr_snippetsPath = $VIM."/vimfiles/snippets"
endif


" set value for indentation; if not defined by user, use 'shiftwidth'
if !exists ( 'g:smgr_shiftWidth' )
    let g:smgr_shiftWidth = &shiftwidth
endif


"*****************************************************************************
"************************* I N I T I A L I S A T I O N ***********************
"*****************************************************************************

  " used to print/echo name of script
let s:scriptName    = "Snippets Manager"

  " suffix of code snippets files, must be in lower case
let s:snippetSuffix = "\.smg"

  " used to store number of buffer showing SnippetsMgr's user interface 
  " set it to impossible value
let s:userBufNr = -1 



"*****************************************************************************
"****************** I N T E R F A C E  T O  C O R E **************************
"*****************************************************************************


"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   Start the snippets manager.                                           **
"*****************************************************************************
function <SID>smgr_StartSnippetsManager()

                                        " setup user-interface
    if ( !s:OpenNewBuffer() )           " get buffer for user-interface
        call s:ShowSnippetsManager()      " show the dialog
        call s:SetLocalKeyMappings()      " and set keys for user (local to buffer)
    endif

endfunction





"*****************************************************************************
"************************ C O R E  F U N C T I O N S *************************
"*****************************************************************************


"*****************************************************************************
"** input:   makeIndent: 0 no indent, else indent the snippet               **
"** output:  ---                                                            **
"**                                                                         **
"** remarks:                                                                **
"**   Load snippet under cursor.                                            **
"*****************************************************************************
function <SID>smgr_LoadSnippet( makeIndent )

    let l:snippetID = GetSnippetID()

    if ( l:snippetID >= 0 )
        let s:snippetFile = g:smgr_snippetsPath."/".s:fileList[ l:snippetID ]

        if ( filereadable( s:snippetFile ) )
            call s:smgr_Exit()              " close user interface

            " Get number of lines before loading snippet and later after
            " loading to get number of new lines (needed to indent)
            let numLines = line( "$" )

            let l:oldCpoptions	= &cpoptions    " don't change alternate file name
            setlocal cpoptions-=a
            :execute "-1read ".s:snippetFile
            let &cpoptions	= l:oldCpoptions	" restore previous options

            " now make the indentation if required
            if ( a:makeIndent )
                " use a script specific shift width
                let shiftWidthBackup = &shiftwidth
                let &shiftwidth      = g:smgr_shiftWidth

                " calculate number of lines of the snippet
                let numLines = line( "$" ) - numLines

                if ( numLines > 0 )
                    execute "normal  =".numLines."+"
                else
                    execute "normal  =0"
                endif

                " restore shift width of indentation
                let &shiftwidth = shiftWidthBackup
            endif

        else
            call s:Error( 4, s:snippetFile )
        endif
    else
        call s:Error( 5, "" )
    endif
endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   Update list of code snippets.                                         **
"*****************************************************************************
function <SID>smgr_UpdateSnippets()
    let b:saveCursor = getpos( "." )

    call s:ShowSnippetsManager()

    call setpos( ".", b:saveCursor )
endfunction
    


"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   Delete snippet under cursor.                                          **
"*****************************************************************************
function <SID>smgr_DeleteSnippet()

    let l:snippetID = GetSnippetID()

    if ( l:snippetID >= 0 )
        let s:snippetFile = g:smgr_snippetsPath."/".s:fileList[ l:snippetID ]

        let l:answer = Input( "Delete snippet file \"".s:fileList[ l:snippetID ]."\" [yes, no]: ", "no" )

        if ( l:answer == "yes" )
            if ( delete( s:snippetFile ) == 0 )
                call <SID>smgr_UpdateSnippets()
            else
                call s:Error( 8, s:snippetFile )
            endif
        else
            echo "not deleted"
        endif
    else
        call s:Error( 5, "" )
    endif
endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   Rename snippet under cursor.                                          **
"*****************************************************************************
function <SID>smgr_RenameSnippet()

    let l:snippetID = GetSnippetID()

    if ( l:snippetID >= 0 )
        let s:snippetFile = g:smgr_snippetsPath."/".s:fileList[ l:snippetID ]

        let l:newName = Input( "Rename snippet file \"".s:fileList[ l:snippetID ]."\": ", "" )

        if ( l:newName != "" )          
            let l:newName = g:smgr_snippetsPath."/".l:newName

            if ( glob( l:newName ) == "" )    " does file already exit?
                if ( rename( s:snippetFile, l:newName ) == 0 )
                    call <SID>smgr_UpdateSnippets()
                else
                    call s:Error( 6, s:snippetFile )
                endif
            else
                call s:Error( 7, "" )
            endif
        else
            echo "not renamed"
        endif
    else
        call s:Error( 5, "" )
    endif
endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   Load snippet under cursor.                                            **
"*****************************************************************************
function <SID>smgr_EditSnippet()

    let l:snippetID = GetSnippetID()

    if ( l:snippetID >= 0 )
        let s:snippetFile = g:smgr_snippetsPath."/".s:fileList[ l:snippetID ]

        if ( filereadable( s:snippetFile ) )
            call <SID>smgr_Exit()
            execute "edit ".s:snippetFile
        else
            call s:Error( 4, s:snippetFile )
        endif
    else
        call s:Error( 5, "" )
    endif

endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   Create a new snippet file and edit it.                                **
"*****************************************************************************
function <SID>smgr_NewSnippet()
    let l:newFile = Input( "Name of new snippet file (without path, suffix \"".s:snippetSuffix."\" not required): ", "" )

    if ( l:newFile != "" )
        let l:newFile = g:smgr_snippetsPath."/".l:newFile

        " Check for suffix. If it is missing, add it.
        let l:lowerFile = tolower( l:newFile )                     " make filename lowercase to be not case-sensitive
        let l:suffixPos = strridx( l:lowerFile, s:snippetSuffix )  " then search for the suffix pattern

        if ( l:suffixPos >= 0 )           " suffix pattern found? yes, then check if it is at the end of the string (else
                                          " it wouldn't be a suffix and we would have to add it)
            if ( l:suffixPos != len( l:newFile ) - len( s:snippetSuffix ) )    " suffix pattern at end of filename? 
                                                                               " no, then no suffix present => add it
                let l:newFile = l:newFile . s:snippetSuffix
            endif
        else                              " no suffix found => add it
            let l:newFile = l:newFile . s:snippetSuffix
        endif


        if ( glob( l:newFile ) == "" )    " does file already exit?

            let l:empty = [ "\r" ]        " writefile() will add a <LF> => <CR><LF> will be written

            if ( !writefile( l:empty, l:newFile ) )
                call <SID>smgr_UpdateSnippets()     " update list of snippets
            else
                call s:Error( 9, l:newFile )
            endif
        else
            call s:Error( 7, "" )
        endif
    else
        echo "no file created"
    endif

endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:   0: ok                                                         **
"**          <0: error                                                      **
"** remarks:                                                                **
"**   Open a new buffer for user interaction.                               **
"*****************************************************************************
function s:OpenNewBuffer()
    
    " save current buffer number so that we can switch back to this buffer
    " when finishing job
    " but only if the current buffer isn't already one of the own ones
    if ( s:userBufNr != winbufnr( 0 ) )
        let s:targetBufNr = winbufnr( 0 )
    endif
    
    " open buffer for user interface
    execute "enew"

    " get buffer for user interface
    let s:userBufNr = winbufnr( 0 )

    " if new buffer is the same as destination buffer we have no buffer to insert a snippet
    if ( s:userBufNr == s:targetBufNr )
        call s:smgr_Exit()
        call s:Error( 1, "" )
        return -1
    endif
    
    " buffer specific settings:
    "   - nomodifiable:     don't allow to edit this buffer
    "   - noswapfile:       we don't need a swapfile
    "   - buftype=nowrite:  buffer will not be written
    "   - bufhidden=delete: delete this buffer if it will be hidden
    "   - nowrap:           don't wrap around long lines
    "   - iabclear:         no abbreviations in insert mode
    setlocal nomodifiable
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    iabclear <buffer>

    return 0
endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:   0: ok                                                         **
"**          <0: error                                                      **
"** remarks:                                                                **
"**   Show the snippets manager in current buffer.                          **
"*****************************************************************************
function s:ShowSnippetsManager()

    let s:fileList = []

    " does snippets directory exist?
    if ( isdirectory(g:smgr_snippetsPath) )
     
        " init syntax-highlighting of user-interface
        call s:SetupSyntax()

        setlocal modifiable

        " delete all lines, use black hole register
        %delete _

        " add content
        let l:txt  =         "\"       Snippets Manager\n"
        let l:txt  = l:txt . "\"  ==========================\n"
        let l:txt  = l:txt . "\"  q:quit\n"
        let l:txt  = l:txt . "\"  <enter>/mouse-click:load with indent\n"
        let l:txt  = l:txt . "\"  l:load without indent\n"
        let l:txt  = l:txt . "\"  u:update this list\n"  
        let l:txt  = l:txt . "\"  d:delete\n"
        let l:txt  = l:txt . "\"  r:rename\n"  
        let l:txt  = l:txt . "\"  e:edit\n"
        let l:txt  = l:txt . "\"  n:new\n"
        let l:txt  = l:txt . "\"\n"
        let l:txt  = l:txt . "> Code Snippets:"
        let l:txt  = l:txt . "\n"
        let l:txt  = l:txt . "\n"

        put! = l:txt

        let s:lineNrFirstSnippet = line(".") + 1


        execute 'cd '.g:smgr_snippetsPath
        call s:GetFiles( 's:fileList' )
        cd -

        if ( len( s:fileList ) >= 1 )       " at least one snippet found?
            let l:prefix = "    "

            for item in s:fileList
                let l:lowerItem = tolower( item )     " make filename lowercase to be not case sensitive

                let l:idx = strridx( l:lowerItem, s:snippetSuffix )

                put = l:prefix . strpart( item, 0, l:idx )
            endfor
        else
            let   b:aux = "no snippets found in " . g:smgr_snippetsPath
            put = b:aux
        endif

        
        let s:lineNrLastSnippet = line(".")

        " set cursor position to first snippet
        call cursor( s:lineNrFirstSnippet, strlen( l:prefix ) + 1 )

        setlocal nomodifiable
    else
        call s:Error( 3, g:smgr_snippetsPath )       " no snippets directory
    endif
endfunction




"*****************************************************************************
"** input:   fileListVariable: variable to store the list of snippet files  **
"** output:  ---                                                            **
"**                                                                         **
"** remarks:                                                                **
"**   Get list of snippet files.                                            **
"*****************************************************************************
function s:GetFiles( fileListVariable )
    let l:fileList = glob( "*".s:snippetSuffix )

    let {a:fileListVariable} = split( l:fileList, '\n' )
endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   set syntax-highlighting for user-interface (if VIM has 'syntax')      **
"*****************************************************************************
function s:SetupSyntax()

    " don't continue, if this version of VIM does not support syntax-highlighting
    if !has('syntax')
        return
    endif

    syntax match smgrHeadline ">.*:"
    syntax match smgrComment   "^\".*"

    if !exists('g:smgr_syntaxUIinit')
        let g:smgr_syntaxUIinit = 0

        hi def link smgrHeadline  String
        hi def link smgrComment   Comment
    endif

endfunction



"*****************************************************************************
"** input:   none                                                           **
"** output:  none                                                           **
"** remarks:                                                                **
"**   set local/temporally key-mappings valid for this buffer only          **
"*****************************************************************************
function s:SetLocalKeyMappings()

    nnoremap <buffer> <silent> q             :call <SID>smgr_Exit()<cr>
    nnoremap <buffer> <silent> <enter>       :call <SID>smgr_LoadSnippet( 1 )<cr>
    nnoremap <buffer> <silent> <2-leftmouse> :call <SID>smgr_LoadSnippet( 1 )<cr>
    nnoremap <buffer> <silent> l             :call <SID>smgr_LoadSnippet( 0 )<cr>
    nnoremap <buffer> <silent> u             :call <SID>smgr_UpdateSnippets()<cr>
    nnoremap <buffer> <silent> d             :call <SID>smgr_DeleteSnippet()<cr>
    nnoremap <buffer> <silent> r             :call <SID>smgr_RenameSnippet()<cr>
    nnoremap <buffer> <silent> e             :call <SID>smgr_EditSnippet()<cr>
    nnoremap <buffer> <silent> n             :call <SID>smgr_NewSnippet()<cr>

endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  ---                                                            **
"** remarks:                                                                **
"**   exit this script:                                                     **
"**     - Switch to buffer we are coming from. This closes the buffer       **
"**       of the user interface automatically.                              **
"*****************************************************************************
function <SID>smgr_Exit()

    execute( "buffer " . s:targetBufNr )
    
endfunction



"*****************************************************************************
"** input:   ---                                                            **
"** output:  snippet ID 0...N-1; N is number of snippets listed             **
"**          -1 if there is no snippet                                      **
"** remarks:                                                                **
"**   Calculate snippet ID from cursor position.                            **
"**   First line with snippet has ID 0.                                     **
"*****************************************************************************
function GetSnippetID()

    let l:snippetID = -1

    if ( len( s:fileList ) >= 1 )     " are there any snippets?

        if ( line(".") >= s:lineNrFirstSnippet ) && ( line(".") <= s:lineNrLastSnippet )

            let l:snippetID = line(".") - s:lineNrFirstSnippet      " get index of snippet in file list
        endif
    endif

    return l:snippetID
endfunction



"*****************************************************************************
"** input:   szPrompt: text for prompt                                      **
"**          szText: default input                                          **
"** output:  input string                                                   **
"** remarks:                                                                **
"**   prompt for user input                                                 **
"*****************************************************************************
function Input ( szPrompt, szText )
	echohl Question

	call inputsave()					     	   " preserve typeahead
	let	l:szInput = input( a:szPrompt, a:szText )  " read input
	call inputrestore()							   " restore typeahead

	echohl None									   " reset highlighting

	return l:szInput
endfunction



"*****************************************************************************
"** input:   errNr: number which defines an error (> 0)                     **
"**          text: addition text for some message, if not used, set it ""   **
"** output:  none                                                           **
"** remarks:                                                                **
"**   this function prints an error-msg                                     **
"*****************************************************************************
function s:Error( errNr, text )
    echohl WarningMsg

    if ( a:errNr == 1 )
        echo s:scriptName.": no buffer to insert snippet - try again with none-empty buffer"
    elseif ( a:errNr == 2 )
        echo s:scriptName.": buffer to insert snippet does not exist"
    elseif ( a:errNr == 3 )
        echo s:scriptName.": snippets directory not found: ".a:text
    elseif ( a:errNr == 4 )
        echo s:scriptName.": snippet file not found or no rights to read: ".a:text
    elseif ( a:errNr == 5 )
        echo s:scriptName.": internal error: bad snippet ID"
    elseif ( a:errNr == 6 )
        echo s:scriptName.": rename failed: ".a:text
    elseif ( a:errNr == 7 )
        echo s:scriptName.": file already exists"
    elseif ( a:errNr == 8 )
        echo s:scriptName.": delete failed: ".a:text
    elseif ( a:errNr == 9 )
        echo s:scriptName.": can\'t create file: ".a:text
    else
        echo s:scriptName.": unknown error occured"
    endif

    echohl None
endfunction



"*** EOF **
