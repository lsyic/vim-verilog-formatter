// Verilog 格式化测试文件
// 此文件用于测试 vim-verilog-formatter 插件的格式化效果

module test_verilog_format(
input clk,
input rst_n,
input wire [31:0] data_in,
output reg [31:0] data_out,
output wire valid
);

//参数定义
parameter WIDTH = 32;
localparam MAX_VAL = 255;

//信号声明
reg [31:0] counter;
reg [7:0] state;
wire enable;
wire [3:0] sel;
logic [63:0] temp_data;

//赋值语句
assign valid = (counter > 0);
assign out = (sel == 0) ? a : b; //选择器输出
assign result = data + offset; //计算结果

// always 块
always @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
counter <= 0;
state <= 0;
end
else begin
if (enable) begin
counter <= counter + 1;
state <= state + 1;
end
end
end

// case 语句
always @(*) begin
case (state)
0: begin
data_out = 0;
end
1: begin
data_out = data_in;
end
2: begin
data_out = data_in + 1;
end
default: begin
data_out = 0; //默认值
end
endcase
end

// generate 块
genvar i;
generate
for (i = 0; i < 4; i = i + 1) begin: gen_block
always @(posedge clk) begin
if (rst_n) begin
data_out[i*8 +: 8] <= 0;
end
end
end
endgenerate

endmodule

// 第二个 module 示例
interface axi_lite_if;
logic aw_valid;
logic aw_ready;
logic [31:0] aw_addr;

logic w_valid;
logic w_ready;
logic [31:0] w_data;

// 块注释示例
/*
 * 这是一个块注释
 * 用于测试格式化效果
 */

endinterface
