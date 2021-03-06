" git.vim - long zhu (iprintf.com)
"
" git command for VIM.
"
"Usage:
" git init              ,gi
" git add               ,ga
" git add  *            ,gaa
" git commit            ,gcv
" git commit -m         ,gc
" git commit -a         ,gca
" git commit --amend    ,gcr
" git branch            ,gb
"
" 自动commit
"   打开文件按日期创建分支
"       判断是否为git项目
"       判断分支是否创建 没有创建则创建
"
"   保存文件时commit :w :wq
"       文件已经保存后再提交
"       对于上次提交有改动后保存才提交
"       commit标题为文件名 第几次保存编号
"       commit内容提取光标所在行代码我
"
"防止重复包含此插件
if exists('g:loaded_kyo_git')
    finish
endif
let g:loaded_kyo_git = 0

"判断Git命令是否存在
if executable('git')
    let s:Kyo_Git_Cmd = 'git'
elseif executable('git.exe')
    let s:Kyo_Git_Cmd = 'git.exe'
else
    echomsg 'KyoGit: Exuberant Git (http://git-scm.com) ' .
                \ 'not found in PATH. Plugin is not loaded.'
    finish
endif

"控制是否默认开启自动提交功能
if !exists('g:Kyo_Git_AutoStart')
    let g:Kyo_Git_AutoStart = 0
endif

"保存自动提交自动创建分支状态
"0 代表未开启功能
"1 代表开启功能
if !exists('g:Kyo_Git_Status')
    let g:Kyo_Git_Status = 0
endif

"控制在什么样的事件触发自动提交
"w  代表在:w 保存时触发
"q  代表在:wq 保存退出时触发
if !exists('g:Kyo_Git_Auto_Event')
    let g:Kyo_Git_Auto_Event = 'w'
endif

"======================================================================

"检查当前工作路径是否为Git Project
function! KyoCheckGitPro()
    let out = system('git status')
    if stridx(out, 'Not a git repository') == -1
        return 1
    endif

    return 0
endfunction

"Git命令运行函数
function! KyoGitRunCommand(cmd, parameter)
    " echo 'echo -n $('.s:Kyo_Git_Cmd.' '.a:cmd.' '.a:parameter.')'
    return system('echo -n $('.s:Kyo_Git_Cmd.' '.a:cmd.' '.a:parameter.')')
endfunction

"Git命令运行函数
function! KyoGitRunCommandNE(cmd, parameter)
    " echo 'echo -n $('.s:Kyo_Git_Cmd.' '.a:cmd.' '.a:parameter.')'
    return system(s:Kyo_Git_Cmd.' '.a:cmd.' '.a:parameter)
endfunction

"======================================================================

"Git Init当前编辑文件目录
function! KyoGitInit()
    return KyoGitRunCommandNE('init', getcwd())
endfunction

"Git Add操作函数
"opt = all      git add *
"opt = ''       git add editfile
function! KyoGitAdd(...)
    if a:0
        let opt = a:1
    else
        let opt = ''
    endif
    if opt == 'all'
        return KyoGitRunCommand('add', '*')
    endif
    let absolutePath = getcwd().'/'.GetFileName()
    return KyoGitRunCommand('add', absolutePath)
endfunction

