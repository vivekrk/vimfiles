set nocompatible
source $VIMRUNTIME/vimrc_example.vim
source $VIMRUNTIME/mswin.vim
behave mswin

set background=dark
colorscheme slate

map <F5> :NERDTree<CR>

if has("gui_running")
  if has("gui_gtk2")
    set guifont=Monaco\ 10
  elseif has("gui_photon")
    set guifont=Monaco:s10
  elseif has("gui_kde")
    set guifont=Monaco/10/-1/5/50/0/0/0/1/0
  elseif has("x11")
    set guifont=-*-courier-medium-r-normal-*-*-180-*-*-m-*-*
  else
    set guifont=Monaco:h10:cDEFAULT
  endif
endif

"Change the paste keys
unmenu! Edit.Paste
aunmenu Edit.Paste
nnoremenu 20.360 &Edit.&Paste<Tab>Ctrl-V    	"+gP
cnoremenu    &Edit.&Paste<Tab>Ctrl-V		<C-R>+

"Change the copy keys
unmenu! Edit.Copy
aunmenu Edit.Copy
nnoremenu 20.360 &Edit.&Copy<Tab>Ctrl-C    	"+gC
cnoremenu    &Edit.&Copy<Tab>Ctrl-C		<C-R>+

"Change the undo keys
unmenu! Edit.Undo
aunmenu Edit.Undo
nnoremenu 20.360 &Edit.&Undo<Tab>Ctrl-Z    	"+gZ
cnoremenu    &Edit.&Undo<Tab>Ctrl-Z		<C-R>+

map <F7> mzgg=G`z<CR>
map <F4> <leader>c<space><CR>

"Filetype
set filetype=on
filetype plugin on
filetype indent on

inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O
inoremap {{     {
inoremap {}     {}

inoremap        (  ()<Left>
inoremap <expr> )  strpart(getline('.'), col('.')-1, 1) == ")" ? "\<Right>" : ")"

set ai
set ts=4
set sts=4
set et
set sw=4
set textwidth=79

autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType php set omnifunc=phpcomplete#CompletePHP

"Show line number
set number

set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction

"End of vimrc file
