" Verilog 格式化核心逻辑
" 包含缩进、对齐、注释整理等功能

" 全局配置默认值
function! verilog#formatter#InitConfig()
    if !exists('g:verilog_format_indent')
        let g:verilog_format_indent = 4
    endif
    if !exists('g:verilog_format_align_ops')
        let g:verilog_format_align_ops = 1
    endif
    if !exists('g:verilog_format_tab_spaces')
        let g:verilog_format_tab_spaces = 1
    endif
endfunction

" 将 tab 转换为空格
function! verilog#formatter#Detab(line)
    if g:verilog_format_tab_spaces
        return substitute(a:line, '\t', repeat(' ', g:verilog_format_indent), 'g')
    endif
    return a:line
endfunction

" 格式化单行缩进
function! verilog#formatter#FormatIndent(line, base_indent)
    let detabbed = verilog#formatter#Detab(a:line)
    let trimmed = substitute(detabbed, '^\s*', '', '')
    return repeat(' ', a:base_indent) . trimmed
endfunction

" 检查一行是否是注释行
function! verilog#formatter#IsCommentLine(trimmed)
    if a:trimmed =~# '^//'
        return 1
    endif
    return 0
endfunction

" 检查一行是否增加缩进
function! verilog#formatter#IsIncreaseIndent(trimmed)
    if a:trimmed =~# 'begin' && a:trimmed !~# 'end'
        return 1
    endif
    if a:trimmed =~# '^\s*\(always\|always_ff\|always_comb\|always_latch\|initial\)\>'
        return 1
    endif
    if a:trimmed =~# '^\s*\(case\|casex\|casez\)\>'
        return 1
    endif
    if a:trimmed =~# '^\s*fork\>'
        return 1
    endif
    if a:trimmed =~# '^\s*generate\>'
        return 1
    endif
    return 0
endfunction

" 检查一行是否减少缩进
function! verilog#formatter#IsDecreaseIndent(trimmed)
    if a:trimmed =~# '^end'
        return 1
    endif
    return 0
endfunction

" 对齐行尾注释
function! verilog#formatter#AlignComments(lines)
    let i = 0
    let n = len(a:lines)

    while i < n
        let line = a:lines[i]
        let detabbed = verilog#formatter#Detab(line)
        let comment_idx = match(detabbed, '//')

        if comment_idx >= 0
            let comment_group = []
            let group_start = i
            while i < n
                let curr_line = a:lines[i]
                let curr_detabbed = verilog#formatter#Detab(curr_line)
                let curr_comment_idx = match(curr_detabbed, '//')
                if curr_comment_idx >= 0
                    let code_part = strpart(curr_detabbed, 0, curr_comment_idx)
                    let comment_part = strpart(curr_detabbed, curr_comment_idx)
                    let code_only_space = (substitute(code_part, '\s', '', '') == '')
                    call add(comment_group, {'index': i, 'code': code_part, 'code_only_space': code_only_space, 'comment': comment_part})
                    let i += 1
                else
                    break
                endif
            endwhile

            let max_width = 0
            for item in comment_group
                if !item.code_only_space
                    let code_len = strlen(substitute(item.code, '\s*$', '', ''))
                    if code_len > max_width
                        let max_width = code_len
                    endif
                endif
            endfor

            for item in comment_group
                if item.code_only_space
                    let a:lines[item.index] = item.code . item.comment
                else
                    let code_part = substitute(item.code, '\s*$', '', '')
                    let spaces_needed = max_width - strlen(code_part) + 2
                    let a:lines[item.index] = code_part . repeat(' ', spaces_needed) . item.comment
                endif
            endfor

            if i == group_start
                let i += 1
            endif
        else
            let i += 1
        endif
    endwhile

    return a:lines
endfunction

" 格式化块注释
function! verilog#formatter#FormatBlockComments(lines)
    let i = 0
    let n = len(a:lines)
    let in_block_comment = 0
    let block_start = 0

    while i < n
        let line = a:lines[i]
        if !in_block_comment && line =~# '/\*' && line !~# '\*/'
            let in_block_comment = 1
            let block_start = i
        endif
        if in_block_comment && line =~# '\*/'
            let in_block_comment = 0
            for j in range(block_start, i)
                let line = a:lines[j]
                let stripped = substitute(line, '^\s*', '', '')
                if stripped =~# '^\*'
                    let a:lines[j] = ' ' . stripped
                elseif stripped =~# '^/\*'
                    let a:lines[j] = stripped
                elseif stripped =~# '^\*/'
                    let a:lines[j] = stripped
                endif
            endfor
        endif
        let i += 1
    endwhile

    return a:lines
endfunction

