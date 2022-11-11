module VGA_piano( 
	input sys_clk,
	input rst_n, 
	input [3:0]an,
	input [1:0]an_back,
	input displaymode,
	input [2:0]key,
	output reg [6:0]seg, 
	output [3:0]we,
	output reg[15:0]rgb, 
	output reg hys,
	output reg cys,
	output reg beep,
    output	add_cnt0,
	output reg warn_flag
    );
    wire clk;

//时钟变量
reg [3:0]Num;//显示数值
reg [25:0]counter1;//计秒钟
reg [15:0]counter2;//计毫秒
reg [3:0]state;
reg [3:0]sec_g,sec_s,fen_g,fen_s,shi_g,shi_s;//计秒钟次数
reg _sclk;//秒时钟
reg _msclk;//毫秒时钟
parameter we1=4'b1110,
		  we2=4'b1101,
		  we3=4'b1011,
		  we4=4'b0111;
//cnt时钟转换为基准时钟
reg cnt;
wire add_cnt;
wire end_cnt;	
//cnt0基准时钟数
reg [9:0]cnt0; 
//wire add_cnt0;
wire end_cnt0;
//cnt1行数
reg [9:0]cnt1; 
wire add_cnt1;
wire end_cnt1;
//channel
reg t00,t01,t02,t03,t04;
reg t10,t11,t12,t13,t14;
reg t20,t21,t22,t23,t24;
reg display;
//移动时钟
reg clk1;
reg [24:0]cnt2; 
wire add_cnt2;
wire end_cnt2;
//计数器
reg [7:0] a;
reg [7:0] b;
reg [7:0] c;
wire count0;
wire count1;
wire count2;
//列移动位
reg [8:0]t;//第t列
reg flag_t;//一帧扫描完
reg [9:0]T;
//数据请求
wire data_req;  
//vga数据输出
wire vga_en;
//位置
wire [9:0]pos_x;
wire [9:0]pos_y;
//边框
reg bianjie;//黑框标志位
//parameter define  
parameter  H_SYNC   =  10'd96;    //行同步
parameter  H_BACK   =  10'd48;    //行显示后沿
parameter  H_DISP   =  10'd640;   //行有效数据
parameter  H_FRONT  =  10'd16;    //行显示前沿
parameter  H_TOTAL  =  10'd800;   //行扫描周期

parameter  V_SYNC   =  10'd2;     //场同步
parameter  V_BACK   =  10'd33;    //场显示后沿
parameter  V_DISP   =  10'd480;   //场有效数据
parameter  V_FRONT  =  10'd10;    //场显示前沿
parameter  V_TOTAL  =  10'd525;   //场扫描周期
//通道区域
parameter hch0 = 110;
parameter hch1 = 250;
parameter hch2 = 390;
parameter hch3 = 530;
//检测区域
reg check;//在检测区域时为1，不在检测区域时为0
reg check1;
reg check2;
reg check3;
parameter lcheck1=330;
parameter lcheck2=390;
//按键中间变量
//按键一
reg [19:0]key_xd;
reg key_reg;        //按键状态的中间变量
reg KEY_flag;
reg KEY_value;
reg key_check;//按键检查
//按键二
reg [19:0]key_xd1;
reg key_reg1;        //按键状态的中间变量
reg KEY_flag1;
reg KEY_value1;
reg key_check1;//按键检查
//按键三
reg [19:0]key_xd2;
reg key_reg2;        //按键状态的中间变量
reg KEY_flag2;
reg KEY_value2;
reg key_check2;//按键检查
parameter key_delay_time=20'd250_000;
//蜂鸣器
wire beep_flag;//beep打开标志位
reg [9:0]pwm;//蜂鸣器PWM
//时钟显示代码
//T=1S
















reg under_check;






always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			begin
				counter1<=0;
				_sclk<=0;
				//sec=0;
			end
		else if(counter1!=25_000_000-1)
			counter1<=counter1+1;
		else
			begin	
				counter1<=0;
				_sclk<=~_sclk;//0.5秒变换一次
				//sec=sec+1;
			end
	end
