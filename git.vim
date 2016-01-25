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
        let cmd = cmd.s:Kyo_Git_Cmd.' log '.strftime("%Y%m%d")
        let cmd = cmd.' --grep "'.fileGitPath.'" --oneline'
        let cmd = cmd.' | wc -l)'
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
        echo '自动提交#'.fileAutoCount.'成功!'
    endif
"}
endfunction

"打开文件自己检查分支是否存在，不存在则创建
function! KyoGitAutoBranch()
    let name = strftime('%Y%m%d')
    let out = system(s:Kyo_Git_Cmd.' branch | grep '.name)
    if out == ''
        let out = KyoGitRunCommand('checkout ', '-b '.name)
        " echo out
    endif
endfunction

function! KyoGitAdd(opt)
    if a:opt == 'all'
        return KyoGitRunCommand('add', '*')
    endif
    let absolutePath = getcwd().'/'.GetFileName()
    return KyoGitRunCommand('add', absolutePath)
endfunction

function! KyoGitCommit(opt)
"{
    let parameter = ''
    if a:opt == 'all'
        let parameter = '-a'
    elseif a:opt == 'amend'
        let parameter = '--amend'
    elseif a:opt == 'msg'
        let msg = input('commit message: ')
        if msg == ''
            echo '提交失败: 没有输入提交信息!'
        else
            let out = KyoGitRunCommand('commit', '-m $'''.msg.'''')
            if stridx(out, 'no changes added to commit') == -1
                echo '提交成功!'
            else
                echo '提交失败: 项目没有改变!'
            endif
        endif
        return 0
    endif
    let cmd = s:Kyo_Git_Cmd.' commit '.parameter
    " echo cmd
    execute 'silent !'.cmd
    :redraw!
"}
endfunction

function! KyoGitBranch()
    git branch
endfunction

let g:Kyo_Git_Switch = 0

function! KyoGitToggle()
    if !KyoCheckGitPro()
        return -1
    endif

    if g:Kyo_Git_Switch == 0
        au BufReadPost * call KyoGitAutoBranch()
        au BufWritePost * call KyoGitAutoCommit()
        call KyoGitAutoBranch()
        let g:Kyo_Git_Switch = 1
    else
        au! BufReadPost * call KyoGitAutoBranch()
        au! BufWritePost * call KyoGitAutoCommit()
        let g:Kyo_Git_Switch = 0
    endif
    echo '自动提交功能:'g:Kyo_Git_Switch
endfunction

nnoremap ,gau   :call KyoGitToggle()<CR><CR>
" nnoremap ,gcv   :! git commit<CR>


