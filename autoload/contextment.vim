function! s:load_ftplugin(ft) abort
  unlet b:did_ftplugin
  execute 'runtime!' printf(
        \ 'ftplugin/%s.vim ftplugin/%s_*.vim ftplugin/%s/*.vim' .
        \ 'ftplugin/%s.lua ftplugin/%s_*.lua ftplugin/%s/*.lua',
        \ a:ft, a:ft, a:ft, a:ft, a:ft, a:ft)
  let b:did_ftplugin = 1
endfunction

function! s:surroundings(line1, line2) abort
  let commentstring = &commentstring
  let context = context_filetype#get()
  if context.filetype !=# &ft &&
        \ context.range[0][0] <= a:line1 && a:line2 <= context.range[1][0]
    call s:load_ftplugin(context.filetype)
    let commentstring = &commentstring
    call s:load_ftplugin(&ft)
  endif
  return map(split(commentstring, '%s', 1), 'trim(v:val)')
endfunction

function! s:is_blank(line) abort
  return a:line =~# '^\s*$'
endfunction

function! s:is_comment(line, l, r) abort
  return a:line =~# '\V\^\s\*' . a:l . '\.\*' . a:r . '\$'
endfunction

function! contextment#do(...) abort
  if a:0 == 0
    let &operatorfunc = 'contextment#do'
    return 'g@'
  elseif a:0 > 1
    let [lnum1, lnum2] = [a:1, a:2]
  else
    let [lnum1, lnum2] = [line("'["), line("']")]
  endif
  " force uncomment
  let uncomment = a:0 > 2 && a:3

  let [l, r] = s:surroundings(lnum1, lnum2)
  let lines = getline(lnum1, lnum2)

  if !uncomment
    " If there is even one line that is neither a blank line nor a comment line, not uncomment.
    let uncomment = 1
    for line in lines
      if !s:is_blank(line) && !s:is_comment(line, l, r)
        let uncomment = 0
        break
      endif
    endfor
  endif

  let first_indent = matchstr(lines[0], '^\s*')
  let lines_new = []
  for line in lines
    if s:is_blank(line)
      " Ignore blank line
    elseif uncomment
      let indent = matchstr(line, '^\s*')
      let line = line[strlen(indent):]
      let line = indent . substitute(substitute(
            \ line, '\V\^' . l . '\s\?', '', ''), '\V\s\?' . r . '\$', '', '')
    else
      let indent = matchstr(line, '^\%(' . first_indent . '\|\s*\)')
      let line = line[strlen(indent):]
      let line = indent . l . ' ' . line . (r ==# '' ? '' : ' ' . r)
    endif
    call add(lines_new, line)
  endfor
  call setline(lnum1, lines_new)
  return ''
endfunction

function! s:find_range(l, r, lnum, inner) abort
  let [l, r] = [a:l, a:r]
  " The actual examination begins with the next line (+0/-1).
  " The reason why it is not +2/-2 is that it is unnecessary to check the same row (lnum) twice.
  let lnums = [a:lnum+1, a:lnum-2]
  " Find the start row upward and the end row downward.
  for [index, dir, bound, line] in [[0, -1, 1, ''], [1, 1, line('$'), '']]
    while lnums[index] != bound && s:is_blank(line) || s:is_comment(line, l, r)
      let lnums[index] += dir
      let line = getline(lnums[index] + dir)
    endwhile
    while a:inner && s:is_blank(getline(lnums[index]))
      let lnums[index] -= dir
    endwhile
  endfor
  return lnums
endfunction

function! contextment#textobject(inner) abort
  let lnum = line('.')
  let [l, r] = s:surroundings(lnum, lnum)
  let [start, end] = s:find_range(l, r, lnum, a:inner)
  let context = context_filetype#get()
  if context.filetype !=# &ft
    let start = max([start, context.range[0][0]])
    let end = min([end, context.range[1][0]])
    if start > end
      let [l, r] = map(split(&commentstring, '%s', 1), 'trim(v:val)')
      let [start, end] = s:find_range(l, r, lnum, a:inner)
    endif
  endif
  if start <= end
    exe 'normal!' start . 'GV' . end . 'G'
  endif
endfunction
