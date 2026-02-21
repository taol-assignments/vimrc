vim9script

# =============================================================================
# VIM CONFIGURATION (MacVim & Windows GVim)
# =============================================================================
# Designed for Vim 9 using pure Vim9script.
# This configuration focuses on cross-platform stability, modern features 
# (LSP, AI), and discoverable keybindings via Which-Key.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Fundamental Setup & Bootstrapping
# -----------------------------------------------------------------------------

# Detect platform and define the dynamic modifier key:
# 'D' corresponds to the Command key on MacVim.
# 'M' corresponds to the Alt key on Windows GVim.
var mod = has("gui_macvim") ? 'D' : 'M'

if has('win32')
  # On Windows, pressing Alt normally focuses the menu bar. 
  # We disable this to allow using <M-...> mappings for editor commands.
  set winaltkeys=no
endif

# Automated vim-plug installation:
# This ensures the configuration is self-contained and portable.
var config_dir = expand('<sfile>:p:h')
var plug_path = config_dir .. '/autoload/plug.vim'

if !filereadable(plug_path)
  echo "Installing vim-plug..."
  mkdir(config_dir .. '/autoload', 'p')
  var url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  if has('win32')
    system($'powershell -Command "Invoke-WebRequest -Uri {url} -OutFile {plug_path}"')
  else
    system($'curl -fLo {plug_path} {url}')
  endif
  # Re-source vimrc after installation to initialize the plugin manager immediately.
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

# -----------------------------------------------------------------------------
# 2. Plugin Management (vim-plug)
# -----------------------------------------------------------------------------

call plug#begin(config_dir .. '/plugged')
  # Project Navigation
  Plug 'mhinz/vim-startify'                # Start screen
  Plug 'lambdalisue/vim-fern'              # Asynchronous file explorer
  Plug 'lambdalisue/vim-fern-git-status'   # Git status indicators for Fern
  Plug 'lambdalisue/vim-fern-hijack'       # Make fern as the default browser
  
  # LSP & Code Intelligence
  Plug 'yegappan/lsp'                      # Native Vim9 LSP client
  
  # UI Enhancements
  Plug 'ap/vim-buftabline'                 # Buffers as tabs at the top
  Plug 'qpkorr/vim-bufkill'                # Delete buffers without closing windows (:BW)
  Plug 'markonm/traces.vim'                # Real-time preview for :substitute
  Plug 'airblade/vim-gitgutter'		   # Git diff indicators in the sign column
  
  # Menus & Discovery
  Plug 'liuchengxu/vim-which-key'          # Popup menu for keybinding discovery
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  
  # Language Support & Tools
  Plug 'fatih/vim-go'                      # Comprehensive Go support
  Plug 'tpope/vim-commentary'              # Rapid code commenting
  Plug 'tpope/vim-fugitive'                # Git wrapper extraordinaire
  
  # AI & Debugging
  Plug 'github/copilot.vim'                # GitHub Copilot completion
  Plug 'puremourning/vimspector'           # Graphical debugger (DAP)
call plug#end()

# -----------------------------------------------------------------------------
# 3. Core Vim Settings
# -----------------------------------------------------------------------------

set nu rnu             # Hybrid line numbers: absolute for current, relative for others
set laststatus=2       # Always show the status line for better visibility
set updatetime=300     # Responsiveness tweak for LSP highlights and AI triggers
set autoread           # Automatically reload files when changed externally
set signcolumn=yes     # Always show the sign column to prevent text shifting when diagnostics appear

# Hide sign column in specific filetypes where they are not useful.
autocmd FileType fugitive,fern setlocal signcolumn=no foldcolumn=0

# Silent Operation
set visualbell t_vb=   # Disable annoying visual/audio beeps
set novisualbell
set belloff=all

# Buffer Auto-Reload Logic:
def SafeCheckTime()
  # Avoid triggering reloads while in Command mode to prevent UI disruption.
  if mode() == 'c' || &buftype != '' || expand('%') == '' | return | endif
  checktime
enddef

augroup AutoReload
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * SafeCheckTime()
  autocmd FileChangedShellPost * echohl WarningMsg | echo "File updated externally" | echohl None
augroup END

# -----------------------------------------------------------------------------
# 4. UI & GUI Appearance
# -----------------------------------------------------------------------------

# Font strategy: Cascadia Code for modern systems, Monaco as fallback for Mac.
set guifont=Cascadia_Code:h12,Monaco:h12