" 格式化操作符对齐
function! verilog#formatter#AlignOperators(lines)
    if !g:verilog_format_align_ops
        return a:lines
    endif

    let i = 0
    let n = len(a:lines)

    while i < n
        let line = a:lines[i]
        let detabbed = verilog#formatter#Detab(line)
        let trimmed = substitute(detabbed, '^\s*', '', '')

        if trimmed =~# '<=' && trimmed !~# '==\|!=\|>=\|=\~\|!\~'
            let assign_group = []
            let assign_start = i
            while i < n
                let curr_line = a:lines[i]
                let curr_detabbed = verilog#formatter#Detab(curr_line)
                let curr_trimmed = substitute(curr_detabbed, '^\s*', '', '')
                if curr_trimmed =~# '<=' && curr_trimmed !~# '==\|!=\|>=\|=\~\|!\~'
                    call add(assign_group, {'line': curr_line, 'trimmed': curr_trimmed, 'index': i})
                    let i += 1
                else
                    break
                endif
            endwhile

            if len(assign_group) > 1
                let max_var_len = 0
                for item in assign_group
                    let eq_pos = match(item.trimmed, '<=')
                    if eq_pos > 0
                        let var_part = strpart(item.trimmed, 0, eq_pos)
                        if strlen(var_part) > max_var_len
                            let max_var_len = strlen(var_part)
                        endif
                    endif
                endfor

                for item in assign_group
                    let t = item.trimmed
                    let leading_space = match(a:lines[item.index], '\S')
                    if leading_space < 0
                        let leading_space = 0
                    endif
                    let eq_pos = match(t, '<=')
                    if eq_pos > 0
                        let var_part = strpart(t, 0, eq_pos)
                        let rest = strpart(t, eq_pos)
                        let padding = repeat(' ', max_var_len - strlen(var_part))
                        let a:lines[item.index] = repeat(' ', leading_space) . var_part . padding . rest
                    endif
                endfor
            endif
        else
            let i += 1
        endif
    endwhile

    return a:lines
endfunction

" 主格式化函数
function! verilog#formatter#Format()
    call verilog#formatter#InitConfig()
    let save_cursor = getpos('.')
    let lines = getline(1, '$')

    " 第一步：转换 tab 为空格
    let i = 0
    while i < len(lines)
        let lines[i] = verilog#formatter#Detab(lines[i])
        let i += 1
    endwhile

    " 第二步：计算缩进级别
    let indent_stack = []
    let line_indents = []
    let indent_level = 0
    let prev_indent = 0
    let in_module = 0

    for i in range(len(lines))
        let line = lines[i]
        let trimmed = substitute(line, '^\s*', '', '')

        if trimmed == ''
            call add(line_indents, -1)
            continue
        endif

        if trimmed =~# '^\s*\(module\|interface\|package\)\>'
            let in_module = 1
        endif
        if trimmed =~# '^end\(module\|interface\|package\)'
            let in_module = 0
        endif

        " 注释行处理
        if verilog#formatter#IsCommentLine(trimmed)
            if prev_indent == 0 && !in_module
                call add(line_indents, 0)
            else
                call add(line_indents, prev_indent)
            endif
            continue
        endif

        " 检查 end 关键词
        if verilog#formatter#IsDecreaseIndent(trimmed)
            if len(indent_stack) > 0
                call remove(indent_stack, -1)
            endif
            let indent_level = len(indent_stack)
        endif

        call add(line_indents, indent_level)
        let prev_indent = indent_level

        " 检查是否需要增加缩进
        if verilog#formatter#IsIncreaseIndent(trimmed)
            call add(indent_stack, indent_level)
            let indent_level = len(indent_stack)
        endif
    endfor

    " 第三步：应用缩进
    for i in range(len(lines))
        let line = lines[i]
        let trimmed = substitute(line, '^\s*', '', '')
        if trimmed == ''
            continue
        endif
        let base_indent = line_indents[i] * g:verilog_format_indent
        let lines[i] = verilog#formatter#FormatIndent(line, base_indent)
    endfor

    " 第四步：对齐声明
    let lines = verilog#formatter#AlignDeclarations(lines)

    " 第五步：对齐行尾注释
    let lines = verilog#formatter#AlignComments(lines)

    " 第六步：格式化块注释
    let lines = verilog#formatter#FormatBlockComments(lines)

    " 第七步：对齐操作符
    let lines = verilog#formatter#AlignOperators(lines)

    " 删除空行
    let result = []
    let empty_count = 0
    for line in lines
        if line =~# '^\s*$'
            let empty_count += 1
            if empty_count <= 2
                call add(result, line)
            endif
        else
            let empty_count = 0
            call add(result, line)
        endif
    endfor

    while len(result) > 0 && result[-1] =~# '^\s*$'
        call remove(result, -1)
    endwhile

    if len(result) > 0 && result[-1] !~# '^\s*$'
        call add(result, '')
    endif

    silent! 1,$delete _
    for i in range(len(result))
        call setline(i + 1, result[i])
    endfor

    call setpos('.', save_cursor)
    echo "Verilog 格式化完成"
endfunction

