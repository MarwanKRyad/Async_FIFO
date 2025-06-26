module Async_FIFO #(parameter FIFO_width=32) (
input[FIFO_width-1:0] i_wdata,
input i_rst_n,
input i_wr,
input i_rd,
input i_wclk,
input i_rclk,
output o_wfull,
output o_rempty,
output reg [FIFO_width-1:0] o_rdata

	);

reg [FIFO_width-1:0] FIFO [0:15];
reg [4:0] w_count_binary=0; 
reg [4:0] r_count_binary=0; 
wire [4:0] w_count_gray; 
wire [4:0] r_count_gray; 

reg[4:0] w_count1_gray;
reg[4:0] w_count2_gray;
wire [4:0] w_count2_binary;


reg[4:0] r_count1_gray;
reg[4:0] r_count2_gray;
wire [4:0] r_count2_binary;

reg [FIFO_width-1:0] buffer0 ;
reg buffer0_valid=0 ;
reg [FIFO_width-1:0] buffer1 ;
reg buffer1_valid=0 ;
reg [FIFO_width-1:0] buffer4 ;
reg buffer4_valid=0 ;

reg buffer2_valid=0 ;
reg buffer3_valid=0 ;
reg buffer5_valid=0 ;
reg[2:0] count2=0;
reg[2:0] count3=0;
reg[2:0] count5=0;


function [4:0]  gray_to_binary;
	input[4:0] gray;
	integer i;
	begin
	gray_to_binary[4]=gray[4];
	for(i=3;i>=0;i=i-1)
	 gray_to_binary[i] = gray[i] ^ gray_to_binary[i + 1];
	end
endfunction 

function[4:0]  binary_to_gray;
	input[4:0] binary;
	begin
	 binary_to_gray[4]=binary[4];
	 binary_to_gray[3:0] = binary[4:1] ^ binary[3:0];	
	end
endfunction


assign w_count_gray=binary_to_gray(w_count_binary);
assign r_count_gray=binary_to_gray(r_count_binary);

assign w_count2_binary=gray_to_binary(w_count2_gray);
assign r_count2_binary=gray_to_binary(r_count2_gray);


assign o_wfull=(~i_rst_n)?0:((w_count_binary[4] != r_count2_binary[4]) &&  // MSB check to detect wrap-around
(w_count_binary[3:0] == r_count2_binary[3:0]));

assign o_rempty =(~i_rst_n)?1:(r_count_binary==w_count2_binary);

/*...................................... reading logic..................................... */
always @(posedge i_wclk or negedge i_rst_n) 
begin

	if(i_rst_n==0)
		begin
		w_count_binary <= 0;
        buffer0_valid <= 0;
        buffer1_valid <= 0;
        buffer4_valid <= 0;
        r_count1_gray <= 0;
        r_count2_gray <= 0;
		end

	else 
	begin			
    if (!o_wfull && (buffer0_valid || buffer1_valid || buffer4_valid) ) begin
        if(buffer0_valid)
        	begin
			FIFO[w_count_binary[3:0]] <= buffer0;
			w_count_binary <= w_count_binary + 1;
        	end
        if(buffer1_valid)
        	begin
        	buffer0<=buffer1;
        	buffer0_valid <= buffer1_valid;
        	end
        else 
        	begin
        		buffer0_valid<=0;
        	end
        if(buffer4_valid)
        	begin
        	buffer1<=buffer4;
        	buffer1_valid <= buffer4_valid;
        	buffer4_valid<=0;
        	end
        else
       		begin
        	buffer1_valid<=0;	
        	end	
    end

    if (i_wr) 
    begin
        if (!o_wfull && !buffer0_valid && !buffer1_valid && !buffer4_valid)
            begin
            FIFO[w_count_binary[3:0]] <= i_wdata;
            w_count_binary <= w_count_binary + 1;
            end
        else if(!buffer0_valid)
            begin
            buffer0<=i_wdata;
            buffer0_valid<=1;
            end
        else if (!buffer1_valid)
            begin
            buffer1<=i_wdata;
            buffer1_valid<=1;
            end
        else if (!buffer4_valid)
            begin
            buffer4<=i_wdata;
            buffer4_valid<=1;
            end   
    end

    //2FF sync
    r_count1_gray<=r_count_gray;
    r_count2_gray<=r_count1_gray;
    end
end



/*...................................... wrtiting logic..................................... */
always @(posedge i_rclk or negedge i_rst_n) 
	begin 

	if(i_rst_n==0)
	begin
	r_count_binary <= 0;
    buffer2_valid <= 0;
    buffer3_valid <= 0;
    buffer5_valid <= 0;
    w_count1_gray <= 0;
    w_count2_gray <= 0;
    o_rdata <= 0;
	end


	else
	begin		
	if(o_rempty && i_rd)
		begin
			if(!buffer2_valid)
				begin
					buffer2_valid<=1;	
				end
			else if (!buffer3_valid)
				begin
					buffer3_valid<=1;
				end
			else if (!buffer5_valid)
				begin
					buffer5_valid<=1;
				end
		end
	if(buffer2_valid && o_rempty)
		count2<=count2+1;	

	if(count2==2)
		begin
			buffer2_valid<=0;
			count2<=0;
		end

	if(buffer3_valid && o_rempty)
		count3<=count3+1;	

	if(count3==2)
		begin
			buffer3_valid<=0;
			count3<=0;
		end

	if(buffer5_valid && o_rempty)
		count5<=count5+1;	

	if(count5==2)
		begin
			buffer5_valid<=0;
			count5<=0;
		end
	if(!o_rempty)
		begin
			if(buffer2_valid && buffer3_valid && buffer5_valid && i_rd )
				begin
					o_rdata<=FIFO[r_count_binary[3:0]];
					r_count_binary<=r_count_binary+1;
					buffer2_valid<=1;
					buffer3_valid<=1;
					buffer5_valid<=1;
				end
			else if( (buffer2_valid && buffer3_valid && buffer5_valid && !i_rd) || (buffer2_valid && buffer3_valid && !buffer5_valid && i_rd))
				begin
					o_rdata<=FIFO[r_count_binary[3:0]];
					r_count_binary<=r_count_binary+1;
					buffer2_valid<=1;
					buffer3_valid<=1;
					buffer5_valid<=0;
				end
			else if ( (buffer2_valid && buffer3_valid && !i_rd && !buffer5_valid) || (buffer2_valid && !buffer3_valid && i_rd && !buffer5_valid) )
				begin
					o_rdata<=FIFO[r_count_binary[3:0]];
					r_count_binary<=r_count_binary+1;
					buffer2_valid<=1;
					buffer3_valid<=0;
					buffer5_valid<=0;
				end
			else if (buffer2_valid && !buffer3_valid && !i_rd && !buffer5_valid)
				begin
					o_rdata<=FIFO[r_count_binary[3:0]];
					r_count_binary<=r_count_binary+1;
					buffer2_valid<=0;
					buffer3_valid<=0;
				end	
			else if (!buffer2_valid && !buffer3_valid &&!buffer5_valid && i_rd)
				begin
					o_rdata<=FIFO[r_count_binary[3:0]];
					r_count_binary<=r_count_binary+1;
				end		
		end
	//2FF sync
	w_count1_gray<=w_count_gray;
	w_count2_gray<=w_count1_gray;
  end
end
endmodule 