vim9script

# =============================================================================
# VIM CONFIGURATION (MacVim & Windows GVim)
# =============================================================================

# ==========================================
# 0. Bootstrapping vim-plug
# ==========================================
# Automatically download and install vim-plug if it's missing.
var config_dir = expand('<sfile>:p:h')
var plug_path = config_dir .. '/autoload/plug.vim'

if !filereadable(plug_path)
  echo "Downloading vim-plug..."
  mkdir(config_dir .. '/autoload', 'p')
  var url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  if has('win32')
    # Use PowerShell on Windows if curl is not available
    system($'powershell -Command "Invoke-WebRequest -Uri {url} -OutFile {plug_path}"')
  else
    system($'curl -fLo {plug_path} {url}')
  endif

  # Trigger plugin installation on first startup after manager is downloaded
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

# ==========================================
# 1. Platform & Environment Detection
# ==========================================
# Use Command key (D) on Mac and Alt key (M) on Windows for GUI shortcuts
var mod = has("gui_macvim") ? 'D' : 'M'

if has('win32')
  # Prevent Alt key from focusing the system menu in Windows GVim
  set winaltkeys=no
endif

# ==========================================
# 2. Plugin Management (vim-plug)
# ==========================================
# All plugins are stored in the 'plugged' subdirectory
call plug#begin(config_dir .. '/plugged')
  # --- UI & Core Components ---
  Plug 'lambdalisue/vim-fern'              # Asynchronous project drawer
  Plug 'lambdalisue/vim-fern-git-status'   # Git integration for Fern
  Plug 'yegappan/lsp'                      # Native Vim LSP client (Vim9)
  Plug 'ap/vim-buftabline'                 # Display buffers as tabs at the top
  Plug 'qpkorr/vim-bufkill'                # Delete buffers without closing windows
  
  # --- Navigation & Menus ---
  Plug 'skywind3000/vim-quickui'           # UI engine for popups
  Plug 'skywind3000/vim-navigator'         # Keybinding discovery menu (Leader menu)
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'markonm/traces.vim'                # Real-time preview for :substitute (Mac)

  # --- Language Support ---
  Plug 'fatih/vim-go'                      # Go development environment
  Plug 'tpope/vim-commentary'              # Efficient commenting logic
  
  # --- Git Workflow ---
  Plug 'tpope/vim-fugitive'                # Git wrapper inside Vim

  # --- AI & Modern Debugging ---
  Plug 'github/copilot.vim'                # GitHub Copilot (AI Completion)
  Plug 'DanBradbury/copilot-chat.vim'      # Interactive Copilot Chat window
  Plug 'puremourning/vimspector'           # Multi-language graphical debugger
call plug#end()


# ==========================================
# 3. General Settings
# ==========================================
set nu rnu             # Hybrid line numbers (current: absolute, others: relative)
set laststatus=2       # Always display the status line
set updatetime=300     # Faster responsiveness for LSP and Copilot
set visualbell t_vb=   # Silence audio and visual bells
set novisualbell
set belloff=all

# --- IME switching (MacVim Specific) ---
# Automatically switch input method to English when leaving Insert mode
if has("gui_macvim")
  set noimdisable
  autocmd InsertEnter * set iminsert=1
  autocmd InsertLeave * set iminsert=0
  autocmd FocusGained * if mode() != 'i' && mode() != 'R' | set iminsert=0 | endif
endif


# ==========================================
# 4. UI & GUI Settings
# ==========================================
# Fallback font chain: Windows/Generic -> Mac standard
set guifont=Cascadia_Code:h12,Monaco:h12

if has("gui_running")
  set cursorline       # Highlight the current line
  colorscheme evening  # Default high-contrast dark theme
  set go-=l            # Hide GUI scrollbars
  set go-=L
  set go-=r
  set go-=R

  # Unbind default system shortcuts to prevent conflicts with Vim mappings
  if has("gui_macvim")
    macmenu &File.Print key=<nop>
    macmenu &Edit.Find.Find… key=<nop>
    macmenu &File.Close key=<nop>
  endif
endif


# ==========================================
# 5. Global Hotkeys (Direct Access)
# ==========================================
nnoremap <SPACE> <Nop>
g:mapleader = " "

# Quick Buffer Navigation
nnoremap <silent> <C-l> :bnext<CR>
nnoremap <silent> <C-h> :bprev<CR>

# Search & File Control (Using mod: Cmd on Mac, Alt on Win)
execute $"nnoremap <silent> <{mod}-w> :BD<CR>"
execute $"nnoremap <silent> <{mod}-p> :call fzf#vim#gitfiles('', {{'options': '--no-preview --layout=reverse --info=inline'}})<CR>"
execute $"nnoremap <silent> <{mod}-f> :call fzf#vim#ag('', {{'options': '--layout=reverse --info=inline'}})<CR>"

# Tab Switching (1-9 for tabs, 0 for the 10th)
for i in range(1, 9)
  execute $"nmap <{mod}-{i}> <Plug>BufTabLine.Go({i})"
endfor
execute $"nmap <{mod}-0> <Plug>BufTabLine.Go(10)"


