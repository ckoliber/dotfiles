" ============================================================================
"  ███╗   ███╗██╗███╗   ███╗
"  ████╗ ████║██║████╗ ████║   A small, sharp vimrc.
"  ██╔████╔██║██║██╔████╔██║   Fast. Hacky. Portable.
"  ██║╚██╔╝██║██║██║╚██╔╝██║
"  ██║ ╚═╝ ██║██║██║ ╚═╝ ██║   No nonsense. No plugins required.
"  ╚═╝     ╚═╝╚═╝╚═╝     ╚═╝
" ============================================================================

" --- paranoia ---------------------------------------------------------------
set nocompatible
set hidden
set autoread
set shortmess+=c
set updatetime=300
set timeoutlen=500

" --- encoding ---------------------------------------------------------------
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,latin1

" --- UI ---------------------------------------------------------------------
set number
set relativenumber
set cursorline
set showcmd
set ruler
set laststatus=2
set signcolumn=yes
set scrolloff=8
set sidescrolloff=8
set wrap
set linebreak
set breakindent
set termguicolors

" --- colors (works even over SSH) -------------------------------------------
if &t_Co >= 256 || has("termguicolors")
  colorscheme desert
endif

" Subtle highlights
hi CursorLine   cterm=NONE ctermbg=236
hi LineNr       ctermfg=244
hi Comment      ctermfg=245
hi Visual       ctermbg=237

" --- editing ---------------------------------------------------------------
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2
set smartindent
set autoindent
set backspace=indent,eol,start
set formatoptions+=j

" --- searching -------------------------------------------------------------
set ignorecase
set smartcase
set incsearch
set hlsearch

nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" --- file handling ----------------------------------------------------------
set undofile
set undodir=~/.vim/undo//
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" Create dirs if missing (pure vim hack)
silent! call mkdir(&undodir, "p")
silent! call mkdir(&backupdir, "p")
silent! call mkdir(&directory, "p")

" --- movement hacks ---------------------------------------------------------
" Move by visual lines, not logical ones
nnoremap j gj
nnoremap k gk

" Faster navigation
nnoremap H ^
nnoremap L $

" --- leader ---------------------------------------------------------------
let mapleader = " "

" Files & buffers
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :qa!<CR>
nnoremap <leader>b :ls<CR>:b<Space>

" --- clipboard -------------------------------------------------------------
" Be polite to the system clipboard if available
if has("clipboard")
  set clipboard=unnamedplus
endif

" --- terminal sanity --------------------------------------------------------
if &term =~ 'xterm\|screen\|tmux'
  set ttimeout
  set ttimeoutlen=10
endif

" --- statusline (pure vim, no plugins) -------------------------------------
set statusline=
set statusline+=\ %f
set statusline+=%m
set statusline+=%r
set statusline+=%=
set statusline+=\ [%{&filetype}]
set statusline+=\ %l:%c

" --- autosave like a gremlin -----------------------------------------------
augroup autosave
  autocmd!
  autocmd InsertLeave,TextChanged * silent! wall
augroup END

" --- yank flash -------------------------------------------------------------
augroup yankflash
  autocmd!
  autocmd TextYankPost * silent! lua << EOF
    vim.highlight.on_yank { timeout = 150 }
EOF
augroup END

" --- trailing whitespace is a crime ----------------------------------------
nnoremap <leader>x :%s/\s\+$//e<CR>

" --- smart defaults per filetype -------------------------------------------
augroup ft
  autocmd!
  autocmd FileType make setlocal noexpandtab
  autocmd FileType yaml setlocal ts=2 sw=2
  autocmd FileType python setlocal ts=4 sw=4
augroup END

" --- quick scratch buffer --------------------------------------------------
nnoremap <leader>s :enew<CR>:setlocal buftype=nofile bufhidden=hide noswapfile<CR>

" --- vim as pager -----------------------------------------------------------
command! -nargs=0 Pager setlocal nonumber norelativenumber nospell nowrap

" --- exit like a civilized human ------------------------------------------
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev WQ wq
cnoreabbrev Wq wq

" ============================================================================
"  Vim is not an editor.
"  It is a state of mind.
" ============================================================================
