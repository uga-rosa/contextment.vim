function! s:has_context_filetype() abort
  let has = 0
  silent! let has = context_filetype#version()
  return has
endfunction

function! s:load_ftplugin(ft) abort
  let ft = a:ft
  unlet b:did_ftplugin
  exe printf('runtime! ftplugin/%s.vim ftplugin/%s_*.vim ftplugin/%s/*.vim', ft, ft, ft)
  exe printf('runtime! ftplugin/%s.lua ftplugin/%s_*.lua ftplugin/%s/*.lua', ft, ft, ft)
  let b:did_ftplugin = 1
endfunction

function! s:surroundings(line1, line2) abort
  let commentstring = &commentstring
  if s:has_context_filetype()
    let context = context_filetype#get()
    if context.filetype !=# &ft &&
          \ context.range[0][0] <= a:line1 && a:line2 <= context.range[1][0]
      call s:load_ftplugin(context.filetype)
      let commentstring = &commentstring
      let &ft = &ft
    endif
  endif
  return map(split(get(b:, 'contextment_format', commentstring), '%s', 1), 'trim(v:val)')
endfunction

function! contextment#do(...) abort
  if a:0 == 0
    let &operatorfunc = 'contextment#do'
    return 'g@'
  elseif a:0 > 1
    let [line1, line2] = [a:1, a:2]
  else
    let [line1, line2] = [line("'["), line("']")]
  endif
  " force uncomment
  let uncomment = a:0 > 2 && a:3

  let [l, r] = s:surroundings(line1, line2)
  let lines = getline(line1, line2)

  if !uncomment
    " If there is even one line that is neither a blank line nor a comment line, not uncomment.
    let uncomment = 1
    for line in lines
      if line !~# '^\s*$' && (line !~# '^\s*' . l || line !~# r . '$')
        let uncomment = 0
        break
      endif
    endfor
  endif

  let first_indent = matchstr(lines[0], '^\s*')

  let lines_new = []
  for line in lines
    if uncomment
      let indent = matchstr(line, '^\s*')
      let line = line[strlen(indent):]
      let line = indent . substitute(substitute(line, '\V\^' . l . '\s\?', '', ''), '\V\s\?' . r . '\$', '', '')
    elseif line !~# '^\s*$'
      " Ignore blank line
      let indent = line =~# '^' . first_indent ? first_indent : matchstr(line, '^\s*')
      let line = line[strlen(indent):]
      let line = indent . l . ' ' . line . ' ' . r
    endif
    call add(lines_new, line)
  endfor
  call setline(line1, lines_new)

  return ''
endfunction
