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

" ultisnips
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" fzf
Plug 'junegunn/fzf'

call plug#end()

" Syntax highlighting FTW
syntax on

" Set background to dark for base16
set background=dark

" Set colorscheme to hybrid
colorscheme hybrid

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

" MULTIPURPOSE TAB KEY
" Indent if we're at the beginning of a line. Else, do completion.
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction
inoremap <tab> <c-r>=InsertTabWrapper()<cr>
inoremap <s-tab> <c-n>

let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" Clear search results
nnoremap <silent> <space> :nohlsearch<CR>

" fzf
nnoremap <leader>f :FZF<CR>
