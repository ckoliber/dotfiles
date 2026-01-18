" ===== Minimal Vimrc =====

set nocompatible
syntax on
filetype plugin indent on

" --- UI ---
set number
set cursorline
set background=dark
colorscheme default
set termguicolors

" --- Editing ---
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent

" --- Search ---
set ignorecase
set smartcase
set incsearch
set hlsearch

nnoremap <Esc> :nohlsearch<CR>

" --- Quality of life ---
set hidden
set mouse=a
set clipboard=unnamed,unnamedplus
