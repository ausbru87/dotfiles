" ~/.vimrc - Vim configuration for Coder workspaces
" Optimized for Terraform/IaC development

" ==============================================================================
" General Settings
" ==============================================================================
set nocompatible              " Be iMproved
filetype plugin indent on     " Enable file type detection
syntax enable                 " Enable syntax highlighting

" Encoding
set encoding=utf-8
set fileencoding=utf-8

" UI Settings
set number                    " Show line numbers
set relativenumber            " Relative line numbers
set cursorline                " Highlight current line
set showmatch                 " Show matching brackets
set showcmd                   " Show command in bottom bar
set wildmenu                  " Visual autocomplete for command menu
set wildmode=longest:full,full
set laststatus=2              " Always show status line
set ruler                     " Show cursor position
set scrolloff=8               " Keep 8 lines above/below cursor
set sidescrolloff=8           " Keep 8 columns left/right of cursor
set signcolumn=yes            " Always show sign column

" Search
set incsearch                 " Incremental search
set hlsearch                  " Highlight search results
set ignorecase                " Case insensitive search...
set smartcase                 " ...unless uppercase used

" Tabs and Indentation
set tabstop=2                 " Tab width
set shiftwidth=2              " Indent width
set softtabstop=2             " Backspace through expanded tabs
set expandtab                 " Use spaces instead of tabs
set smartindent               " Smart auto-indenting
set autoindent                " Auto-indent new lines

" Performance
set lazyredraw                " Don't redraw during macros
set ttyfast                   " Faster terminal output
set updatetime=300            " Faster completion

" Backup and Undo
set nobackup                  " No backup files
set nowritebackup             " No backup before overwriting
set noswapfile                " No swap files
set undofile                  " Persistent undo
set undodir=~/.vim/undodir    " Undo directory

" Create undo directory if it doesn't exist
if !isdirectory(expand('~/.vim/undodir'))
    call mkdir(expand('~/.vim/undodir'), 'p')
endif

" Clipboard
if has('clipboard')
    set clipboard=unnamedplus   " Use system clipboard
endif

" Splits
set splitbelow                " Horizontal splits below
set splitright                " Vertical splits to the right

" Line wrapping
set nowrap                    " Don't wrap lines
set linebreak                 " Break lines at word boundaries

" Whitespace
set list                      " Show whitespace characters
set listchars=tab:▸\ ,trail:·,nbsp:␣,extends:❯,precedes:❮

" Auto-reload files
set autoread                  " Auto-reload changed files
au FocusGained,BufEnter * checktime

" ==============================================================================
" File Type Settings
" ==============================================================================

" Terraform/HCL
au BufNewFile,BufRead *.tf,*.tfvars setlocal filetype=terraform
au BufNewFile,BufRead *.hcl setlocal filetype=hcl
au FileType terraform setlocal tabstop=2 shiftwidth=2 expandtab
au FileType terraform setlocal commentstring=#\ %s

" Terragrunt
au BufNewFile,BufRead terragrunt.hcl setlocal filetype=terraform

" YAML (for K8s manifests, Ansible, etc.)
au FileType yaml setlocal tabstop=2 shiftwidth=2 expandtab
au FileType yaml setlocal commentstring=#\ %s

" JSON
au FileType json setlocal tabstop=2 shiftwidth=2 expandtab
au FileType json setlocal conceallevel=0

" Shell scripts
au FileType sh,bash setlocal tabstop=4 shiftwidth=4 expandtab

" Python (for CDK, etc.)
au FileType python setlocal tabstop=4 shiftwidth=4 expandtab

" TypeScript/JavaScript (for CDK)
au FileType typescript,javascript setlocal tabstop=2 shiftwidth=2 expandtab

" Markdown
au FileType markdown setlocal wrap linebreak spell

" Docker
au BufNewFile,BufRead Dockerfile* setlocal filetype=dockerfile

" ==============================================================================
" Key Mappings
" ==============================================================================

" Leader key
let mapleader = " "

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Clear search highlighting
nnoremap <leader><space> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize windows
nnoremap <C-Up> :resize +2<CR>
nnoremap <C-Down> :resize -2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" Move lines up/down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Stay in indent mode
vnoremap < <gv
vnoremap > >gv

" Better yank behavior
nnoremap Y y$

" Center cursor after navigation
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Quick buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>
nnoremap <leader>bd :bdelete<CR>

