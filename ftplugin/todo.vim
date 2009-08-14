" todo.txt plugin

" Default variables
let todo_states = [["TODO", "DONE"]]
let todo_state_colors = { "TODO" : "Yellow", "DONE": "Green" }
let todo_checkbox_states=[[" ", "X"], ["+", "-", "."], ["Y", "N", "?"]]
let todo_log = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Folding support
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
setlocal foldmethod=indent
setlocal foldtext=getline(v:foldstart).\"\ ...\"
setlocal fillchars+=fold:\ 
" Change the color of Folds - most color schemes have a horrible background
" making the folds stand out too much.
" TODO - make this overridable
hi! link Folded Delimiter

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Todo entry macros
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Datestamp
iab ds <C-R>=strftime("%Y-%m-%d")<CR>
" New todo entry - both command and abbreviation
map \cn o[ ] ds 
" TODO - make the abbreviation run 'ds' instead
iab cn [ ] <C-R>=strftime("%Y-%m-%d")<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Checkboxes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Note: These macros make use of the 'z' mark
" TODO - ask on irc if there is an accepted way to do this in a macro

" Make a checkbox at the beginning of the line, removes any preceding bullet
" point dash
function! InsertCheckBox()
    let oldpos=getpos(".")
    s/^\(\s*\)\?\(- \)\?/\1[ ] /
    call setpos(".", oldpos)
endfunction

map <leader>cb :call InsertCheckBox()<CR>

" Toggle a checkbox
function! CheckBoxToggle()
    let line=getline(".")
    let idx=match(line, "\\[[^]]\\]")
    if idx != -1
        for group in g:todo_checkbox_states
            let stateidx = 0
            while stateidx < len(group)
                if group[stateidx] == line[idx+1]
                    let stateidx=stateidx + 1
                    if stateidx >= len(group)
                        let stateidx = 0
                    endif
                    let val=group[stateidx]
                    let parts=[line[0:idx],line[idx+2:]]
                    call setline(".", join(parts, val))
                    " Logging code - not used in checkboxes
                    "if g:todo_checkbox_log == 1
                    "    let log=g:todo_checkbox_states[val]["log"]
                    "    call append(line("."), matchstr(getline("."), "\\s\\+")."    ".
                    "            \log.": ".strftime("%Y-%m-%d %H:%M:%S"))
                    "endif
                    return
                endif
                let stateidx=stateidx + 1
            endwhile
        endfor
    endif
endfunction

map <leader>cc :call CheckBoxToggle()<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Task status
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! NextTaskState()
    let line=getline(".")
    let idx=match(line, "\\(^\\s*\\)\\@<=[A-Z]\\+\\(\\s\\|$\\)\\@=")
    if idx != -1
        for group in g:todo_states
            let stateidx = 0
            while stateidx < len(group)
                let oldstate = group[stateidx]
                if oldstate == line[idx+0:idx+len(oldstate)-1]
                    let stateidx=stateidx + 1
                    if stateidx >= len(group)
                        let stateidx = 0
                    endif
                    let val=group[stateidx]
                    let parts=[line[0:idx-1],line[idx+len(oldstate):]]
                    call setline(".", join(parts, val))
                    " Logging code - not used in checkboxes
                    if g:todo_log == 1
                        let log=group[stateidx] " TODO allow alternate log msg
                        call append(line("."),
                                    \ matchstr(getline("."), "\\s\\+")."    ".
                                    \log.": ".strftime("%Y-%m-%d %H:%M:%S"))
                    endif
                    return
                endif
                let stateidx=stateidx + 1
            endwhile
        endfor
    endif
endfunction

map <leader>cs :call NextTaskState()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Task link
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Provides a link to a web based task manager
" Need to set the todo_taskurl and todo_browser variables in .vimrc
" E.g.
" let todo_browser="gnome-open"
" let todo_taskurl="http://www.example.com/tasks/?id=%s"
" (The %s will be replaced with the task id)
function! LoadTaskLink()
    let tid=matchstr(getline("."), "tid\\d\\+")
    if tid != ""
        let tid = matchstr(tid, "\\d\\+")
        let taskurl = substitute(g:todo_taskurl, "%s", tid, "")
        call system(g:todo_browser . " " . taskurl)
        echo "Loading Task"
    else
        echo "No Task ID found"
    endif
endfunction

map <leader>ct :call LoadTaskLink()<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" URL opening
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Uses todo_browser
function! LoadLink()
    let url=matchstr(getline("."), "https\\?://\\S\\+")
    if url != ""
        call system(g:todo_browser . " " . url)
        echo "Loading URL"
    else
        echo "No URL Found"
    endif
endfunction

map <leader>cl :call LoadLink()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Task searching
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ShowDueTasks(day, ...)
    " Based on the Todo function at
    " http://ifacethoughts.net/2008/05/11/task-management-using-vim/
    " Add the first day
    let _date = strftime("%Y-%m-%d", localtime() + a:day * 86400)
    try
        exec "lvimgrep /{" . _date . "}/j %"
    catch /^Vim(\a\+):E480:/
    endtry
    " Add any more in the day range
    if a:0 > 0
        for offset in range(a:day+1, a:1)
            let _date = strftime("%Y-%m-%d", localtime() + offset * 86400)
            try
                exec "lvimgrepadd /{" . _date . "}/j %"
            catch /^Vim(\a\+):E480:/
            endtry
        endfor
    endif
    exec "lw"
endfunction

" Due today
command! Today :call ShowDueTasks(0)
map <leader>cd :Today<CR>
" Due tomorrow
command! Tomorrow :call ShowDueTasks(1)
map <leader>cf :Tomorrow<CR>
" Due in the next week
command! Week :call ShowDueTasks(0,7)
map <leader>cw :Week<CR>
" Due in the past week
command! Overdue :call ShowDueTasks(-7,-1)
map <leader>cx :Overdue<CR>
