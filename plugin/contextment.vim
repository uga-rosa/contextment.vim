if exists('g:loaded_contextment')
  finish
endif
let g:loaded_contextment = 1

command! -range -bar -bang Contextment call contextment#do(<line1>, <line2>, <bang>0)
nnoremap <expr>   <Plug>(contextment)      contextment#do()
xnoremap <expr>   <Plug>(contextment)      contextment#do()
nnoremap <expr>   <Plug>(contextment-line) contextment#do() . '_'
onoremap <silent> <Plug>(contextment)      <Cmd>call contextment#textobject(get(v:, 'operator', '') ==# 'c')<CR>