" Tab navigation
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <Tab> :tabnext<CR>
nnoremap <S-Tab> :tabprev<CR>

" Quick access to common files
nnoremap <leader>ev :e ~/.vimrc<CR>
nnoremap <leader>eb :e ~/.bashrc<CR>
nnoremap <leader>et :e ~/.bash_terraform<CR>

" Toggle settings
nnoremap <leader>tw :set wrap!<CR>
nnoremap <leader>tn :set number!<CR>
nnoremap <leader>tr :set relativenumber!<CR>

" ==============================================================================
" Terraform/IaC Shortcuts
" ==============================================================================

" Terraform commands
nnoremap <leader>ti :!terraform init<CR>
nnoremap <leader>tp :!terraform plan<CR>
nnoremap <leader>ta :!terraform apply<CR>
nnoremap <leader>tv :!terraform validate<CR>
nnoremap <leader>tf :!terraform fmt %<CR>:e<CR>

" Terragrunt commands
nnoremap <leader>gi :!terragrunt init<CR>
nnoremap <leader>gp :!terragrunt plan<CR>
nnoremap <leader>ga :!terragrunt apply<CR>
nnoremap <leader>gf :!terragrunt hclfmt<CR>:e<CR>

" Format current terraform file
autocmd FileType terraform nnoremap <buffer> <leader>F :!terraform fmt %<CR>:e<CR>

" ==============================================================================
" Status Line
" ==============================================================================

" Custom status line (if no plugin)
set statusline=
set statusline+=%#PmenuSel#
set statusline+=\ %{&modified?'[+]':''}
set statusline+=\ %f
set statusline+=%=
set statusline+=%#CursorColumn#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\ [%{&fileformat}\]
set statusline+=\ %l:%c
set statusline+=\ %p%%
set statusline+=\ 

" ==============================================================================
" Color Scheme
" ==============================================================================

" Use 256 colors if available
if &term =~ '256color'
    set t_Co=256
endif

" Enable true colors if available
if has('termguicolors')
    set termguicolors
endif

" Simple color scheme that works everywhere
colorscheme default
set background=dark

" Custom highlights for terraform files
highlight link terraformBlockType Statement
highlight link terraformBraces Delimiter

" ==============================================================================
" Netrw (File Explorer)
" ==============================================================================
let g:netrw_banner = 0          " Hide banner
let g:netrw_liststyle = 3       " Tree view
let g:netrw_browse_split = 4    " Open in previous window
let g:netrw_winsize = 25        " 25% width

" Toggle file explorer
nnoremap <leader>e :Lexplore<CR>

" ==============================================================================
" Auto Commands
" ==============================================================================

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Auto-format terraform files on save (if terraform is available)
autocmd BufWritePre *.tf if executable('terraform') | silent! execute '!terraform fmt %' | edit | endif

" Return to last edit position when opening files
autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \     exe "normal! g`\"" |
    \ endif

" ==============================================================================
" Plugin Configuration (if vim-plug is installed)
" ==============================================================================

" Install vim-plug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Check if vim-plug exists before calling
if filereadable(expand('~/.vim/autoload/plug.vim'))
    call plug#begin('~/.vim/plugged')

    " Essential plugins
    Plug 'tpope/vim-sensible'           " Sensible defaults
    Plug 'tpope/vim-commentary'         " Easy commenting
    Plug 'tpope/vim-surround'           " Surround text objects
    Plug 'tpope/vim-fugitive'           " Git integration
    Plug 'airblade/vim-gitgutter'       " Git diff in gutter

    " File navigation
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Terraform/HCL
    Plug 'hashivim/vim-terraform'       " Terraform syntax and commands
    Plug 'juliosueiras/vim-terraform-completion'

    " YAML
    Plug 'stephpy/vim-yaml'

    " Color schemes
    Plug 'gruvbox-community/gruvbox'

    call plug#end()

    " Plugin-specific settings
    if isdirectory(expand('~/.vim/plugged/gruvbox'))
        colorscheme gruvbox
    endif

    " vim-terraform settings
    let g:terraform_fmt_on_save = 1
    let g:terraform_align = 1
    let g:terraform_fold_sections = 1

    " FZF settings
    nnoremap <leader>ff :Files<CR>
    nnoremap <leader>fg :GFiles<CR>
    nnoremap <leader>fb :Buffers<CR>
    nnoremap <leader>fr :Rg<CR>
endif