# ==========================================
# 6. Navigator Configuration (Leader Menu)
# ==========================================
# This menu appears when <Leader> (Space) is pressed.
g:navigator_config = {
  't': [':Fern . -drawer -toggle', 'Toggle File Tree'],
  '/': ['<Plug>CommentaryLine', 'Toggle Comment'],
  'g': {
    'name': '+Git',
    's': [':Git', 'Status Panel'],
    'd': [':Gdiff', 'Diff Split'],
    'w': [':Gwrite', 'Save & Stage (add)'],
    'b': [':Git blame', 'Line Blame'],
  },
  'a': {
    'name': '+AI (Copilot)',
    'c': [':CopilotChatOpen', 'Open Chat'],
    'f': [':CopilotChatFocus', 'Focus Chat'],
    'r': [':CopilotChatReset', 'Reset Conversation'],
  },
  'l': {
    'name': '+LSP',
    'a': [':LspCodeAction', 'Quick Fix / Actions'],
    'f': [':LspFormat', 'Format Document'],
    'o': [':LspDocumentSymbol', 'Symbol Outline'],
    'r': [':LspRename', 'Rename Symbol'],
  },
  'b': {
    'name': '+Buffers',
    'n': [':bnext', 'Next Buffer'],
    'p': [':bprev', 'Previous Buffer'],
    'd': [':BD', 'Kill Current Buffer'],
  }
}

# Bind Leader key to trigger the discovery menu
nnoremap <silent> <leader> :<C-u>Navigator g:navigator_config<CR>
vnoremap <silent> <leader> :<C-u>NavigatorVisual g:navigator_config<CR>


# ==========================================
# 7. Language-Specific Settings
# ==========================================
# F# Setup
autocmd FileType fsharp setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2 commentstring=//\ %s

# Enhanced Go Highlighting
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


# ==========================================
# 8. Plugin Specific Settings
# ==========================================
# BufTabLine: Show buffer numbers for quick jumping
g:buftabline_numbers = 2
g:buftabline_show = 1
g:buftabline_indicators = true

# Fern: Sidebar appearance and behavior
augroup FernCustom
  autocmd!
  autocmd FileType fern setlocal signcolumn=no foldcolumn=0 nu rnu
  autocmd BufWinEnter * if &filetype == 'fern' | wincmd = | vertical resize 30 | endif
augroup END
g:fern#renderer#default#leaf_symbol      = '│  '
g:fern#renderer#default#collapsed_symbol = '├─ '
g:fern#renderer#default#expanded_symbol  = '└─ '
g:fern#default_hidden = 1


# ==========================================
# 9. LSP (Native Vim9 Client)
# ==========================================
var lspOpts = {
  showDiagWithSign: true,
  semanticHighlight: true,
  showInlayHints: false,
  autoHighlight: true,
  autoHighlightDiags: true,
}
autocmd User LspSetup call LspOptionsSet(lspOpts)

# --- Dynamic Server Registration ---
var lspServers: list<dict<any>> = []

# Go (gopls)
if executable('gopls')
  add(lspServers, { name: 'golang', filetype: ['go', 'gomod'], path: 'gopls', args: ['serve'], syncInit: v:true })
endif

# F# (fsautocomplete)
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
    args: ['--adaptive-lsp-server-enabled'],
    initializationOptions: { AutomaticWorkspaceInit: true, TooltipShowDocumentationLink: false }
  })
endif

if len(lspServers) > 0
  autocmd User LspSetup call LspAddServer(lspServers)
endif

# --- LSP Buffer Local Mappings ---
def SetLspMappings()
  nnoremap <buffer> <silent> <C-]> <Cmd>LspGotoDefinition<CR>
  nnoremap <buffer> <silent> gy    <Cmd>LspGotoTypeDef<CR>
  nnoremap <buffer> <silent> gi    <Cmd>LspGotoImpl<CR>
  nnoremap <buffer> <silent> <C-g> <Cmd>LspShowReferences<CR>
  execute $"nnoremap <buffer> <silent> <{mod}-k> <Cmd>LspHover<CR>"
  execute $"nnoremap <buffer> <silent> <{mod}-r> <Cmd>LspRename<CR>"
  nnoremap <buffer> <silent> [d <Cmd>LspDiag prevWrap<CR>
  nnoremap <buffer> <silent> ]d <Cmd>LspDiag nextWrap<CR>
  nnoremap <buffer> <silent> gl <Cmd>LspDiag current<CR>
enddef

augroup LspKeybindings
  autocmd!
  autocmd User LspAttached SetLspMappings()
  # Fallback for buffers opened before LSP attached
  autocmd FileType * if &buftype == '' | SetLspMappings() | endif
augroup END


# ==========================================
# 10. File Watcher & Commentary
# ==========================================
# Automatically reload files when changed outside of Vim
set autoread
def SafeCheckTime()
  if mode() == 'c' || &buftype != '' || expand('%') == '' | return | endif
  checktime
enddef
augroup AutoReload
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * SafeCheckTime()
  autocmd FileChangedShellPost * echohl WarningMsg | echo "File updated externally" | echohl None
augroup END

# Commentary Fast Map (Cmd+/ on Mac, Alt+/ on Win)
execute $"nmap <silent> <{mod}-/> <Plug>CommentaryLine"
execute $"xmap <silent> <{mod}-/> <Plug>Commentary"


# ==========================================
# 11. AI & Debugger Extras
# ==========================================
# Send selected text to AI Chat
vmap <leader>ca <Plug>CopilotChatAddSelection
# Prevent Copilot from completing inside its own chat window
g:copilot_filetypes = { 'copilot-chat': v:false }
# Use 'HUMAN' keybindings for Vimspector (F5, F9, F10, etc.)
g:vimspector_enable_mappings = 'HUMAN'
