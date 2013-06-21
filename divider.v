`timescale 1ns/10ps
module div(
clk,
en,
rst,
dividend,
divisor,
quotient
);

//==============================================================================
// MY PORT DECLARATION
//==============================================================================
parameter a_width = 21;
parameter b_width = 13;
parameter q_width = 8;

input clk;
input en;
input rst;
input  [a_width-1:0] dividend;//40 //n-1
input  [b_width-1:0] divisor;
output [q_width-1:0] quotient;


//reg subtract_r;
reg [1:0]  c_state,n_state;
reg signed [2*a_width-1:0] r_rem,r_div; //n*2-1 n=16,28,40
reg [a_width-1:0] r_quo; //n-1
reg [6:0] counter_r,counter_w;
reg [a_width-1:0] ans_temp;

assign quotient=ans_temp[q_width-1:0];


parameter Idle          =2'd0;
parameter ADD           =2'd1;
parameter SUB           =2'd2;
parameter Finish        =2'd3;

always@(posedge clk )
begin
  if(rst) 
  c_state<=Idle;
  else      
	c_state<=n_state;
end

always @* 
begin

 case(c_state)
	Idle:begin
			if(en) 
				n_state = SUB;
			else         
				n_state = c_state;
		end
	SUB:begin
			if(counter_r==a_width+2)  //n+2 16,28               
				n_state=Finish;
			else if(r_rem[2*a_width-1])      //n*2-1 n=16,28                            
				n_state=ADD;
			else
				n_state = c_state;
		end
	ADD:begin
			if(counter_r==a_width+2)                  
				n_state=Finish;
			else if(!r_rem[2*a_width-1])                                   
				n_state=SUB;
			else
				n_state = c_state;			

        end	
	Finish:	 n_state = Idle;			
	default :	 n_state = Idle;	  
	
 endcase
end

always @(posedge clk)
begin
    if(rst)
	   counter_r <=7'b0; 
	else
       counter_r<=counter_w;
end

always @(*)
begin
    if(en)
	   counter_w <=counter_r+1; 
	else
       counter_w <=0;
end

always@(posedge clk )
begin
  if(rst) 
	ans_temp<=0;
  else if(counter_r == a_width+3)     
	ans_temp <=r_quo;
  else
   ans_temp <=ans_temp; 
end

always @(posedge clk)
begin
    if(rst)
	    r_rem <={21'b0,dividend};//21 =a_width
    else if(counter_r < a_width+1 && en) //n+1
	   case(n_state)
		ADD:r_rem <= r_rem + r_div;
		SUB:r_rem <= r_rem - r_div;
		endcase 
	else
        r_rem <=r_rem;		    
end
 
always @(posedge clk)
begin
    if(rst)
		r_div<={divisor,21'b0};// 21 = a_width
    else if(counter_w > 0)
		r_div <= r_div>>>1;
	else 
	    r_div<=r_div; 
end

always @(posedge clk)
begin
    if(rst)
		r_quo<=0;
    else if(counter_r > 0 &&counter_r<a_width+2) //4+2//n+2
	    case(r_rem[2*a_width-1])//2n-1
		0:r_quo <={r_quo[a_width-2:0],1'b1}; //4-2//X-2
		1:r_quo <={r_quo[a_width-2:0],1'b0};
		endcase
	else r_quo <=r_quo;	 
end


endmodule 
