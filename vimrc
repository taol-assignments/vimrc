vim9script

# ==========================================
# 0. Bootstrapping vim-plug
# ==========================================
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

  # Auto-install plugins on first run
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

# ==========================================
# 1. Platform Detection
# ==========================================
# Use Cmd (D) on Mac and Alt (M) on Windows
var mod = has("gui_macvim") ? 'D' : 'M'

if has('win32')
  # Prevent Alt key from triggering the system menu in GVim
  set winaltkeys=no
endif

# ==========================================
# 2. Plugin Management
# ==========================================
call plug#begin(config_dir .. '/plugged')
  # --- Core ---
  Plug 'lambdalisue/vim-fern'              # Async file tree
  Plug 'lambdalisue/vim-fern-git-status'   # Git status for Fern
  Plug 'yegappan/lsp'                      # Native LSP client
  Plug 'ap/vim-buftabline'                 # Buffer tabline
  Plug 'qpkorr/vim-bufkill'                # Safe buffer close (keep layout)
  
  # --- Navigation ---
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'markonm/traces.vim'                # Live preview :s (Mac)

  # --- Languages ---
  Plug 'fatih/vim-go'                      # Go support
  Plug 'tpope/vim-commentary'              # Fast comments
  
  # --- Git ---
  Plug 'tpope/vim-fugitive'                # Git wrapper

  # --- AI & Debug ---
  Plug 'github/copilot.vim'                # GitHub Copilot
  Plug 'DanBradbury/copilot-chat.vim'      # Copilot Chat
  Plug 'puremourning/vimspector'           # Debugger
call plug#end()


# ==========================================
# 3. General Settings
# ==========================================
# Hybrid line numbers
set nu rnu
# Always show status bar
set laststatus=2

# Reduce update time to 300ms (LSP/Copilot speed)
set updatetime=300

# Disable bells
set visualbell t_vb=
set novisualbell
set belloff=all

# --- IME switching (Mac Best Practice) ---
if has("gui_macvim")
  set noimdisable
  # 1. Insert mode: enable IME
  autocmd InsertEnter * set iminsert=1
  # 2. Leave Insert mode: reset IME
  autocmd InsertLeave * set iminsert=0
  # 3. Focus gained: reset IME if not in insert/replace
  autocmd FocusGained * if mode() != 'i' && mode() != 'R' | set iminsert=0 | endif
endif


# ==========================================
# 4. UI & GUI Settings
# ==========================================
# Font fallback: Cascadia Code (Win/Modern) -> Monaco (Mac)
set guifont=Cascadia_Code:h12,Monaco:h12

if has("gui_running")
  set cursorline
  colorscheme evening

  # Hide scrollbars
  set go-=l
  set go-=L
  set go-=r
  set go-=R

  # Unbind MacVim default shortcuts
  if has("gui_macvim")
    macmenu &File.Print key=<nop>
    macmenu &Edit.Find.Find… key=<nop>
    macmenu &File.Close key=<nop>
  endif
endif


# ==========================================
# 5. Global Keybindings
# ==========================================
# Map Space to Leader
nnoremap <SPACE> <Nop>
g:mapleader = " "

# Buffer navigation
nnoremap <silent> <C-l> :bnext<CR>
nnoremap <silent> <C-h> :bprev<CR>

# Modifier-based mappings
execute $"nnoremap <silent> <{mod}-w> :BD<CR>"

# --- FZF (Dynamic Modifier) ---
execute $"nnoremap <silent> <{mod}-p> :call fzf#vim#gitfiles('', {{'options': '--no-preview --layout=reverse --info=inline'}})<CR>"
execute $"nnoremap <silent> <{mod}-f> :call fzf#vim#ag('', {{'options': '--layout=reverse --info=inline'}})<CR>"


# ==========================================
# 6. Filetype Settings
# ==========================================
# F#
autocmd FileType fsharp setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2 commentstring=//\ %s

# Go highlight enhancements
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
# 7. BufTabLine
# ==========================================
g:buftabline_numbers = 2
g:buftabline_show = 1
g:buftabline_indicators = true

# Dynamic Modifier for tab switching
for i in range(1, 9)
  execute $"nmap <{mod}-{i}> <Plug>BufTabLine.Go({i})"
endfor
execute $"nmap <{mod}-0> <Plug>BufTabLine.Go(10)"


# ==========================================
# 8. vim-fern
# ==========================================
# Mappings
nnoremap <silent> <C-t>     :Fern . -drawer -toggle<CR>
nnoremap <silent> <leader>t :Fern . -drawer<CR>

