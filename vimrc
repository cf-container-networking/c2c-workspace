" Plug for plugins
call plug#begin('~/.vim/plugged')

" Ruby/Rails highlighting + helpers
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
Plug 'thoughtbot/vim-rspec', { 'for': 'ruby' }

" All the colorschemes
Plug 'flazz/vim-colorschemes'

" File navigation
Plug 'ctrlpvim/ctrlp.vim'

" Git Commands
Plug 'tpope/vim-fugitive'

" Lets do go development
Plug 'fatih/vim-go'

" Nevoim specific plugins
Plug 'benekastah/neomake'
Plug 'Shougo/deoplete.nvim'

" Pairs of handy bracket mappings
Plug 'tpope/vim-unimpaired'

" Searching with AG
Plug 'rking/ag.vim'

" Make commenting easier
Plug 'tpope/vim-commentary'

" improved Javascript indentation and syntax
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }

" make netrw way better
Plug 'tpope/vim-vinegar'

" adds airline for bottom status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" the git gutter for changes
Plug 'airblade/vim-gitgutter'

" hcl syntax
Plug 'fatih/vim-hclfmt'

call plug#end()

" Syntax highlighting FTW
syntax on

" Set background to dark for base16
set background=dark

" Move swp to a standard location
set directory=/tmp

" Setting Spacing and Indent (plus line no)
set nu
set tabstop=2 shiftwidth=2 expandtab
set ts=2
set nowrap

" Remap the leader key
:let mapleader = ','

" yank to clipboard alias
vnoremap <leader>y "*y

" Set 256 colors
set t_Co=256
set guifont=Inconsolata:h16

set listchars=tab:\ \ ,trail:█
set list

" Go Declaration
au FileType go nmap gd <Plug>(go-def)
let g:go_fmt_command = "goimports"

" Turn on go-implements
au FileType go nmap <Leader>s <Plug>(go-implements)

" Turn on go-rename
au FileType go nmap <Leader>e <Plug>(go-rename)

" Make YAML Great Again
autocmd FileType yaml setlocal indentexpr=

" Amp up the syntax highlighting in vim-go
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_interfaces = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" Use deoplete.
let g:deoplete#enable_at_startup = 1

" Take over Tab for deoplete
" <Tab> completion:
" 1. If popup menu is visible, select and insert next item
" 2. Otherwise, if preceding chars are whitespace, insert tab char
" 3. Otherwise, start manual autocomplete
imap <silent><expr><Tab>
  \ pumvisible() ? "\<C-n>"
  \ : (<SID>is_whitespace() ? "\<Tab>"
  \ : deoplete#mappings#manual_complete())

smap <silent><expr><Tab>
  \ pumvisible() ? "\<C-n>"
  \ : (<SID>is_whitespace() ? "\<Tab>"
  \ : deoplete#mappings#manual_complete())

inoremap <expr><S-Tab>  pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:is_whitespace() "{{{
  let col = col('.') - 1
  return ! col || getline('.')[col - 1] =~? '\s'
endfunction "}}}

" Make deoplete insert a line when closing prompt
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function() abort
  return deoplete#mappings#close_popup() . "\<CR>"
endfunction

:let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