//T=1MS
always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			begin
				counter2<=0;
				_msclk<=0;
			end
		else if(counter2!=25_000-1)
			counter2<=counter2+1;
		else
			begin	
				counter2<=0;
				_msclk<=~_msclk;//0.5毫秒变换一次
			end
	end	
always@(posedge _sclk or negedge rst_n)begin
	if(!rst_n)begin
		sec_g=0;
		sec_s=0;
		fen_g=0;
		fen_s=0;
		shi_g=0;
		shi_s=0;
	end
	
	else if(sec_g<9||sec_s<5)begin //秒钟不为59
		sec_g=sec_g+6-T; //秒钟个位不为10时个位自加1
		if(sec_g==10)begin //秒钟个位由9加到0时个位清0，十位自加1
			sec_g=0;
			sec_s=sec_s+1;
		end
		else if(sec_g >= 11)begin
			sec_g = sec_g - 10;
			sec_s = sec_s + 1;
			 if(sec_s >= 6)	begin
				sec_s  = 0;
				fen_g = fen_g +1;
			end
		end
	end
	else if(sec_g==9&&sec_s==5&&(fen_g<9||fen_s<5))begin //秒钟为59,分钟不为59
		sec_g=0;     //秒钟清0，分钟个位自加1
		sec_s=0;
		fen_g=fen_g+1;
		if(fen_g==10)begin//分钟个位为10时个位清0，十位自加1
			fen_g=0;
			fen_s=fen_s+1;
		end
	end
	
	else if(fen_g==9&&fen_s==5)begin //分钟为59,时钟进1,时钟为24小时时清0 
		fen_g=0;
		fen_s=0;
		shi_g=shi_g+1;
		if(shi_g==10&&shi_s<2)begin //时钟不大于20
			shi_g=0;
			shi_s=shi_s+1;
		end
		else if(shi_g==4&&shi_s==2)begin //时钟为24
			shi_g=0;
			shi_s=0;
		end	
	end
end
assign we=state;
//数码管扫描（从右往左）
always@(posedge _msclk or negedge rst_n) begin
	if(!rst_n) begin
		seg<=7'b111_1111;
		state<=4'b1111;
	end
	else if(state==we4)begin
		if(displaymode==0)begin
			case(sec_g)
				4'd0:begin seg<=7'b100_0000;end
				4'd1:begin seg<=7'b111_1001;end
				4'd2:begin seg<=7'b010_0100;end
				4'd3:begin seg<=7'b011_0000;end
				4'd4:begin seg<=7'b001_1001;end
				4'd5:begin seg<=7'b001_0010;end
				4'd6:begin seg<=7'b000_0010;end
				4'd7:begin seg<=7'b111_1000;end
				4'd8:begin seg<=7'b000_0000;end
				4'd9:begin seg<=7'b001_0000;end 
			endcase	
			state<=we1;
		end
		else if(displaymode==1)begin 
			if(T<10)begin
				case(T)
					10'd1:begin seg<=7'b111_1001;end
					10'd2:begin seg<=7'b010_0100;end
					10'd3:begin seg<=7'b011_0000;end
					10'd5:begin seg<=7'b001_0010;end
				endcase
			end
			else if(T==20)begin
				seg<=7'b100_0000;
			end
			state<=we1;
		end
	end 
	else if(state==we1)begin
		if(displaymode==0)begin
			case(sec_s)
				4'd0:begin seg<=7'b100_0000;end
				4'd1:begin seg<=7'b111_1001;end
				4'd2:begin seg<=7'b010_0100;end
				4'd3:begin seg<=7'b011_0000;end
				4'd4:begin seg<=7'b001_1001;end
				4'd5:begin seg<=7'b001_0010;end
				4'd6:begin seg<=7'b000_0010;end
				4'd7:begin seg<=7'b111_1000;end
				4'd8:begin seg<=7'b000_0000;end
				4'd9:begin seg<=7'b001_0000;end 
			endcase
			state<=we2;
		end
		else if(displaymode==1)begin 
			if(T==20)begin
				seg<=7'b010_0100;
			end
			else
				seg<=7'b111_1111;
			state<=we2;
		end
	end
	else if(state==we2)begin
		if(displaymode==0)begin
			case(fen_g)
				4'd0:begin seg<=7'b100_0000;end
				4'd1:begin seg<=7'b111_1001;end
				4'd2:begin seg<=7'b010_0100;end
				4'd3:begin seg<=7'b011_0000;end
				4'd4:begin seg<=7'b001_1001;end
				4'd5:begin seg<=7'b001_0010;end
				4'd6:begin seg<=7'b000_0010;end
				4'd7:begin seg<=7'b111_1000;end
				4'd8:begin seg<=7'b000_0000;end
				4'd9:begin seg<=7'b001_0000;end 
			endcase
			state<=we3;
		end
		else if(displaymode==1)begin 
			seg<=7'b111_1111;
			state<=we3;
		end
	end
	else if(state==we3)begin
		if(displaymode==0)begin
			case(fen_s)
				4'd0:begin seg<=7'b100_0000;end
				4'd1:begin seg<=7'b111_1001;end
				4'd2:begin seg<=7'b010_0100;end
				4'd3:begin seg<=7'b011_0000;end
				4'd4:begin seg<=7'b001_1001;end
				4'd5:begin seg<=7'b001_0010;end
				4'd6:begin seg<=7'b000_0010;end
				4'd7:begin seg<=7'b111_1000;end
				4'd8:begin seg<=7'b000_0000;end
				4'd9:begin seg<=7'b001_0000;end 
			endcase
			state<=we4;
		end
		if(displaymode==1)begin 
			seg<=7'b001_0010;
			state<=we4;
		end
	end
	else
		state<=we4;
