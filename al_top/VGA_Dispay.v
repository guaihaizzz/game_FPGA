`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:58:04 05/18/2016 
// Design Name: 
// Module Name:    VGA_Dispay 
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
	/*
	`define right 1'b1
	`define left  1'b0
	`define up    1'b0
	`define down  1'b1
	*/
	//Do not! Don`t! Never add a ';' after a `define sentence! The compiler will FUCK YOU HARD!
`include "Definition.h"

module VGA_Dispay(
    input clk,
    input rst_n,
	 input to_left,
	 input to_right,
	 input [3:0] bar_move_speed,
    output reg hs,
    output reg vs,
    output reg [2:0] Red,
    output reg [2:0] Green,
    output reg [1:0] Blue,
    output  clk_25M,
	 output reg lose,
	 output reg get
    );
	
	//parameter definition
    parameter HPW = 96;			//行同步Horizontal synchro Pulse Width (pixels)
	parameter PAL = 640;		//行有效Pixels/Active Line (pixels)
	parameter HFP = 16;			//行前沿Horizontal synchro Front Porch (pixels)
	parameter PLD = 800;	    //行全部Pixel/Line Divider
	parameter LFD = 521;		//行/帧分隔符Line/Frame Divider
	
	
	parameter VPW = 2;			//场同步Verical synchro Pulse Width (lines)
    parameter LAF = 480;		//场有效Lines/Active Frame (lines)
	parameter VFP = 10;			//场前沿Verical synchro Front Porch (lines)
	
	parameter UP_BOUND = 10;
    parameter DOWN_BOUND = 480;  
    parameter LEFT_BOUND = 20;  
    parameter RIGHT_BOUND = 630;

//	parameter   
//		RED     =   8'b111_000_00    ,   //红色
//        ORANGE  =   8'b111_100_00    ,   //橙色
//        YELLOW  =   8'b111_111_00    ,   //黄色
//        GREEN   =   8'b000_111_00    ,   //绿色
//        CYAN    =   8'b000_111_11    ,   //青色
//        BLUE    =   8'b000_000_11    ,   //蓝色
//        PURPPLE =   8'b111_000_11    ,   //紫色
//        BLACK   =   8'b000_000_00    ,   //黑色
//        WHITE   =   8'b111_111_11    ,   //白色
//        GRAY    =   8'b110_110_11    ;   //灰色

	
	// 球的半径
	parameter ball_r = 10;
	
	
	/*寄存器定义*/
	reg [9:0] Hcnt;      // 水平计数器，  if=PLD-1->Hcnt<=0
	reg [9:0] Vcnt;      // 水平计数器，  if = LFD-1 -> Vcnt <= 0
	reg clk_25M_reg = 0;     //25MHz 
	
	reg h_speed = `RIGHT;
	reg v_speed = `UP; 
	
	// 下横杆的位置
	reg [9:0] up_pos = 400;
	reg [9:0] down_pos = 430;
	reg [9:0] left_pos = 230;
	reg [9:0] right_pos = 430;  
		
	// 球的圆心位置
	reg [9:0] ball_x_pos = 330;
	reg [9:0] ball_y_pos = 390;
	
	
	//生成25MHz的二分频时钟
	always@(posedge(clk))
	begin
		clk_25M_reg <= ~clk_25M_reg;
	end
	assign clk_25M = clk_25M_reg;
	/*生成 hs && vs 定时*/
	always@(posedge(clk_25M_reg)) 
	begin
		/*重置Hcnter && Vcnter的条件*/
		if( Hcnt == PLD-1 ) //已到达一条线的边缘
		begin
			Hcnt <= 0; //重置水平计数器
			if( Vcnt == LFD-1 ) //只有当水平指针到达边缘时，垂直计数器才能++
				Vcnt <=0;
			else
				Vcnt <= Vcnt + 1;
		end
		else
			Hcnt <= Hcnt + 1;
		
		/*生成 hs 定时*/
		if( Hcnt == PAL - 1 + HFP)
			hs <= 1'b0;
		else if( Hcnt == PAL - 1 + HFP + HPW )
			hs <= 1'b1;
		
		/*生成 vs 定时*/		
		if( Vcnt == LAF - 1 + VFP ) 
			vs <= 1'b0;
		else if( Vcnt == LAF - 1 + VFP + VPW )
			vs <= 1'b1;					
	end
	
	
	//显示球和杆
	always @ (posedge clk_25M_reg)   
	begin  
		// 显示杆
		if (Vcnt>=up_pos && Vcnt<=down_pos  
				&& Hcnt>=left_pos && Hcnt<=right_pos) 
		begin  
			Red <= 3'b111;  
			Green <= 3'b111;  
			Blue <= 2'b11;
		end  
		
		// 显示球
		else if ( (Hcnt - ball_x_pos)*(Hcnt - ball_x_pos) + (Vcnt - ball_y_pos)*(Vcnt - ball_y_pos) <= (ball_r * ball_r))  
		begin  
