module top (
    input clk,
    input rst_n,
    output [6:0]seg,
    input all_sw,//高为弹球，低为钢琴
    output [3:0]seg_sel,
    input [2:0]move,//0为左，2为右
    input [9:0]sw,
    input displaymode,
    output beep,
//    output add_cnt0,
    output warn_flag,
    output vga_clk,
    output hs,
    output vs,
    output [15:0]regrgb1
);

wire sys_clk;

wire [2:0]OutRed;
wire [2:0]OutGreen;
wire [2:1]OutBlue;
wire [15:0]regrgb;

assign regrgb1[15:13] = all_sw ? OutRed : regrgb[15:13];
assign regrgb1[12:11] = all_sw ? 2'b0 : regrgb[12:11];
assign regrgb1[10:8] = all_sw ? OutGreen : regrgb[11:9];
assign regrgb1[7:5] = all_sw ? 3'b0 : regrgb[8:5];
assign regrgb1[4:3] = all_sw ? OutBlue : regrgb[4:3];
assign regrgb1[2:0] = all_sw ? 3'b0 : regrgb[2:0];

//always@(*)begin
//    regrgb[15:13] = all_sw ? OutRed : regrgb[15:13];
//    regrgb[12:11] = all_sw ? 2'b0 : regrgb[12:11];
//    regrgb[11:9] = all_sw ? OutGreen : regrgb[11:9];
//    regrgb[8:5] = all_sw ? 3'b0 : regrgb[8:5];
//    regrgb[4:3] = all_sw ? OutBlue : regrgb[4:3];
//    regrgb[2:0] = all_sw ? 3'b0 : regrgb[2:0];
//end



wire VSync;
wire cys;
assign vs = all_sw ? VSync : cys;

wire HSync;
wire hys;
assign hs = all_sw ? HSync : hys;

wire clk_vga;
wire add_cnt0;
assign vga_clk = all_sw ? clk_vga : add_cnt0;

//[9:0]sw
wire [3:0]bar_move_speed;
wire [3:0]an;
wire [1:0]an_back;
assign an = sw[9:6];
assign an_back = sw[5:4];
assign bar_move_speed = sw[3:0];

wire seg_LED;
wire seg_p;
assign seg = all_sw ? seg_LED : seg_p;

wire [3:0]seg_select;
wire [3:0]we;
assign seg_sel = all_sw ? seg_select : we;

wire to_left;
wire to_right;
wire [2:0]key;
assign to_left = all_sw ? move[0] : 0;
assign to_right = all_sw ? move[2] : 0;
assign key = all_sw ? 0 : move;

pll u_pll(
    .refclk(clk),
    .reset(!rst_n),
    .extlock(),
    .clk0_out(),
    .clk1_out (sys_clk)
);

SBgame u_SBgame(
    .sys_clk        ( sys_clk        ),
    .rst_n          ( rst_n          ),
    .to_left        ( to_left        ),
    .to_right       ( to_right       ),
    .bar_move_speed ( bar_move_speed ),
    .HSync          ( HSync          ),
    .VSync          ( VSync          ),
    .OutBlue        ( OutBlue        ),
    .OutGreen       ( OutGreen       ),
    .OutRed         ( OutRed         ),
    .clk_vga        ( clk_vga        ),
    .seg_select     ( seg_select     ),
    .seg_LED        ( seg_LED        )
);


VGA_piano u_VGA_piano(
    .sys_clk     ( sys_clk     ),
    .rst_n       ( rst_n       ),
    .an          ( an          ),
    .an_back     ( an_back     ),
    .displaymode ( displaymode ),
    .key         ( key         ),
    .seg         ( seg_p       ),
    .we          ( we          ),
    .rgb         ( regrgb      ),
    .hys         ( hys         ),
    .cys         ( cys         ),
    .beep        ( beep        ),
    .add_cnt0    ( add_cnt0    ),
    .warn_flag   ( warn_flag   )
);

endmodule