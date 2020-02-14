scriptencoding utf-8
set encoding=utf-8

" ============================================================================
" Initialize plugins
" ============================================================================
call plug#begin('~/.local/share/nvim/plugged')

" Editor
Plug 'NLKNguyen/papercolor-theme'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'jlanzarotta/bufexplorer' " not sure if this is needed anymore (fzf)
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'

" Git
Plug 'airblade/vim-gitgutter'

" Language
Plug 'fatih/vim-go'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

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
set background=dark
colorscheme PaperColor

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
set fillchars+=vert:\
hi VertSplit ctermbg=NONE guibg=NONE

" Italicize comments
highlight Comment cterm=italic gui=italic

" Set line height
set linespace=4

" Disable bell banners
" set noerrorbells novisualbell t_vb


" ============================================================================
"  Maps
" ============================================================================
nmap <silent> <leader>V :source ~/.config/nvim/init.vim <cr>:filetype detect<cr>
nmap <silent> <leader>bh <cr>:bprevious<cr>
nmap <silent> <leader>bl <cr>:bnext<cr>
" fzf
nnoremap <C-p> :Files<Cr>
nnoremap <C-g> :Rg<Cr>

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
"  Function
" ============================================================================
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun
command! TrimWhitespace call TrimWhitespace()


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

" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0

" ============================================================================
"  Plugins
" ============================================================================

" ----- NERDTree -----
nmap <silent> <C-E> :NERDTreeToggle<CR>
let NERDTreeIgnore=['\~$', 'node_modules[[dir]]',  'dist[[dir]]', 'venv[[dir]]', '\.pyc$']


" ============================================================================
" coc.nvim
" ============================================================================

" if hidden is not set, TextEdit might fail.
set hidden
" Better display for messages
set cmdheight=2
" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use U to show documentation in preview window
nnoremap <silent> U :call <SID>show_documentation()<CR>

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