end
//拨码开关控制刷新速度
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		T=20;
	end
	else begin
		casex(an)
			4'b0001:T=1;//1
			4'b001x:T=2;//2
			4'b01xx:T=3;//3
			4'b1xxx:T=5;//5
			4'b0000:T=20;
		endcase
	end
end
//数码管显示状态：1、2、3、4、5分别代表五种滚动速度，5为待机速度

//按键检测
//按键延时：这个模块有两个输出，一个是按键消抖完以后的信号，一个是消抖完了的标志信号
//按键一
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		key_xd<=0;
		key_reg<=1;
	end
	else if(add_cnt0)begin
		key_reg<=key[0];
		if(key_reg!=key[0])          //说明有按键按下了
			key_xd<=key_delay_time;
		else begin                        //这里开始一直减了
			if(key_xd==20'd0)
				key_xd<=20'd0;
			else
				key_xd<=key_xd-1'b1;
			end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		KEY_flag<=1'b0;
		KEY_value<=1'b1;
	end
	else if(add_cnt0)begin
		if(key_xd==20'd1) begin
			KEY_flag<=1'b1;
			KEY_value<=key[0];
		end			
		else begin
			KEY_flag<=1'b0;
			KEY_value<=KEY_value;		
		end
	end
end
//按键二
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		key_xd1<=0;
		key_reg1<=1;
	end
	else if(add_cnt0)begin
		key_reg1<=key[1];
		if(key_reg1!=key[1])          //说明有按键按下了
			key_xd1<=key_delay_time;
		else begin                        //这里开始一直减了
			if(key_xd1==20'd0)
				key_xd1<=20'd0;
			else
				key_xd1<=key_xd1-1'b1;
			end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		KEY_flag1<=1'b0;
		KEY_value1<=1'b1;
	end
	else if(add_cnt0)begin
		if(key_xd1==20'd1) begin
			KEY_flag1<=1'b1;
			KEY_value1<=key[1];
		end			
		else begin
			KEY_flag1<=1'b0;
			KEY_value1<=KEY_value1;		
		end
	end
end
//按键三
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		key_xd2<=0;
		key_reg2<=1;
	end
	else if(add_cnt0)begin
		key_reg2<=key[2];
		if(key_reg2!=key[2])          //说明有按键按下了
			key_xd2<=key_delay_time;
		else begin                        //这里开始一直减了
			if(key_xd2==20'd0)
				key_xd2<=20'd0;
			else
				key_xd2<=key_xd2-1'b1;
			end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		KEY_flag2<=1'b0;
		KEY_value2<=1'b1;
	end
	else if(add_cnt0)begin
		if(key_xd2==20'd1) begin
			KEY_flag2<=1'b1;
			KEY_value2<=key[2];
		end			
		else begin
			KEY_flag2<=1'b0;
			KEY_value2<=KEY_value2;		
		end
	end
end
//时钟转基准时钟
assign add_cnt=1;
assign end_cnt=add_cnt&&cnt==2-1;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt<=0;
	end
	else if(add_cnt)begin
		if(end_cnt)begin
			cnt<=0;
		end
		else begin
			cnt<=cnt+1;
		end
	end
end
//基准时钟计数
assign add_cnt0=end_cnt;
assign end_cnt0=add_cnt0&&cnt0==800-1;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt0<=0;
	end
	else if(add_cnt0)begin
		if(end_cnt0)
			cnt0<=0;
		else
			cnt0<=cnt0+1;	
	end
end
//行计数
assign add_cnt1=end_cnt0;
assign end_cnt1=add_cnt1&&cnt1==525-1;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt1<=0;
	end
	else if(add_cnt1)begin
		if(end_cnt1)
			cnt1<=0;
		else
			cnt1<=cnt1+1;	
	end
end
//行
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		hys<=0;
	end
	else if(add_cnt0)begin
		if(cnt0==96-1)
			hys<=1;
		else if(cnt0==800-1)
			hys<=0;
	end
end
//列
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cys<=0;
	end
	else if(add_cnt1)begin
		if(cnt1==2-1)
			cys<=1;
		else if(cnt1==525-1)
			cys<=0;
	end
end
//图像移动时钟
assign add_cnt2=1;
assign end_cnt2=add_cnt2&&cnt2==T*1000*25;//T的时间单位：ms。 原式由公式T*1000_000/40推导
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt2<=0;
		clk1<=0;
	end
	else if(add_cnt2)begin
		if(end_cnt2)begin
			cnt2<=0;
			clk1<=~clk1;
		end
		else begin
			cnt2<=cnt2+1;
		end
	end
end
//计数器
assign count0=a%2;
assign count1=b%2;
assign count2=c%2;	
always @(posedge clk or negedge rst_n)	begin
	if(~rst_n)
		a <= 8'haa;
	else
		a <= #1 {a[0]^a[1]^a[3]^a[4]^a[7],a[7:1]};
end
always @(posedge clk or negedge rst_n)	begin
	if(~rst_n)
		b <= 8'h33;
	else
		b <= #1 {b[0]^b[1]^b[3]^b[4]^b[7],b[7:1]};
end
always @(posedge clk or negedge rst_n)	begin
	if(~rst_n)
		c <= 8'h18;
	else
		c <= #1 {c[0]^c[1]^c[3]^c[4]^c[7],c[7:1]};
end
//列移动位
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		t<=0;
		t00<=0;	t10<=0;	t20<=0;
		t01<=0;	t11<=0;	t21<=0;
		t02<=0;	t12<=0;	t22<=0;
		t03<=0;	t13<=0;	t23<=0;
		t04<=0; t14<=0; t24<=0;
		flag_t<=0;
	end
	else begin
		if(t==120)begin
			t<=0;
			flag_t<=~flag_t;
			case({count1,count2,count0})
				3'b000:begin t00<=1;t10<=0;t20<=0; end
				3'b001:begin t00<=1;t10<=0;t20<=0; end
				3'b010:begin t00<=1;t10<=0;t20<=0; end
				3'b011:begin t00<=0;t10<=1;t20<=0; end
				3'b100:begin t00<=0;t10<=1;t20<=0; end
				3'b101:begin t00<=0;t10<=1;t20<=0; end
				3'b110:begin t00<=0;t10<=0;t20<=1; end
				3'b111:begin t00<=0;t10<=0;t20<=1; end
			endcase
			t01<=t00;	t02<=t01;	t03<=t02;	t04<=t03;
			t11<=t10;	t12<=t11;	t13<=t12;	t14<=t13;	
			t21<=t20;	t22<=t21;	t23<=t22;	t24<=t23;
		end
		else begin
			t<=t+1;
			if((t00==1&&t10==1)||(t00==1&&t20==1)||(t10==1&&t20==1))begin
				t00<=0;t10<=0;t20<=1;
			end
			else if(t00==0&&t10==0&&t20==0)begin
				t00<=0;t10<=1;t20<=0;
			end
		end
	end
end
//请求像素点颜色数据输入
assign data_req=(((cnt0 >= H_SYNC+H_BACK-1'b1) && (cnt0 < H_SYNC+H_BACK+H_DISP-1'b1))
                  && ((cnt1 >= V_SYNC+V_BACK) && (cnt1 < V_SYNC+V_BACK+V_DISP)))
                  ?  1'b1 : 1'b0;
//vga数据输出
assign vga_en=(((cnt0 >= H_SYNC+H_BACK) && (cnt0 < H_SYNC+H_BACK+H_DISP))
                  && ((cnt1 >= V_SYNC+V_BACK) && (cnt1 < V_SYNC+V_BACK+V_DISP)))
                  ?  1'b1 : 1'b0;
//像素点坐标
assign pos_x=data_req?(cnt0-(H_SYNC + H_BACK - 1'b1)):10'b0;
assign pos_y=data_req?(cnt1-(V_SYNC + V_BACK - 1'b1)):10'b0;
//随机显示设置

//显示单元 
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		display<=0;
	end
//---------------------------------------------------------------------
//通道一
//---------------------------------------------------------------------
	else if(data_req)begin
		if(pos_x>=hch0&&pos_x<hch3)begin
			if(pos_x>=hch0&&pos_x<hch1&&pos_y>=0&&pos_y<t)begin
				bianjie<=0;display<=t00;
			end
			else if(pos_x>=hch0&&pos_x<hch1&&pos_y>=t&&pos_y<120+t)begin
				bianjie<=0;display<=t01;
			end
			else if(pos_x>=hch0&&pos_x<hch1&&pos_y>=120+t&&pos_y<240+t)begin
				bianjie<=0;display<=t02;
			end
			else if(pos_x>=hch0&&pos_x<hch1&&pos_y>=240+t&&pos_y<360+t)begin
				bianjie<=0;display<=t03;
			end
			else if(pos_x>=hch0&&pos_x<hch1&&pos_y>=360+t&&pos_y<480)begin
				bianjie<=0;display<=t04;
			end
			
			else if(pos_x>=hch1&&pos_x<hch2&&pos_y>=0&&pos_y<t)begin
				bianjie<=0;display<=t10;
			end
			else if(pos_x>=hch1&&pos_x<hch2&&pos_y>=t&&pos_y<120+t)begin
				bianjie<=0;display<=t11;
			end
			else if(pos_x>=hch1&&pos_x<hch2&&pos_y>=120+t&&pos_y<240+t)begin
				bianjie<=0;display<=t12;
			end
			else if(pos_x>=hch1&&pos_x<hch2&&pos_y>=240+t&&pos_y<360+t)begin
				bianjie<=0;display<=t13;
			end
			else if(pos_x>=hch1&&pos_x<hch2&&pos_y>=360+t&&pos_y<480)begin
				bianjie<=0;display<=t14;
			end
			
			else if(pos_x>=hch2&&pos_x<hch3&&pos_y>=0&&pos_y<t)begin
				bianjie<=0;display<=t20;
			end
			else if(pos_x>=hch2&&pos_x<hch3&&pos_y>=t&&pos_y<120+t)begin
				bianjie<=0;display<=t21;
			end
			else if(pos_x>=hch2&&pos_x<hch3&&pos_y>=120+t&&pos_y<240+t)begin
				bianjie<=0;display<=t22;
			end
			else if(pos_x>=hch2&&pos_x<hch3&&pos_y>=240+t&&pos_y<360+t)begin
				bianjie<=0;display<=t23;
			end
			else if(pos_x>=hch2&&pos_x<hch3&&pos_y>=360+t&&pos_y<480)begin
				bianjie<=0;display<=t24;
			end
			
		end
		else if((pos_x>=0&&pos_x<hch0)||(pos_x>=hch3&&pos_x<640))begin
			bianjie<=1;
		end
	end
//---------------------------------------------------------------------
	else begin
		display<=0;
	end
end

//蜂鸣器
assign beep_flag=(t03==1&&check1==1)||(t13==1&&check2==1)||(t23==1&&check3==1);
//----------------------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		pwm<=0;
		beep<=0;
	end
	else begin
		if(pwm==T*50-1)begin
			pwm<=0;
			beep<=0;
		end
		else if(pwm==T*5-1&&t03==1&&check1==1)begin
			pwm<=pwm+1;
			beep<=1;
		end
		else if(pwm==T*8-1&&t13==1&&check2==1)begin
			pwm<=pwm+1;
			beep<=1;
		end
		else if(pwm==T*10-1&&t23==1&&check3==1)begin
			pwm<=pwm+1;
			beep<=1;
		end
		else begin
			pwm<=pwm+1;
		end
	end
end
//检测单元
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		check<=0;
	end
	else begin
		if(pos_y>=lcheck1&&pos_y<lcheck2)begin
			check<=1;
		end
		else
			check<=0;
	end	
end	

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		under_check<=0;
	end
	else begin
		if(pos_y>=lcheck2)begin
			under_check<=1;
		end
		else
			under_check<=0;
	end	
end	


reg [30:0]		cnt_warn			;
wire			add_cnt_warn		;
wire			end_cnt_warn		;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		warn_flag <= 0;
	end
	else if(beep_flag) begin
		warn_flag <= 1;
	end else if (end_cnt_warn) begin
		warn_flag <= 0;
	end
		
end


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt_warn<=0;
	end
	else if(add_cnt_warn) begin
		if (end_cnt_warn) begin
			cnt_warn<=0;
		end
		else
			cnt_warn<=cnt_warn+1;
	end
end
assign add_cnt_warn=warn_flag;
assign end_cnt_warn=add_cnt_warn&&cnt_warn==50_000_000;




always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		key_check<=0;
		key_check1<=0;
		key_check2<=0;
	end
	else begin
		if(KEY_flag==1&&KEY_value==1)begin
			key_check<=1;
		end
		else if(KEY_flag1==1&&KEY_value1==1)begin
			key_check1<=1;
		end
		else if(KEY_flag2==1&&KEY_value2==1)begin
			key_check2<=1;
		end
		else begin
			key_check<=0;
			key_check1<=0;
			key_check2<=0;
		end		
	end
end	
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		check1<=0;
		check2<=0;
		check3<=0;
	end
	else begin
		if(key_check==1)begin
			check1<=1;check2<=0;check3<=0;
		end
		else if(key_check1==1)begin
			check1<=0;check2<=1;check3<=0;
		end
		else if(key_check2==1)begin
			check1<=0;check2<=0;check3<=1;
		end
	end
end	

//颜色输出
always@(*)begin
	if(!rst_n)
		rgb<=16'b00000_000000_00000;
	else if(data_req)begin
			if(bianjie)begin
				rgb<=16'b00000_000000_11111;//蓝
			end
			else begin
				if(check==0)begin
					if (under_check&&warn_flag) 
				 
					begin
						rgb<=16'b11111_111111_11111;
					end else begin
						if(display)begin
						if(an_back==2'b00)
							rgb<=16'b00000_000000_00000;
						else if(an_back==2'b01)
							rgb<=16'b10011_000011_01011;
						else if(an_back==2'b10)
							rgb<=16'b00111_011000_00011;
						else
							rgb<=16'b00011_000001_01110;
					end
					else
						rgb<=16'b11111_111111_11111;
					end
					
				end
				else begin
					rgb<=16'b11000_000000_00000;
				end
				if(pos_x>=hch0&&pos_x<hch1&&pos_y>=lcheck1&&pos_y<lcheck2&&check1==1)begin
					rgb<=16'b11111_000000_11111;
				end
				else if(pos_x>=hch1&&pos_x<hch2&&pos_y>=lcheck1&&pos_y<lcheck2&&check2==1)begin
					rgb<=16'b11111_000000_11111;
				end
				else if(pos_x>=hch2&&pos_x<hch3&&pos_y>=lcheck1&&pos_y<lcheck2&&check3==1)begin
					rgb<=16'b11111_000000_11111;
				end
			end
	end
	else
		rgb<=16'b00000_000000_00000;
end
endmodule

