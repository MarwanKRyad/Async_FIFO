`timescale 1ns / 1ps
module Async_FIFO_tb ();
reg [31:0] i_wdata;
reg i_wr;
reg rst_n;
reg i_rd;
reg clk_in;
wire o_wfull;
wire o_rempty;
wire [31:0] o_rdata;
Async_FIFO  DUT (i_wdata,rst_n,clk_in,i_wr,i_rd,o_wfull,o_rempty,o_rdata);

initial 
begin
	clk_in=0;

	forever
	begin
	#5;
	clk_in=~clk_in;
	end

end


integer i;
initial
begin
i_wr=0; i_rd=0; i_wdata=0; rst_n=0;
#10;
rst_n=1;
#610;
	/* first i reset the FIFO */
	


	/* three cycle to avoid the xx values */
	rst_n=1; i_wr=0; i_rd=0; i_wdata=0;
	#25;
	#25;
	#25;
	i_wr=1; i_rd=0; i_wdata=0;
	#20;
	/* write the whole FIFO and more without any reading*/
	for(i=1;i<20;i=i+1)
	begin
		i_wdata=i;
	#20;
	end
	/* only reading*/
	i_wr=0; i_rd=1; i_wdata=0;
	for(i=1;i<24;i=i+1)
	begin
	#20;
	end
	i_wr=0; i_rd=0;
	#20;
	#20;
	#20;
	/* now FIFO is empty and reading buffer valid is 0 it's like we have just start*/

	/* now i will try corner cases */

	/* i will write data in the FIFO untill it becomes full 
	the next 3 cycles i will read 3 items but since domain A has 3 cycle delay it will write in buf0,buf1,buf4  
	then after 3 cycles it suppoesed to write from buf0->FIFO and afer another cycle it suppoesed to write buf1->FIFO and after another cycle it wrill write 
	but->FIFO but that's happen in case of aligned clock but we have async clock so it maybe 2 or 4 clocks instead of 3  */

	i_wr=1; i_rd=0; i_wdata=0;
	for(i=2;i<18;i=i+1)
	begin
		i_wdata=2*i;
	#20;
	end
	i_wr=1; i_rd=1; i_wdata=97;
	#20;
	i_wr=1; i_rd=1; i_wdata=98;
	#20;
	i_wr=1; i_rd=1; i_wdata=99;
	#20;
	i_rd=0; i_wdata=0; i_wr=0;
	#20;
	#20;
	#20;
	#20;
	#20;

	/* second corner case when we have an empty FIFO and domain A writes and domain B reads but wait 3 cycle untill the delay end*/
	i_wr=0; i_rd=1;
	for(i=0;i<19;i=i+1)
	begin
	#20;
	end
	i_rd=0;
	#20;
	#20;
	/* now both of read,write pointer at the same place (9) and FIFO is empty so we can do our test */
	i_wr=1; i_rd=1; i_wdata=88;
	#20;
	i_wr=1; i_rd=1; i_wdata=89;
	#20;
	i_wr=1; i_rd=1; i_wdata=90;
	#20;
	i_rd=0; i_wr=0;
	#20;
	#20;
	#20;
	#20;

	$stop;
end
endmodule 
