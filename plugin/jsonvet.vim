if !has('vim9script') || v:version < 900
  finish
endif

vim9script

# jsonvet.vim - check JSON files with jsonvet
# https://github.com/simonvanlierde/jsonvet     Needs Vim 9.0+.  See README.md
#
# Only this small file loads at startup; the real work lives in
# autoload/jsonvet.vim and is loaded the first time you run a check.

if exists('g:loaded_jsonvet')
  finish
endif
g:loaded_jsonvet = 1

def Highlights()
  highlight default JsonvetError   ctermfg=9  guifg=#ff0000
  highlight default JsonvetSuccess ctermfg=46 guifg=#00ff00
enddef

def Attach()
  # buffer-local, unless you already mapped <Plug>(jsonvet-check) yourself
  if !hasmapto('<Plug>(jsonvet-check)', 'n')
    nmap <buffer> <leader>n <Plug>(jsonvet-check)
  endif
enddef

nnoremap <Plug>(jsonvet-check) <Cmd>call jsonvet#Check()<CR>
command! JsonCheck call jsonvet#Check()

Highlights()

# Attach by filetype AND by file extension, so it works however your Vim
# detects (or mis-detects) these files.
augroup jsonvet
  autocmd!
  autocmd ColorScheme * Highlights()
  autocmd FileType json,jsonc,json5,jsonl Attach()
  autocmd BufNewFile,BufRead *.json,*.jsonc,*.json5,*.jsonl,*.ndjson,*.geojson,*.jsonld,*.hujson,*.jwcc,*.code-workspace,*.code-snippets,*.webmanifest,.babelrc Attach()
augroup END