if has("gui_running")
  # Visually track the cursor position, but only in the active window to
  # reduce distraction.
  augroup CursorLine
    au!
    au VimEnter * setlocal cursorline
    au WinEnter * setlocal cursorline
    au BufWinEnter * setlocal cursorline
    au WinLeave * setlocal nocursorline
  augroup END

  colorscheme desert
  
  # Clean UI: Remove scrollbars from the GUI window.
  set go-=l
  set go-=L
  set go-=r
  set go-=R
  set go-=T
  set go-=m

  if has("gui_macvim")
    # Release default MacVim menu shortcuts to allow re-mapping them in Vim.
    macmenu &File.Print key=<nop>
    macmenu &Edit.Find.Find… key=<nop>
    macmenu &File.Close key=<nop>
    
    # IME Smart Switching (MacVim): Reset input method to English on mode change.
    set noimdisable
    autocmd InsertEnter * set iminsert=1
    autocmd InsertLeave * set iminsert=0
    autocmd FocusGained * if mode() != 'i' && mode() != 'R' | set iminsert=0 | endif
  endif
endif

# -----------------------------------------------------------------------------
# 5. Integrated Feature Configurations
# -----------------------------------------------------------------------------

# --- LSP (yegappan/lsp) ---
var lspOpts = {
  showDiagWithSign: true,
  semanticHighlight: true,
  showInlayHints: false,
  autoHighlight: true,
  autoHighlightDiags: true,
}
autocmd User LspSetup call LspOptionsSet(lspOpts)

# Register LSP servers only if their binaries are detected in the system PATH.
var lspServers: list<dict<any>> = []
if executable('gopls')
  add(lspServers, { name: 'golang', filetype: ['go', 'gomod'], path: 'gopls', args: ['serve'], syncInit: v:true })
endif

var fsac_cmd = ''
if executable('fsautocomplete')
  fsac_cmd = 'fsautocomplete'
elseif executable(expand('~/.dotnet/tools/fsautocomplete'))
  fsac_cmd = expand('~/.dotnet/tools/fsautocomplete')
endif
if fsac_cmd != ''
  add(lspServers, {
    name: 'fsharp',
    filetype: ['fsharp'],
    path: fsac_cmd,
    args: [],
    initializationOptions: {AutomaticWorkspaceInit: true, TooltipShowDocumentationLink: false}
  })
endif

autocmd User LspSetup call LspAddServer(lspServers)

# --- UI Plugins ---
g:buftabline_numbers = 2 # Show buffer indices for number-key switching
g:buftabline_show = 1
g:buftabline_indicators = true

# Auto-balance window sizes when opening the side drawer.
autocmd BufWinEnter * if &filetype == 'fern' | wincmd = | vertical resize 30 | endif

g:fern#renderer#default#leaf_symbol      = '│  '
g:fern#renderer#default#collapsed_symbol = '├─ '
g:fern#renderer#default#expanded_symbol  = '└─ '
g:fern#default_hidden = 1

# --- Debugging ---
g:vimspector_enable_mappings = 'HUMAN'           # F5=Run, F10=Over, F11=Into

# -----------------------------------------------------------------------------
# 6. Keybindings System
# -----------------------------------------------------------------------------

# Set Leader key to Space
nnoremap <SPACE> <Nop>
g:mapleader = " "

# --- Direct Access Hotkeys (Muscle Memory) ---
# High-frequency actions remain instantly accessible.

# Navigation
nnoremap <silent> <C-l> :bnext<CR>
nnoremap <silent> <C-h> :bprev<CR>
nnoremap <silent> <C-t> :Fern . -drawer -toggle<CR>
nnoremap <silent> <leader>t :Fern . -drawer<CR>

# Search
nnoremap <silent> <leader><leader> :call fzf#vim#gitfiles('', {'options': '--no-preview --layout=reverse --info=inline'})<CR>
nnoremap <silent> <leader>f :call fzf#vim#ag('', {'options': '--layout=reverse --info=inline'})<CR>
vnoremap <silent> <leader>f "zy:call fzf#vim#ag(@z, {'options': '--layout=reverse --info=inline'})<CR>

# Tab Switching (Cmd/Alt + 1-9)
execute $"nnoremap <silent> <{mod}-w> :BW<CR>"
for i in range(1, 9)
  execute $"nmap <{mod}-{i}> <Plug>BufTabLine.Go({i})"
endfor
execute $"nmap <{mod}-0> <Plug>BufTabLine.Go(10)"

# Git Operations
nnoremap <silent> <leader>gs <Cmd>Git<CR>
nnoremap <silent> <leader>gd <Cmd>Gdiff<CR>
nnoremap <silent> <leader>gw <Cmd>Gwrite<CR>
nnoremap <silent> <leader>gb <Cmd>Git blame<CR>

nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)