" 对齐声明语句
function! verilog#formatter#AlignDeclarations(lines)
    let i = 0
    let n = len(a:lines)

    while i < n
        let line = a:lines[i]
        let detabbed = verilog#formatter#Detab(line)
        let trimmed = substitute(detabbed, '^\s*', '', '')

        " 检查是否是声明语句
        let is_decl = 0
        if trimmed =~# '^\(wire\|reg\|logic\|integer\|real\|time\|event\|genvar\)\>'
            let is_decl = 1
        elseif trimmed =~# '^\(input\|output\|inout\)\>'
            let is_decl = 1
        elseif trimmed =~# '^\(parameter\|localparam\)\>'
            let is_decl = 1
        endif

        if is_decl
            let decl_group = []
            let decl_start = i
            while i < n
                let curr_line = a:lines[i]
                let curr_detabbed = verilog#formatter#Detab(curr_line)
                let curr_trimmed = substitute(curr_detabbed, '^\s*', '', '')

                let curr_is_decl = 0
                if curr_trimmed =~# '^\(wire\|reg\|logic\|integer\|real\|time\|event\|genvar\)\>'
                    let curr_is_decl = 1
                elseif curr_trimmed =~# '^\(input\|output\|inout\)\>'
                    let curr_is_decl = 1
                elseif curr_trimmed =~# '^\(parameter\|localparam\)\>'
                    let curr_is_decl = 1
                endif

                if curr_is_decl
                    call add(decl_group, {'trimmed': curr_trimmed, 'index': i})
                    let i += 1
                else
                    break
                endif
            endwhile

            if len(decl_group) > 0
                " 检查是否是端口声明 (input/output/inout)
                let is_port = (decl_group[0].trimmed =~# '^\(input\|output\|inout\)')

                " 解析每个声明，计算前缀长度（input/output + wire/reg + 位宽）
                let parsed = []
                let max_prefix_len = 0

                for item in decl_group
                    let parts = split(item.trimmed)
                    if len(parts) >= 2
                        let first = parts[0]
                        let second = ''
                        let width = ''
                        let name_idx = 1

                        " 处理 input/output/inout
                        if first =~# '^\(input\|output\|inout\)$' && len(parts) >= 3
                            let second = parts[1]
                            let name_idx = 2
                        endif

                        " 检查位宽
                        if name_idx < len(parts) && parts[name_idx] =~# '^\['
                            let w = parts[name_idx]
                            let wi = name_idx
                            while wi < len(parts) && w !~# '\]$'
                                let wi += 1
                                if wi < len(parts)
                                    let w .= ' ' . parts[wi]
                                endif
                            endwhile
                            let width = w
                            let name_idx = wi + 1
                        endif

                        " 计算前缀长度（方向 + 类型 + 位宽 + 空格）
                        let prefix_len = strlen(first) + 1  " first + 空格
                        if second != ''
                            let prefix_len += strlen(second) + 1
                        endif
                        if width != ''
                            let prefix_len += strlen(width) + 1
                        endif

                        let name = join(parts[name_idx:], ' ')
                        let leading = match(a:lines[item.index], '\S')
                        if leading < 0
                            let leading = 0
                        endif

                        " 使用字典变量而不是字面量
                        let entry = {}
                        let entry.first = first
                        let entry.second = second
                        let entry.width = width
                        let entry.name = name
                        let entry.prefix_len = prefix_len
                        let entry.index = item.index
                        let entry.leading = leading
                        call add(parsed, entry)

                        if prefix_len > max_prefix_len
                            let max_prefix_len = prefix_len
                        endif
                    endif
                endfor

                " 应用对齐 - 名字从同一列开始
                let name_col = max_prefix_len + 1  " 额外 1 个空格

                for p in parsed
                    if p.leading < 0
                        let p.leading = 0
                    endif

                    " 构建前缀
                    let prefix = p.first . ' '
                    if p.second != ''
                        let prefix .= p.second . ' '
                    endif
                    if p.width != ''
                        let prefix .= p.width . ' '
                    endif

                    " 计算名字前的空格数
                    let name_spaces = name_col - strlen(prefix)
                    if name_spaces < 1
                        let name_spaces = 1
                    endif

                    let new_line = repeat(' ', p.leading) . prefix . repeat(' ', name_spaces) . p.name
                    let a:lines[p.index] = new_line
                endfor
            endif

            if i == decl_start
                let i += 1
            endif
        else
            let i += 1
        endif
    endwhile

    return a:lines
endfunction

" 格式化选区
function! verilog#formatter#FormatRange(start, end)
    call verilog#formatter#InitConfig()
    let save_cursor = getpos('.')
    let lines = getline(a:start, a:end)

    let i = 0
    while i < len(lines)
        let lines[i] = verilog#formatter#Detab(lines[i])
        let i += 1
    endwhile

    let base_indent = len(matchstr(lines[0], '^\s*'))
    for i in range(len(lines))
        let trimmed = substitute(lines[i], '^\s*', '', '')
        if trimmed != ''
            let lines[i] = repeat(' ', base_indent) . trimmed
        endif
    endfor

    silent! execute a:start . ',' . a:end . 'delete _'
    for i in range(len(lines))
        call append(a:start + i - 1, lines[i])
    endfor

    call setpos('.', save_cursor)
    echo "选区格式化完成"
endfunction