"Git Commit操作函数
"opt = all      git commit -a
"opt = amend    git commit --amend
"opt = msg      git commit -m
"opt = ''       git commit
function! KyoGitCommit(...)
"{
    let parameter = ''
    if a:0
        let opt = a:1
    else
        let opt = ''
    endif

    if opt == 'all'
        let parameter = '-a'
    elseif opt == 'amend'
        let parameter = '--amend'
    elseif opt == 'msg'
        call KyoGitAdd('all')
        let msg = input('commit message: ')
        if msg != ''
            let out = KyoGitRunCommand('commit', '-m $'''.msg.'''')
            if stridx(out, 'no changes added to commit') == -1
                echo '提交成功!'
            else
                echo '提交失败: 项目没有改变!'
            endif
        endif
        return 0
    else
        call KyoGitAdd('all')
    endif
    let cmd = s:Kyo_Git_Cmd.' commit '.parameter
    " echo cmd
    execute 'silent !'.cmd
    :redraw!
"}
endfunction

"Git Branch操作函数
"opt = co       git checkout branch
"opt = m        git branch oldbranch newbranch
"opt = ''       git checkout todaybranch
function! KyoGitBranch(...)
"{
    if a:0
        let opt = a:1
    else
        let opt = ''
    endif
    if opt == 'm'
        let cmd = s:Kyo_Git_Cmd.' branch | grep "*" | sed -en "s/\*//p"'
        let oldname = system(cmd)
        if oldname == ''
            echo '重命名分支失败，没有获取到当前分支名'
            return 0
        endif
        let newname = input('New Branch Name:')
        if newname == ''
            echo '重命名分支失败, 没有输入新分支名!'
            return 0
        endif

        return KyoGitRunCommand('branch', '-m '.oldname.' '.newname)
    elseif opt == 'co'
        echo KyoGitRunCommandNE('branch', '-l')
        let branch = input('checkout branch name:')
        if branch == ''
            echo '切换分支失败，没有输入分支名!'
            return 0
        endif
        return KyoGitRunCommand('checkout', branch)
    else
        return KyoGitRunCommand('checkout', strftime("%Y%m%d"))
    endif
"}
endfunction


"======================================================================

"保存时自动提交
function! KyoGitAutoCommit()
"{
    let filename = GetFileName()
    let fileGitPath = KyoGitRunCommand('rev-parse', '--show-prefix')
                    \.filename
    let absolutePath = getcwd().'/'.filename
    " echo fileGitPath
    " echo absolutePath
    let diff = KyoGitRunCommand('diff',
                    \'--ignore-blank-lines "'.absolutePath.'"')
    " echo diff
    if diff != ''
        let out = KyoGitRunCommand('add', absolutePath)
        let cmd = 'echo -n $('
        let cmd = cmd.s:Kyo_Git_Cmd.' log --grep "'.fileGitPath.'" --oneline '
        let cmd = cmd.' --pretty=format:"%cd" --date=iso '
        let cmd = cmd.' | grep "'.strftime("%Y-%m-%d").'" | wc -l)'
        " echo cmd
        let fileAutoCount = system(cmd)
        let fileAutoCount += 1
        let commit = '-m $''自动提交#'.fileAutoCount.' '.filename.'\n\n'
        let commit = commit.'filePath: '.absolutePath.'\n'
        let commit = commit.'GitPath: '.fileGitPath.'\n'
        let commit = commit.'LastEdit: \n'
        let l = line('.')
        let f = l - 1
        let e = l + 1
        let commit = commit.'\t'.f.': '.getline(f).'\n'
        let commit = commit.'\t'.l.': '.getline(l).'\n'
        let commit = commit.'\t'.e.': '.getline(e).'\n'
        let commit = commit.''''
        let out = KyoGitRunCommand('commit', commit)
        " echo out
        " echo '自动提交#'.fileAutoCount.'成功!'
    endif
"}
endfunction

"打开文件自己检查分支是否存在，不存在则创建
function! KyoGitAutoBranch()
"{
    let name = strftime('%Y%m%d')
    let out = system(s:Kyo_Git_Cmd.' branch | grep '.name)
    if out == ''
        let out = KyoGitRunCommand('checkout ', '-b '.name)
        " echo out
    else
        let cmd = s:Kyo_Git_Cmd.' branch | grep "*" | sed -en "s/\*//p"'
        let oldname = system(cmd)
        if oldname == name
            return
        endif

        return KyoGitRunCommand('checkout', name)
    endif
"}
endfunction

"自动提交功能开启
function! KyoGitAutoOn()
    if !KyoCheckGitPro()
        return -1
    endif
    if g:Kyo_Git_Auto_Event == 'w'
        au BufWritePost * call KyoGitAutoCommit()
    elseif g:Kyo_Git_Auto_Event == 'q'
        au QuitPre * call KyoGitAutoCommit()
    endif
    call KyoGitAutoBranch()
    let g:Kyo_Git_Status = 1
endfunction

"自动提交功能关闭
function! KyoGitAutoOff()
    if !KyoCheckGitPro()
        return -1
    endif
    if g:Kyo_Git_Auto_Event == 'w'
        au! BufWritePost * call KyoGitAutoCommit()
    elseif g:Kyo_Git_Auto_Event == 'q'
        au! QuitPre * call KyoGitAutoCommit()
    endif
    let g:Kyo_Git_Status = 0
endfunction

"自动提交功能开关轮换
function! KyoGitToggle()
"{
    if g:Kyo_Git_Status == 0
        call KyoGitAutoOn()
    else
        call KyoGitAutoOff()
    endif

    echo '自动提交功能:'g:Kyo_Git_Status
"}
endfunction

"默认打开文件是否开启自动提交功能
if g:Kyo_Git_AutoStart
    call KyoGitAutoOn()
endif

command! KyoGitAutoOn call KyoGitAutoOn()
command! KyoGitAutoOff call KyoGitAutoOff()
command! KyoGitToggle call KyoGitToggle()
command! KyoGitInit call KyoGitInit()
command! -nargs=? KyoGitAdd call KyoGitAdd(<f-args>)
command! -nargs=? KyoGitCommit call KyoGitCommit(<f-args>)
command! -nargs=? KyoGitBranch call KyoGitBranch(<f-args>)

nnoremap ,gau   :KyoGitToggle<CR>
nnoremap ,gi    :KyoGitInit<CR>
nnoremap ,ga    :KyoGitAdd<CR>
nnoremap ,gaa   :KyoGitAdd all<CR>
nnoremap ,gc    :KyoGitCommit<CR>
nnoremap ,gcv   :KyoGitCommit msg<CR>
nnoremap ,gca   :KyoGitCommit all<CR>
nnoremap ,gcr   :KyoGitCommit amend<CR>
nnoremap ,gb    :KyoGitBranch<CR>
nnoremap ,gbr   :KyoGitBranch m<CR>
nnoremap ,gbc   :KyoGitBranch co<CR>
