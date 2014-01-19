if exists("g:simple_tap") || &cp
  finish
endif
let g:simple_tap = 1

augroup simpleTap
  au!
  au BufWritePost /tmp/tap_result.mytap call s:SetupTap()
  au WinEnter * call s:SetLastPosition()
augroup END

command CloseTapWindow :call CloseTapWindow()
command RunTapTests :call s:RunTapTests(<args>)

fun! CloseTapWindow()
  let tapwin = FindTapWindow()
  if tapwin > 0
    silent execute tapwin . 'wincmd w'
    silent execute 'normal q'
  endif
endfun

fun! FindTapWindow()
  for w in range(1, winnr('$'))
    if getwinvar(w,'&ft') ==# 'mytap'
      return w
    endif
  endfor
endfun

fun! JumpToNextTapError()
  if &ft !=# 'mytap'
    silent execute 'wincmd p'
    if (search('\(\/.*\):\(\d\+\):\(\d\+\)', 'n') <= 0)
      silent execute 'wincmd p'
      return 0
    endif
  endif
  silent execute 'normal p'
  call feedkeys("\<cr>")
endfun

fun! JumpToPrevTapError()
  if &ft !=# 'mytap'
    silent execute 'wincmd p'
    if (search('\(\/.*\):\(\d\+\):\(\d\+\)', 'n') <= 0)
      silent execute 'wincmd p'
      return 0
    endif
  endif
  silent execute 'normal n'
  call feedkeys("\<cr>")
endfun

fun! s:RunTapTests(...)
  if !exists('t:is_tap_error')
    silent execute 'normal! mP'
  endif
  let t:tap_winnr_ran_from=winnr()
  let t:tap_window_is_open=1
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
  if a:0 > 0
    silent! execute 'read !REPORTER=tap ' . a:1
  elseif exists("t:test_command")
    silent! execute 'read !REPORTER=tap ' . t:test_command
  else
    silent! execute 'read !REPORTER=tap make test'
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
  if (search('\(\/.*\):\(\d\+\):\(\d\+\)', 'n') <= 0)
    silent execute t:tap_winnr_ran_from.'wincmd w'
  else
    call search('\(\/.*\):\(\d\+\):\(\d\+\)')
  endif
endfun

fun! s:SetLastPosition()
  if &ft ==? 'mytap' && !exists('t:is_tap_error')
    silent execute 'wincmd p'
    silent execute 'normal! mP'
    silent execute 'wincmd p'
  endif
endfun

fun! s:SetupTap()
  let g:tap_win = bufnr('%')
  silent! call AdjustWindowHeight(5, 10)
  nnoremap <buffer><silent>n :call <SID>TapNextError()<cr>
  nnoremap <buffer><silent>p :call <SID>TapPrevError()<cr>
  nnoremap <buffer><silent>q :q!<cr>:wincmd p<cr>:unlet t:tap_window_is_open<cr>
  nnoremap <buffer><silent><cr> :call <SID>TapGotoError()<cr>
  nnoremap <buffer><silent><c-cr> :call <SID>TapGotoError()<cr>
endfun

fun! s:TapCloseTest()
  unlet t:is_tap_error
  nnoremap <buffer><silent><c-o> <c-o>
  silent execute "normal! `P"
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
    silent execute t:tap_winnr_ran_from.'wincmd w'
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
    nnoremap <buffer><silent><c-o> :call <SID>TapCloseTest()<cr>
    let t:is_tap_error = 1
  endif
endfun

fun! s:TapNextError()
  if (search('\(\/.*\):\(\d\+\):\(\d\+\)', 'n') > 0)
    call search('\(\/.*\):\(\d\+\):\(\d\+\)')
  else
    call search('^not ok')
  endif
  silent execute 'normal! zt'
endfun

fun! s:TapPrevError()
  if (search('\(\/.*\):\(\d\+\):\(\d\+\)', 'n') > 0)
    call search('\(\/.*\):\(\d\+\):\(\d\+\)', 'b')
  else
    call search('^not ok', 'b')
  endif
  silent execute 'normal! zt'
endfun
