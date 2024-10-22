
module asyn_fifo
	#(
		parameter DATA_WIDTH=8,
					 FIFO_DEPTH_WIDTH=11  
	)
	(
	input wire rst_n,
	input wire clk_write,clk_read, 
	input wire write,read, 
	input wire [DATA_WIDTH-1:0] data_write,
	output [DATA_WIDTH-1:0] data_read, 
	output reg full,empty, 
	output reg[FIFO_DEPTH_WIDTH-1:0] data_count_w,data_count_r 
    );
 
	 localparam FIFO_DEPTH=2**FIFO_DEPTH_WIDTH;
	 
	 initial begin
		full=0;
		empty=1;
	 end
	 
	 
	 ///////////////////WRITE CLOCK DOMAIN
	 reg[FIFO_DEPTH_WIDTH:0] w_ptr_q=0; //binary counter for write pointer
	 reg[FIFO_DEPTH_WIDTH:0] r_ptr_sync; //binary pointer for read pointer sync to write clk
	 reg[FIFO_DEPTH_WIDTH:0] r_grey_sync; //grey counter for the read pointer synchronized to write clock
	 reg[3:0] i; //log_2(FIFO_DEPTH_WIDTH)
	 
	 wire[FIFO_DEPTH_WIDTH:0] w_grey,w_grey_nxt; //grey counter for write pointer
	 wire we;
	 	 
	 assign w_grey=w_ptr_q^(w_ptr_q>>1); //binary to grey code conversion for current write pointer
	 assign w_grey_nxt=(w_ptr_q+1'b1)^((w_ptr_q+1'b1)>>1);  //next grey code
	 assign we= write && !full; 
	 
	 //register operation
	 always @(posedge clk_write,posedge rst_n) begin
		if(!rst_n) begin
			w_ptr_q<=0;
			full<=0;
		end
		else begin
			if(write && !full) begin //write condition
				w_ptr_q<=w_ptr_q+1'b1; 
				full <= w_grey_nxt == {~r_grey_sync[FIFO_DEPTH_WIDTH:FIFO_DEPTH_WIDTH-1],r_grey_sync[FIFO_DEPTH_WIDTH-2:0]}; //algorithm for full logic which can be observed on the grey code table
			end
			else full <= w_grey == {~r_grey_sync[FIFO_DEPTH_WIDTH:FIFO_DEPTH_WIDTH-1],r_grey_sync[FIFO_DEPTH_WIDTH-2:0]}; 
			
			for(i=0;i<=FIFO_DEPTH_WIDTH;i=i+1) r_ptr_sync[i]=^(r_grey_sync>>i); //grey code to binary converter 
			data_count_w <= (w_ptr_q>=r_ptr_sync)? (w_ptr_q-r_ptr_sync):(FIFO_DEPTH-r_ptr_sync+w_ptr_q); //compares write pointer and sync read pointer to generate data_count
		end							
	 end

	
	 reg[FIFO_DEPTH_WIDTH:0] r_ptr_q=0; //binary counter for read pointer
	 reg[FIFO_DEPTH_WIDTH:0] w_ptr_sync; //binary counter for write pointer sync to read clk
	 reg[FIFO_DEPTH_WIDTH:0] w_grey_sync; //grey counter for the write pointer synchronized to read clock
	 
	 wire[FIFO_DEPTH_WIDTH:0] r_grey,r_grey_nxt; //grey counter for read pointer 
	 wire[FIFO_DEPTH_WIDTH:0] r_ptr_d;
	 
	 
	 assign r_grey= r_ptr_q^(r_ptr_q>>1);  //binary to grey code conversion
	 assign r_grey_nxt= (r_ptr_q+1'b1)^((r_ptr_q+1'b1)>>1); //next grey code
	 assign r_ptr_d= (read && !empty)? r_ptr_q+1'b1:r_ptr_q;
	 
	 
	//CLOCK DOMAIN CROSSING
	 reg[FIFO_DEPTH_WIDTH:0] r_grey_sync_temp;
	 reg[FIFO_DEPTH_WIDTH:0] w_grey_sync_temp;
	 always @(posedge clk_write) begin //2 D-Flipflops for reduced metastability in clock domain crossing from READ DOMAIN to WRITE DOMAIN
		r_grey_sync_temp<=r_grey; 
		r_grey_sync<=r_grey_sync_temp;
	 end
	 always @(posedge clk_read) begin //2 D-Flipflops for reduced metastability in clock domain crossing from WRITE DOMAIN to READ DOMAIN
		w_grey_sync_temp<=w_grey;
		w_grey_sync<=w_grey_sync_temp;
	 end

endmodule


	
