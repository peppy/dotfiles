set hlsearch
set relativenumber
set number relativenumber
set incsearch
set ignorecase
set smartcase
set noshowmatch
set hidden
set noerrorbells
set linebreak

set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab

set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile

" fix out of memory when adding brackets to start of long markdown file
" (https://github.com/vim/vim/issues/2049)
set mmp=500000

set so=4

filetype off
syntax on

let mapleader = "'"

" set termguicolors

set t_Co=256
set background=dark
set updatetime=500

" omnisharp setup
let g:OmniSharp_server_stdio = 1
let g:OmniSharp_highlighting = 3

let g:omnicomplete_fetch_full_documentation = 1

" Add Vundle to runtime path
set rtp+=~/.vim/bundle/Vundle.vim
set rtp+=/opt/homebrew/opt/fzf

let g:gruvbox_invert_selection='0'

let g:WhiplashProjectsDir = "~/Projects/"
let g:WhiplashConfigDir = "~/.vim/whiplash"

autocmd VimEnter * hi Normal ctermbg=NONE guibg=NONE

" tmux title update
autocmd BufEnter * call system("tmux rename-window \"vim (" . expand("%:t") . ")\"")
autocmd VimLeave * call system("tmux rename-window fish")

call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'OmniSharp/omnisharp-vim'
Plugin 'dense-analysis/ale'
Plugin 'RRethy/vim-illuminate'
Plugin 'flazz/vim-colorschemes'
Plugin 'vim-airline/vim-airline'
Plugin 'morhetz/gruvbox'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-commentary'
Plugin 'junegunn/fzf.vim'
Plugin 'kien/rainbow_parentheses.vim'
Plugin 'machakann/vim-highlightedyank'
Plugin 'arkwright/vim-whiplash'
Plugin 'tpope/vim-obsession'
Plugin 'mg979/vim-visual-multi'
call vundle#end()

" colorscheme Tomorrow-Night
colorscheme gruvbox

filetype plugin indent on

let g:ale_linters = {
            \ 'cs': ['OmniSharp']
            \}

let g:highlightedyank_highlight_duration = 100

function! s:loadsession(dir)
    exe 'cd ~/Projects/' . a:dir
    silent! source .vimsession
    exe 'cd ~/Projects/' . a:dir
endfunction

function! s:savesession()
    Obsess .vimsession
endfunction

if argc() == 0 | silent! source .vimsession | endif

nnoremap <silent> <Leader>o :call <sid>savesession()<CR>:silent call fzf#run({'source': 'ls ~/Projects/', 'options': '--reverse --prompt "Projects "', 'down': 20, 'dir': '~/Projects/', 'sink': function('<sid>loadsession') })<CR>
nnoremap <Leader>u   :OmniSharpFindUsages<CR>
nnoremap <Leader>c   :OmniSharpFindUsages<CR>
nnoremap <Leader>v   :OmniSharpFindImplementations<CR>
nnoremap <Leader>d   :OmniSharpGotoDefinition<CR>
nnoremap <Leader>e   :ALENextWrap<CR>
nnoremap <Leader>x   :OmniSharpGotoDefinition<CR>
nnoremap <Leader>f   :OmniSharpCodeFormat<CR>
nnoremap <Leader>F   :Rg 
nnoremap <Leader>R   :OmniSharpRename<CR>
nnoremap <Leader>t   :GFiles<CR>
nnoremap <Leader>w   :w<CR>
nnoremap <Leader>Q   :q!<CR>
nnoremap <Leader>q   :call <sid>savesession()<CR>:q<CR>
nnoremap <Leader>k   :%bd<CR>

nnoremap <leader>p "+p

" Feels more symmetrical on ortholinear layouts.
noremap & ^
imap <C-BS> <C-W>

nmap <PageUp> <C-U>
nmap <PageDown> <C-D>

nnoremap <Space> <C-D>
nnoremap <S-Space> <C-U>

" In insert mode, C-U deletes line, but due to the above we probably don't
" want that..
inoremap <C-U> <Space>

" Copy to clipboard
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y

" Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P

nnoremap <Leader>,   :e ~/.vimrc<CR>:source ~/.vimrc<CR>

map <Leader>b :Buffers<CR>
map , :OmniSharpGetCodeActions<CR>

" window navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nnoremap <silent><Esc><Esc> :noh<CR>

" tab complete
inoremap <expr> <Tab> pumvisible() ? '<C-n>' :
            \ getline('.')[col('.')-2] =~# '[[:alnum:].-_#$]' ? '<C-x><C-o>' : '<Tab>'

augroup omnisharp_commands
  autocmd!

  " Show type information automatically when the cursor stops moving.
  " Note that the type is echoed to the Vim command line, and will overwrite
  " any other messages in this space including e.g. ALE linting messages.
  " autocmd CursorHold *.cs OmniSharpDocumentation

  " The following commands are contextual, based on the cursor position.
  autocmd FileType cs nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osfu <Plug>(omnisharp_find_usages)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osfi <Plug>(omnisharp_find_implementations)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>ospd <Plug>(omnisharp_preview_definition)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>ospi <Plug>(omnisharp_preview_implementations)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>ost <Plug>(omnisharp_type_lookup)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osd <Plug>(omnisharp_documentation)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osfs <Plug>(omnisharp_find_symbol)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osfx <Plug>(omnisharp_fix_usings)
  autocmd FileType cs nmap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
  autocmd FileType cs imap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)

  " Navigate up and down by method/property/field
  autocmd FileType cs nmap <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)
  autocmd FileType cs nmap <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)
  " Find all code errors/warnings for the current solution and populate the quickfix window
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osgcc <Plug>(omnisharp_global_code_check)
  " Contextual code actions (uses fzf, CtrlP or unite.vim when available)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osca <Plug>(omnisharp_code_actions)
  " autocmd FileType cs xmap <silent> <buffer> <Leader>osca <Plug>(omnisharp_code_actions)

  " autocmd FileType cs nmap <silent> <buffer> <Leader>os= <Plug>(omnisharp_code_format)

  " autocmd FileType cs nmap <silent> <buffer> <Leader>osnm <Plug>(omnisharp_rename)

  " autocmd FileType cs nmap <silent> <buffer> <Leader>osre <Plug>(omnisharp_restart_server)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>osst <Plug>(omnisharp_start_server)
  " autocmd FileType cs nmap <silent> <buffer> <Leader>ossp <Plug>(omnisharp_stop_server)
augroup END

autocmd FileType c,cpp,java,php,cs,md autocmd BufWritePre <buffer> %s/\s\+$//e
