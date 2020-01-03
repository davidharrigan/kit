scriptencoding utf-8
set encoding=utf-8

" ============================================================================
" Initialize plugins
" ============================================================================
call plug#begin('~/.local/share/nvim/plugged')

" Editor
Plug 'nathanaelkane/vim-indent-guides'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }

" Git
Plug 'airblade/vim-gitgutter'

" Language
Plug 'fatih/vim-go'

call plug#end()


" ============================================================================
" Editor config
" ============================================================================
let mapleader=","

set wildignore=*.swp,*.pyc
set nobackup
set noswapfile
set scrolloff=15

set number

" Color settings
set t_Co=256
let g:rehash256=1

" Allow mouse control
set mouse=a

" Highlight current line
set cursorline
hi CursorLine cterm=NONE ctermbg=238
highlight LineNr ctermfg=7

" Color column
set colorcolumn=120

" Set automatic indentation
set autoindent
set smartindent

" Set tabs at 4 spaces
set cindent
set sw=4 ts=4 et
set hlsearch
set incsearch

" Syntax highlighting
syntax enable
syntax on

" Set some nice character listings, then activate list
set list listchars=tab:⟶\ ,trail:·,extends:>,precedes:<

" Show matching brackets
set showmatch

" Spell check on
set spell spelllang=en_us
setlocal spell spelllang=en_us

" Style vertical split bar
" set fillchars+=vert:│
set fillchars+=vert:\ 
hi VertSplit ctermbg=NONE guibg=NONE

" Italicize comments
highlight Comment cterm=italic gui=itali

" Set line height
set linespace=4

" Disable bell banners
set noerrorbells novisualbell t_vb

" ============================================================================
"  Maps
" ============================================================================
nmap <silent> <leader>V :source ~/.vimrc <cr>:filetype detect<cr>
nmap <silent> <leader>bh <cr>:bprevious<cr>
nmap <silent> <leader>bl <cr>:bnext<cr>

" Toggle spelling with the F7 key
nmap <silent> <F7> :setlocal spell! spelllang=en_us<cr>

" nnoremap <silent> <leader>tb :TagbarToggle<CR>

" Spelling
highlight clear SpellBad
highlight SpellBad term=standout ctermfg=1 term=underline cterm=underline
highlight clear SpellCap
highlight SpellCap term=underline cterm=underline
highlight clear SpellRare
highlight SpellRare term=underline cterm=underline
highlight clear SpellLocal
highlight SpellLocal term=underline cterm=underline

" where it should get the dictionary files
let g:spellfile_URL = 'http://ftp.vim.org/vim/runtime/spell'

" Set title of window to file name
set title

" Toggle paste
set pastetoggle=<F2>

" ============================================================================
"  Language
" ============================================================================

" ----- Go -----
" use goimports for formatting
let g:go_fmt_command = "goimports"

" turn highlighting on
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" ============================================================================
"  Plugins
" ============================================================================

" ----- NERDTree -----
nmap <silent> <C-E> :NERDTreeToggle<CR>
let NERDTreeIgnore=['\~$', 'node_modules[[dir]]',  'dist[[dir]]', 'venv[[dir]]', '\.pyc$']

