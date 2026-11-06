vim9script

# The actual check. Only loaded the first time you run one (<Leader>n or
# :JsonCheck), so Vim's startup doesn't pay for any of it.
# See plugin/jsonvet.vim and README.md

# jsonvet prints  file:line:col: severity[rule] message
# (\%#=1 = Vim's backtracking regexp engine: 2x faster than the default one
# for this simple anchored pattern, which matters with thousands of problems)
const LINE_PATTERN = '\%#=1^.\{-}:\(\d\+\):\(\d\+\): \(error\|warning\)\[[^]]*\] \(.*\)$'

# The dialect a file is checked as. It is also the word in the messages, so a
# .jsonc file reports "jsonc check successful". These extensions settle it:
const DIALECT_OF_EXTENSION = {
  jsonc: 'jsonc', 'code-workspace': 'jsonc', 'code-snippets': 'jsonc',
  json5: 'json5', babelrc: 'json5',
  jsonl: 'jsonl', ndjson: 'jsonl',
  hujson: 'jwcc', jwcc: 'jwcc',
}
const FILETYPES = ['json', 'jsonc', 'json5', 'jsonl']
const PLAIN_JSON = ['json', 'geojson', 'jsonld', 'webmanifest']

def Dialect(): string
  var ext = matchstr(tolower(expand('%:t')), '[^.]*$')
  if has_key(DIALECT_OF_EXTENSION, ext)
    return DIALECT_OF_EXTENSION[ext]
  endif
  # .json and unknown names: trust the filetype (Vim says tsconfig.json is jsonc)
  if index(FILETYPES, &filetype) >= 0
    return &filetype
  endif
  # no filetype either: strict JSON for the JSON names, else what jsonvet does
  return index(PLAIN_JSON, ext) >= 0 ? 'json' : 'json5'
enddef

# g:jsonvet_args: a list (each item escaped for the shell) or a string (as is)
def ExtraArgs(): string
  var extra = get(g:, 'jsonvet_args', '')
  if type(extra) == v:t_list
    return join(mapnew(extra, (_, a) => shellescape('' .. a)), ' ')
  endif
  return '' .. extra
enddef

def Report(group: string, text: string)
  redraw!
  var msg = text
  # wider than the command line would trigger a hit-enter prompt
  if strdisplaywidth(msg) >= &columns
    msg = strcharpart(msg, 0, &columns - 4) .. '...'
  endif
  execute 'echohl ' .. group
  echo msg
  echohl None
enddef

export def Check()
  var dialect = Dialect()
  if !executable('jsonvet')
    Report('JsonvetError', 'jsonvet not found')
    return
  endif
  if expand('%') ==# ''
    Report('JsonvetError', dialect .. ' check: buffer has no file name')
    return
  endif
  if &modified
    silent! write
    if &modified
      Report('JsonvetError', dialect .. ' check: could not save the buffer')
      return
    endif
  endif

  # --dialect without a glob applies to the one file we pass. g:jsonvet_args comes
  # after it and the last match wins, so it can change the dialect (--dialect auto
  # hands the choice back to jsonvet.toml)
  var cmd = 'jsonvet --dialect ' .. dialect .. ' ' .. ExtraArgs() .. ' ' .. shellescape(expand('%:p')) .. ' 2>&1'
  var output = system(cmd)
  var status = v:shell_error
  # jsonvet 3.2+ colors piped lines when FORCE_COLOR is set: strip the codes
  output = substitute(output, '\%x1b\[[0-9;]*m', '', 'g')

  var bnr = bufnr('%')
  var problems: list<dict<any>> = []
  for entry in split(output, "\n")
    var m = matchlist(entry, LINE_PATTERN)
    if empty(m)
      continue
    endif
    var lnum = str2nr(m[1])
    var colnr = str2nr(m[2])
    # jsonvet counts code points (and a BOM as column 1); cursor() wants bytes
    if lnum == 1 && &bomb
      colnr = max([colnr - 1, 1])
    endif
    var text = getline(lnum)
    var bcol = byteidxcomp(text, colnr - 1)
    problems->add({
      bufnr: bnr,
      lnum: lnum,
      col: bcol < 0 ? len(text) + 1 : bcol + 1,
      type: m[3] ==# 'error' ? 'E' : 'W',
      text: m[4],
    })
  endfor

  setqflist(problems, 'r')

  if status == 0
    # Warnings don't fail jsonvet: still a pass, but don't hide them.
    var msg = dialect .. ' check successful'
    var n = len(problems)
    if n > 0
      msg ..= ' (' .. n .. ' warning' .. (n > 1 ? 's' : '') .. ', :copen)'
    endif
    Report('JsonvetSuccess', msg)
  elseif !empty(problems)
    # the first error (or the first problem, if there are only warnings)
    var first = problems[0]
    for p in problems
      if p.type ==# 'E'
        first = p
        break
      endif
    endfor
    cursor(first.lnum, first.col)
    # an error at end-of-file is reported on the line after the last one
    if first.lnum > line('$')
      normal! $
    endif
    normal! zvzz
    Report('JsonvetError', first.text)
  else
    # Failed without a position: unreadable / not UTF-8, bad option, crash...
    Report('JsonvetError', get(split(output, "\n"), 0, 'jsonvet failed (exit ' .. status .. ')'))
  endif
enddef
