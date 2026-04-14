# Verilog Format - Verilog 格式化 Vim 插件

一个用于格式化 Verilog/SystemVerilog 代码的 Vim 插件，支持信号名对齐、注释对齐、自动缩进等功能。

## 功能特性

- **自动缩进**：以 4 个空格为单位自动缩进（可配置）
- **信号名对齐**：对齐 `wire`, `reg`, `logic`, `input`, `output` 等声明
- **注释对齐**：行尾注释和块注释自动对齐
- **端口对齐**：module 端口声明对齐
- **case 语句对齐**：case item 标签对齐
- **操作符对齐**：赋值语句 `=` 和 `<=` 对齐
- **支持的结构**：
  - module / endmodule
  - interface / endinterface
  - package / endpackage
  - begin / end
  - case / endcase
  - generate / endgenerate
  - fork / join

## 安装

### 手动安装

```bash
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone <repository-url> vim-verilog-formatter
```

### 使用 vim-plug

在 `.vimrc` 中添加：

```vim
Plug '<repository-url>'
```

然后运行 `:PlugInstall`

## 使用方法

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+k` | 格式化整个文件 |
| `Ctrl+\` | 格式化整个文件（备用，当 Ctrl+k 被终端占用时） |
| `Ctrl+k`（可视模式） | 格式化选中的区域 |
| `Ctrl+\`（可视模式） | 格式化选中的区域 |

**注意**：某些终端可能会拦截 `Ctrl+k`，如果遇到快捷键不生效的情况，请尝试使用 `Ctrl+\` 或者在 Vim 中直接使用 `:VerilogFormat` 命令。

### 命令

| 命令 | 功能 |
|------|------|
| `:VerilogFormat` | 格式化整个文件 |
| `:VerilogFormatRange` | 格式化指定行范围 |
| `:VerilogFormatHelp` | 显示帮助信息 |

### 示例

```vim
" 格式化整个文件
:VerilogFormat

" 格式化第 10 到 50 行
:10,50VerilogFormatRange

" 在可视模式下选择区域后按 \vs
```

## 配置选项

在 `.vimrc` 中添加以下配置：

```vim
" 缩进空格数（默认：4）
let g:verilog_format_indent = 4

" 是否对齐操作符（默认：1）
let g:verilog_format_align_ops = 1

" 是否将 Tab 转换为空格（默认：1）
let g:verilog_format_tab_spaces = 1
```

## 示例

### 格式化前

```verilog
module test(
input clk,
input rst_n,
output wire [7:0] data_out,
input wire [7:0] data_in
);
reg [3:0] counter;
wire enable;
assign out = (en) ? data : 4'b0; // 默认值
always @(posedge clk) begin
if (rst_n) begin
counter <= 0;
end
end
endmodule
```

### 格式化后

```verilog
module test(
    input      clk,
    input      rst_n,
    output wire [7:0] data_out,
    input wire [7:0] data_in
);
    reg  [3:0] counter;
    wire       enable;

    assign out = (en) ? data : 4'b0;    // 默认值

    always @(posedge clk) begin
        if (rst_n) begin
            counter <= 0;
        end
    end
endmodule
```

## 文件结构

```
vim-verilog-formatter/
├── plugin/
│   └── verilog_format.vim    # 插件入口（命令和快捷键）
├── autoload/
│   └── verilog/
│       └── formatter.vim     # 核心格式化逻辑
├── doc/
│   └── verilog_format.txt    # Vim 帮助文档
├── test/
│   └── test.v                # 测试文件
├── README.md                  # 本文件
└── LICENSE
```

## 测试

在 `test/test.v` 中包含了测试用例，可以打开文件后按 `\vf` 查看格式化效果。

## 注意事项

- 插件使用 `buffer-local` 映射，只在 Verilog 文件中生效
- 格式化会修改原文件内容，建议先保存或使用版本控制
- 某些复杂的格式化场景可能需要手动调整

## License

MIT License