# AI & Commenting
nnoremap <leader>ac :CopilotChatOpen<CR>
nnoremap <leader>af :CopilotChatFocus<CR>
nnoremap <leader>ar :CopilotChatReset<CR>
vmap <leader>aa <Plug>CopilotChatAddSelection
execute $"nmap <silent> <{mod}-/> <Plug>CommentaryLine"
execute $"xmap <silent> <{mod}-/> <Plug>Commentary"

# --- Discovery System (Which-Key) ---
# Lower-frequency commands are organized into a searchable menu.

g:which_key_use_floating_win = 1
g:which_key_floating_relative_win = 1

g:which_key_map = {
  ' ': 'Find Files',
  'f': 'Find in Project Root',
  '<F5>': 'Debug',
  '<F8>': 'Run to Cursor',
  '<F9>': 'Toggle Conditional Breakpoint',
  't': 'Open File Tree',
  'g': { 'name': '+Git', 's': 'Status Panel', 'd': 'Diff Split', 'w': 'Save & Stage', 'b': 'Line Blame' },
  'a': { 'name': '+AI (Copilot)', 'c': 'Open Chat', 'f': 'Focus Chat', 'r': 'Reset Conversation' },
  'l': { 'name': '+LSP', 'a': 'Code Actions', 'f': 'Format Document', 'o': 'Symbol Outline' }
}

g:which_key_map_visual = {
  'a': { 'name': '+AI', 'a': 'Add Selection to Chat' }
}

which_key#register(' ', 'g:which_key_map')
which_key#register(' ', 'g:which_key_map_visual', 'v')

nnoremap <silent> <leader> :<C-u>WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :<C-u>WhichKeyVisual '<Space>'<CR>

# --- Context-Sensitive LSP Mappings ---
def SetLspMappings()
  # Definitions & Usage
  nnoremap <buffer> <silent> <C-]> <Cmd>LspGotoDefinition<CR>
  nnoremap <buffer> <silent> gy    <Cmd>LspGotoTypeDef<CR>
  nnoremap <buffer> <silent> gi    <Cmd>LspGotoImpl<CR>
  nnoremap <buffer> <silent> <C-g> <Cmd>LspShowReferences<CR>
  
  # Popups & Refactoring
  execute $"nnoremap <buffer> <silent> <{mod}-k> <Cmd>LspHover<CR>"
  execute $"nnoremap <buffer> <silent> <{mod}-r> <Cmd>LspRename<CR>"
  
  # Diagnostics
  nnoremap <buffer> <silent> [d <Cmd>LspDiag prevWrap<CR>
  nnoremap <buffer> <silent> ]d <Cmd>LspDiag nextWrap<CR>
  nnoremap <buffer> <silent> gl <Cmd>LspDiag current<CR>
  
  # Standardized Leader Maps
  nnoremap <buffer> <silent> <leader>la <Cmd>LspCodeAction<CR>
  nnoremap <buffer> <silent> <leader>lf <Cmd>LspFormat<CR>
  nnoremap <buffer> <silent> <leader>lo <Cmd>LspDocumentSymbol<CR>
enddef

augroup LspKeybindings
  autocmd!
  autocmd User LspAttached SetLspMappings()
  autocmd FileType * if &buftype == '' | SetLspMappings() | endif
augroup END

# -----------------------------------------------------------------------------
# 7. Filetype Specifics
# -----------------------------------------------------------------------------

# --- Go (vim-go) ---
# Enable all syntax highlighting features for an IDE-like experience.
g:go_highlight_operators = 1
g:go_highlight_functions = 1
g:go_highlight_function_parameters = 1
g:go_highlight_function_calls = 1
g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_build_constraints = 1
g:go_highlight_generate_tags = 1
g:go_highlight_variable_declarations = 1
g:go_highlight_variable_assignments = 1
autocmd FileType go setlocal tabstop=2 shiftwidth=2 softtabstop=2 commentstring=//\ %s

# --- F# ---
# F# local indentation and commenting overrides.
autocmd FileType fsharp setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2 commentstring=//\ %s

# --- Help Files and Quick Fix ---
autocmd FileType help,qf setlocal signcolumn=no nu rnu

# -----------------------------------------------------------------------------
# 8. Start Screen
# -----------------------------------------------------------------------------
# Automatically save the session when leaving Vim
g:startify_session_persistence = 1

# Automatically load Session.vim
g:startify_session_autoload = 1

# Default bookmark
g:startify_bookmarks = [ {'c': $MYVIMRC} ]

# -----------------------------------------------------------------------------
# 9. Local & Private Overrides
# -----------------------------------------------------------------------------
# Load a local, machine-specific configuration file if it exists.
# This file is NOT committed to Git and is used for private settings like
# bookmarks, project-specific paths, or API keys.
var local_config = expand('<sfile>:p:h') .. '/vimrc.local'
if filereadable(local_config)
  source `=local_config`
endif
