if exists("g:simple_tap") || &cp
  finish
endif
let g:simple_tap = 1

augroup simpleTap
  au!
  au BufWritePost /tmp/tap_result.mytap call s:SetupTap()
augroup END

command RunTapTests :call s:RunTapTests()

fun! s:RunTapTests()
  let tapresult ="/tmp/tap_result.mytap"
  let old_win = winnr()
  silent! up
  if exists('g:tap_win')
    silent! execute g:tap_win . 'bd!'
  endif
  call delete(tapresult)
  silent! execute 'botright new'
  silent! execute 'write! ' . tapresult
  redraw
  execute 'normal! \<C-W>b'
  setl modifiable
  execute '1,$d'
  if exists("t:test_command")
    silent! execute 'read !' . t:test_command
  else
    silent! execute 'read !make test'
  endif
  highlight TAP_PASS ctermfg=Green ctermbg=Black guifg=Green guibg=Black
  highlight TAP_FAIL ctermfg=Red ctermbg=Black guifg=Red guibg=Black
  highlight TAP_SKIP ctermfg=Yellow ctermbg=Black guifg=Yellow guibg=Black
  match  TAP_PASS /^\(# pass\|ok\).*$/
  2match TAP_FAIL /^\(# fail\|not ok\).*$/
  3match TAP_SKIP /^ok .*# SKIP -$/
  silent! 1,$g/^$/d
  silent! 1,$g/^ok/d
  silent! 1,$g/node_modules/d
  silent! 1,$g/node\.js/d
  silent! 1,$g/module\.js/d
  silent! 1,$g/make: \*\*\*/d
  silent! 1,$g/is now called `/d
  execute '0'
  if (search('not ok', 'n') > 0)
    silent! execute '/not ok/'
  else
    silent! execute '/# tests/'
  endif
  set filetype=mytap
  setl nomodifiable
  setl nobuflisted
  write!
  silent execute 'normal! zt'
  redraw!
endfun

fun! s:SetupTap()
  let g:tap_win = bufnr('%')
  silent! call AdjustWindowHeight(5, 10)
  nnoremap <buffer><silent>n :call s:TapNextError()<cr>
  nnoremap <buffer><silent>p :call s:TapPrevError()<cr>
  nnoremap <buffer><silent>q :q!<cr>:wincmd p<cr>
  nnoremap <buffer><silent><cr> :call s:TapGotoError()<cr>
endfun

fun! s:TapCloseTest()
  tabc
endfun

fun! s:TapGotoError()
  let line = getline('.')
  let matched_line = matchlist(line, '\(\/.*\):\(\d\+\):\(\d\+\)')
  let f = get(matched_line, 1)
  let l = get(matched_line, 2)
  let c = get(matched_line, 3)
  if filereadable(f)
    let not_listed = 0
    if !buflisted(f)
      let not_listed = 1
    endif
    tabnew
    exec "edit " . f
    exec ":" . l
    silent execute 'normal! ' . c . '|'
    if foldlevel(l) > 0
      silent execute 'normal! zv'
    endif
    silent execute 'normal! zz'
    if not_listed
      setl nobuflisted
    endif
    nnoremap <buffer><silent><c-o> :call s:TapCloseTest()<cr>
  endif
endfun

fun! s:TapNextError()
  call search('^not ok')
  silent execute 'normal! zt'
endfun

fun! s:TapPrevError()
  call search('^not ok', 'b')
  silent execute 'normal! zt'
endfun
