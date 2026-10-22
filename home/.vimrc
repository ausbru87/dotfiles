" ~/.vimrc
" Vim configuration file

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General Settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible              " Don't try to be vi compatible
filetype off                  " Disable filetype detection temporarily

" Enable filetype plugins
filetype plugin indent on

" Set encoding
set encoding=utf-8
set fileencoding=utf-8

" Enable syntax highlighting
syntax enable
syntax on

" Set leader key to space
let mapleader = " "
let maplocalleader = " "

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug Plugin Manager
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugin list
call plug#begin('~/.vim/plugged')

" File navigation and search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'

" Git integration
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Code completion and linting
Plug 'dense-analysis/ale'

" Syntax and language support
Plug 'sheerun/vim-polyglot'

" Color schemes
Plug 'morhetz/gruvbox'
Plug 'arcticicestudio/nord-vim'
Plug 'dracula/vim', { 'as': 'dracula' }

" Editing enhancements
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-repeat'

" Code snippets
Plug 'honza/vim-snippets'

" Markdown
Plug 'plasticboy/vim-markdown'

" YAML
Plug 'stephpy/vim-yaml'

" Docker
Plug 'ekalinin/Dockerfile.vim'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Appearance
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Enable 24-bit RGB colors
if has('termguicolors')
  set termguicolors
endif

" Set color scheme
set background=dark
colorscheme gruvbox
" Alternative: colorscheme nord
" Alternative: colorscheme dracula

" Show line numbers
set number
set relativenumber

" Show cursor line
set cursorline

" Show command in bottom bar
set showcmd

" Highlight matching parentheses
set showmatch

" Display ruler
set ruler

" Always show status line
set laststatus=2

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Indentation and Formatting
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use spaces instead of tabs
set expandtab

" Tab width
set tabstop=2
set softtabstop=2
set shiftwidth=2

" Auto indent
set autoindent
set smartindent

" Wrap lines
set wrap
set linebreak

" Show invisible characters
set list
set listchars=tab:→\ ,trail:·,nbsp:␣

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Case insensitive search
set ignorecase
set smartcase

" Highlight search results
set hlsearch

" Incremental search
set incsearch

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Performance
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Faster redrawing
set ttyfast

" Only redraw when necessary
set lazyredraw

" Reduce updatetime for better UX
set updatetime=300

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Files and Backups
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Disable backup files
set nobackup
set nowritebackup

" Enable persistent undo
set undofile
set undodir=~/.vim/undo
if !isdirectory(&undodir)
  call mkdir(&undodir, 'p')
endif

" Auto-reload files when changed outside vim
set autoread

" Disable swap files
set noswapfile

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Key Mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Save file
nnoremap <leader>w :w<CR>

" Quit
nnoremap <leader>q :q<CR>

" Save and quit
nnoremap <leader>x :x<CR>

" Force quit without saving
nnoremap <leader>Q :q!<CR>

" Move between splits
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <leader>= :vertical resize +5<CR>
nnoremap <leader>- :vertical resize -5<CR>

" Move lines up and down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Better indenting in visual mode
vnoremap < <gv
vnoremap > >gv

" Copy to system clipboard
vnoremap <leader>y "+y
nnoremap <leader>Y "+yg_
nnoremap <leader>yy "+yy

" Paste from system clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P

" Quick edit and source vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.git$', '\.DS_Store$', '\.pyc$', '__pycache__']

" FZF
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>l :Lines<CR>
nnoremap <leader>h :History<CR>

" vim-airline
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#branch#enabled = 1

" ALE (Linting)
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'typescript': ['eslint', 'tsserver'],
\   'python': ['flake8', 'pylint'],
\   'go': ['gopls', 'golint'],
\   'rust': ['rls'],
\}
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint', 'prettier'],
\   'typescript': ['eslint', 'prettier'],
\   'python': ['black', 'isort'],
\   'go': ['gofmt'],
\}
let g:ale_fix_on_save = 0
nnoremap <leader>af :ALEFix<CR>

" vim-fugitive (Git)
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gd :Gdiff<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gl :Git log<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

augroup general
  autocmd!
  " Remove trailing whitespace on save
  autocmd BufWritePre * :%s/\s\+$//e

  " Return to last edit position when opening files
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  " Auto-source vimrc on save
  autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

augroup filetype_specific
  autocmd!
  " Python: 4 spaces
  autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4

  " Go: tabs
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4

  " Markdown: wrap text
  autocmd FileType markdown setlocal wrap linebreak

  " YAML: 2 spaces
  autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Enable mouse support
set mouse=a

" Split windows below and to the right
set splitbelow
set splitright

" Faster scrolling
set scrolloff=8
set sidescrolloff=8

" Command line completion
set wildmenu
set wildmode=longest:full,full

" Ignore certain files
set wildignore+=*.pyc,*.o,*.obj,*.swp,*.class,*.DS_Store,*/node_modules/*,*/dist/*

" Better completion
set completeopt=menuone,noinsert,noselect

" Don't show mode (airline shows it)
set noshowmode

" Enable code folding
set foldenable
set foldlevelstart=10
set foldmethod=indent

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Local Overrides
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Load local vimrc if it exists
if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif
