" ================================
" Basic setup
" ================================
set nocompatible
set encoding=utf-8
filetype plugin indent on
syntax on

" ================================
" UI
" ================================
set number
set norelativenumber
set cursorline
set showcmd
set showmode
set ruler
set laststatus=2
set wildmenu
set lazyredraw
set ttyfast

" ================================
" Colors / Theme
" ================================
set termguicolors
set background=dark

let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_italic = 1
let g:gruvbox_bold = 1
let g:gruvbox_sign_column = 'bg0'

colorscheme gruvbox

" ================================
" Airline
" ================================
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'

" ================================
" Editing behavior
" ================================
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set smartindent
set autoindent

set wrap
set linebreak

set backspace=indent,eol,start
set clipboard=unnamedplus

" ================================
" Search
" ================================
set ignorecase
set smartcase
set incsearch
set hlsearch

" Clear search highlight
nnoremap <silent> <Esc> :nohlsearch<CR>

" ================================
" Performance
" ================================
set updatetime=300
set timeoutlen=500

" ================================
" Files
" ================================
set hidden
set autoread
set nobackup
set nowritebackup
set noswapfile

" ================================
" Splits
" ================================
set splitbelow
set splitright
