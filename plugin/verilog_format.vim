" Verilog 格式化插件 - 主入口文件
" 提供命令和快捷键定义

" 防止重复加载
if exists('g:loaded_verilog_format')
    finish
endif
let g:loaded_verilog_format = 1

" 初始化配置
call verilog#formatter#InitConfig()

" 定义全局命令
command! -nargs=0 VerilogFormat call verilog#formatter#Format()
command! -range=% VerilogFormatRange call verilog#formatter#FormatRange(<line1>, <line2>)
command! VerilogFormatHelp echo "Verilog 格式化插件\n\n快捷键:\n  Ctrl+k - 格式化整个文件\n  Ctrl+k (可视模式) - 格式化选区\n\n命令:\n  :VerilogFormat - 格式化整个文件\n  :VerilogFormatRange - 格式化选区\n\n配置选项:\n  g:verilog_format_indent - 缩进空格数 (默认：4)\n  g:verilog_format_align_ops - 操作符对齐 (默认：1)\n  g:verilog_format_tab_spaces - Tab 转空格 (默认：1)"

" 全局快捷键映射：Ctrl+k 和 Ctrl+\ 格式化
" Ctrl+k 可能被终端拦截，Ctrl+\ 作为备用
nnoremap <C-k> :<C-u>call verilog#formatter#Format()<CR>
vnoremap <C-k> :<C-u>call verilog#formatter#FormatRange(<line1>, <line2>)<CR>
nnoremap <C-\> :<C-u>call verilog#formatter#Format()<CR>
vnoremap <C-\> :<C-u>call verilog#formatter#FormatRange(<line1>, <line2>)<CR>

" 自动命令：保存时自动格式化（可选，需要用户手动启用）
" 取消下面的注释来启用自动格式化
" autocmd BufWritePre <buffer> call verilog#formatter#Format()
