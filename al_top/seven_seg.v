`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:11:34 05/26/2016 
// Design Name: 
// Module Name:    seven_seg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`include "Definition.h"
module seven_seg(
    input clk,
	 input rst_n,
	 input lose,
     input get,
     input [3:0] bar_move_speed,
    output reg [3:0] select,
    output reg [6:0] seg
    );

reg [4:0] num0 = 5'b0;

reg [3:0] num1 = 4'b0;

reg [3:0] num2 = 4'b0;

reg [3:0] num3 = 4'b0;

reg [1:0] cnt = 0;

reg [6:0] clk_cnt = 0;
reg sclk = 0;

always@(posedge clk)
begin
	if(clk_cnt == 127)
	begin
		sclk <= ~sclk;
		clk_cnt <= 0;
	end
	else
		clk_cnt <= clk_cnt + 1;
end

wire [6:0] out0;
wire [6:0] out1;
wire [6:0] out2;
wire [6:0] out3;

seg_decoder seg0(
	.clk(clk),
	.num(num0),
	.code(out0)
	);

seg_decoder seg1(
	.clk(clk),
	.num(num1),
	.code(out1)
	);

seg_decoder seg2(
	.clk(clk),
	.num(num2),
	.code(out2)
	);

seg_decoder seg3(
	.clk(clk),
	.num(num3),
	.code(out3)
	);
	
// 数码管显示
always@(posedge sclk or negedge rst_n)
begin
	if(!rst_n) 
	begin
		cnt <= 0;
	end
	else
	begin
		case(cnt)
		2'b00:
		begin
			seg <= out0;
			select <= 4'b0111;
		end	
		2'b01:
		begin
			seg <= out1;
			select <= 4'b1011;
		end
		2'b10:
		begin
			seg <= out2;
			select <= 4'b1101;
		end
		2'b11:
		begin
			seg <= out3;
			select <= 4'b1110;
		end
		default:
		begin
			seg <= seg;
			select <= select;
		end
		endcase
		cnt <= cnt + 1;	
		if(cnt == 2'b11)
			cnt<=0;
	end
end

// 每次丢失时刷新数据
always@(posedge get or negedge rst_n)
begin
	if(!rst_n)
	begin
		num0 <= 0;
		num1 <= 0;
		num2 <= 0;
		num3 <=0;
	end
	// else if(num0 == 9)
	// begin
	// 	num0 <= 0;
	// 	if(num1 == 9)
	// 	begin
	// 		num1 <= 0;
	// 		if(num2 == 9)
	// 		begin
	// 			num2 <= 0;
	// 			if(num3 == 9)
	// 				num3 <= 0;
	// 			else
	// 				num3 <= num3 + 1;
	// 		end
	// 		else
	// 			num2 <= num2 + 1;
	// 	end
	// 	else
	// 		num1 <= num1 + 1;
	// end
	else if(num0 + bar_move_speed>= 20) begin
        	num1 <= num1 + 2;
            num0 <= num0 + bar_move_speed - 20;
			if(num1 == 9)
		begin
			num1 <= 0;
			if(num2 == 9)
			begin
				num2 <= 0;
				if(num3 == 9)
					num3 <= 0;
				else
					num3 <= num3 + 1;
			end
			else
				num2 <= num2 + 1;
		end
		else
			num1 <= num1 + 1;
        	end
    else if(num0 + bar_move_speed > 9)begin
        	num1 <= num1 + 1;
            num0 <= num0 + bar_move_speed - 10;
			if(num1 == 9)
		begin
			num1 <= 0;
			if(num2 == 9)
			begin
				num2 <= 0;
				if(num3 == 9)
					num3 <= 0;
				else
					num3 <= num3 + 1;
			end
			else
				num2 <= num2 + 1;
		end
		else
			num1 <= num1 + 1;
        	end     
	else	num0 <= num0 + bar_move_speed;	
end	


endmodule