//			Red <= Hcnt[3:1];  
//			Green <= Hcnt[6:4];  
//			Blue <= Hcnt[8:7];
			Red <= 3'b111;  
			Green <= 3'b111;  
			Blue <= 2'b11;
            	  if(lose == 1) begin
                    Red <= 3'b000;  
					Green <= 3'b000;  
					Blue <= 2'b00; 
                    
                  end              
		end  
		else 
		begin  
			Red <= 3'b000;  
			Green <= 3'b000;  
			Blue <= 2'b00;  
		end		 
		
	end
	
	//显示砖块
	always @ (posedge clk_25M_reg) begin

	end
	
	//冲洗每个帧的图像 = =||
	always @ (posedge vs)  
   begin  		
		// 杆的运动
      if (to_left && left_pos >= LEFT_BOUND) 
		begin  
			left_pos <= left_pos - bar_move_speed;  
			right_pos <= right_pos - bar_move_speed;  
      end  
      else if(to_right && right_pos <= RIGHT_BOUND)
		begin  		
			left_pos <= left_pos + bar_move_speed; 
			right_pos <= right_pos + bar_move_speed;  
      end  
		
		//球的运动
		if (v_speed == `UP) // go up 
			ball_y_pos <= ball_y_pos - bar_move_speed;  
      else //go down
			ball_y_pos <= ball_y_pos + bar_move_speed;  
		if (h_speed == `RIGHT) // go right 
			ball_x_pos <= ball_x_pos + bar_move_speed;  
      else //go down
			ball_x_pos <= ball_x_pos - bar_move_speed;
        if(lose == 1) begin
        	ball_x_pos <= 100;
            ball_y_pos <= 100;
        end  	
   end 
	
	
	//到达边缘或挤压杆时改变方向
	always @ (negedge vs or negedge rst_n)  
   begin		// 这里，所有的判断都应该使用>=或<=，而不是==
   if(!rst_n)	lose <= 0;
   else	begin
		if (ball_y_pos <= UP_BOUND)   //球到达上边缘
		begin	
			v_speed <= 1;              // 因为当偏移量大于1时，轴可能会跨过直线
			lose <= 0;
            get <= 0;
		end
		else if (ball_y_pos >= (up_pos - ball_r) && ball_x_pos <= right_pos && ball_x_pos >= left_pos) begin//杆上反弹 
            v_speed <= 0;  
            get <= 1;
        end
		else if (ball_y_pos >= down_pos && ball_y_pos < (DOWN_BOUND - ball_r))//下掉落
		begin
			//失去时做你想做的事
			lose <= 1;
		end
//		else if (ball_y_pos >= (DOWN_BOUND - ball_r + 1))//下反弹
//			v_speed <= 0; 
     else  
            v_speed <= v_speed;  

      if (ball_x_pos <= LEFT_BOUND)  //左反弹
        	h_speed <= 1;  
      else if (ball_x_pos >= RIGHT_BOUND)  //右反弹
        	h_speed <= 0;  
      else  
        	h_speed <= h_speed;  
  end 
  end		

endmodule