augroup FernCustom
  autocmd!
  # Visual tweaks for fern buffer
  autocmd FileType fern setlocal signcolumn=no foldcolumn=0 nu rnu
  autocmd BufWinEnter * if &filetype == 'fern' | wincmd = | vertical resize 30 | endif
augroup END

# UTF-8 Icons
g:fern#renderer#default#leaf_symbol      = '│  '
g:fern#renderer#default#collapsed_symbol = '├─ '
g:fern#renderer#default#expanded_symbol  = '└─ '
g:fern#default_hidden = 1


# ==========================================
# 9. LSP (yegappan/lsp)
# ==========================================
# 9.1 Core options
var lspOpts = {
  showDiagWithSign: true,
  semanticHighlight: true,
  showInlayHints: false,
  autoHighlight: true,
  autoHighlightDiags: true,
}
autocmd User LspSetup call LspOptionsSet(lspOpts)

# 9.2 Dynamic server registration
var lspServers: list<dict<any>> = []

# --- Go ---
if executable('gopls')
  add(lspServers, {
    name: 'golang',
    filetype: ['go', 'gomod'],
    path: 'gopls',
    args: ['serve'],
    syncInit: v:true
  })
endif

# --- F# ---
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
    initializationOptions: {
      AutomaticWorkspaceInit: true,
      TooltipShowDocumentationLink: false
    }
  })
endif

if len(lspServers) > 0
  autocmd User LspSetup call LspAddServer(lspServers)
endif

# 8.3 Mappings
def SetLspMappings()
  # Navigation
  nnoremap <buffer> <silent> <C-]> <Cmd>LspGotoDefinition<CR>
  nnoremap <buffer> <silent> gy    <Cmd>LspGotoTypeDef<CR>
  nnoremap <buffer> <silent> gi    <Cmd>LspGotoImpl<CR>

  # Dynamic Modifier Mappings
  execute $"nnoremap <buffer> <silent> <{mod}-k> <Cmd>LspHover<CR>"
  execute $"nnoremap <buffer> <silent> <{mod}-r> <Cmd>LspRename<CR>"

  # References
  nnoremap <buffer> <silent> <C-g> <Cmd>LspShowReferences<CR>
  # QuickFix & Format
  nnoremap <buffer> <silent> <leader>ca <Cmd>LspCodeAction<CR>
  # nnoremap <buffer> <silent> <leader>fm <Cmd>LspFormat<CR>  # Conflict with default map, use carefully

  # Diagnostics
  nnoremap <buffer> <silent> [d <Cmd>LspDiag prevWrap<CR>
  nnoremap <buffer> <silent> ]d <Cmd>LspDiag nextWrap<CR>
  nnoremap <buffer> <silent> gl <Cmd>LspDiag current<CR>
  # Symbols
  nnoremap <buffer> <silent> <leader>o  <Cmd>LspDocumentSymbol<CR>
enddef

augroup LspKeybindings
  autocmd!
  autocmd User LspAttached SetLspMappings()
  autocmd FileType * if &buftype == '' | SetLspMappings() | endif
augroup END


# ==========================================
# 10. Auto-reload
# ==========================================
set autoread

def SafeCheckTime()
  if mode() == 'c' || &buftype != '' || expand('%') == ''
    return
  endif
  checktime
enddef

augroup AutoReload
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * SafeCheckTime()
  autocmd FileChangedShellPost * echohl WarningMsg | echo "File updated externally" | echohl None
augroup END


# ==========================================
# 11. Commentary
# ==========================================
# Dynamic Modifier to comment
execute $"nmap <silent> <{mod}-/> <Plug>CommentaryLine"
execute $"xmap <silent> <{mod}-/> <Plug>Commentary"


# ==========================================
# 12. Git (Fugitive)
# ==========================================
nnoremap <silent> <leader>gs <Cmd>Git<CR>
nnoremap <silent> <leader>gd <Cmd>Gdiff<CR>
nnoremap <silent> <leader>gw <Cmd>Gwrite<CR>
nnoremap <silent> <leader>gb <Cmd>Git blame<CR>


# ==========================================
# 13. AI (Copilot)
# ==========================================
nnoremap <leader>cc :CopilotChatOpen<CR>
nnoremap <leader>cf :CopilotChatFocus<CR>
nnoremap <leader>cr :CopilotChatReset<CR>
vmap <leader>ca <Plug>CopilotChatAddSelection

# Disable Copilot in chat window
g:copilot_filetypes = {
  'copilot-chat': v:false
}


# ==========================================
# 14. Vimspector
# ==========================================
g:vimspector_enable_mappings = 'HUMAN'
