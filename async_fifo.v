module async_fifo (rd_clk, wr_clk, reset, rd_en, wr_en, w_data, r_data, full, empty, valid, overflow, underflow);

   parameter data_width = 8;
   parameter fifo_depth = 16; 
   parameter address_size = 5;

   input rd_clk;
   input wr_clk;
   input reset;
   input rd_en;
   input wr_en;
   input [data_width-1 : 0] w_data;

   output reg [data_width-1 : 0] r_data;
   output full;
   output empty;
   output reg valid;
   output reg overflow;
   output reg underflow;

   reg [address_size-1:0] wr_ptr;
   reg [address_size-1:0] rd_ptr;

   wire [address_size-1:0] wr_gray_ptr;
   wire [address_size-1:0] rd_gray_ptr;

   reg  [address_size-1:0] wr_gray_ptr_s1;
   reg  [address_size-1:0] wr_gray_ptr_s2;
   reg  [address_size-1:0] rd_gray_ptr_s1;
   reg  [address_size-1:0] rd_gray_ptr_s2;

//declaring the 2 dimensional array
   reg [data_width-1:0] mem [fifo_depth-1:0];

//writing the data into fifo
   always@(posedge wr_clk) 
   begin
      if (reset) 
         wr_ptr<=0;
      else 
      begin 
         if (wr_en && !full) 
         begin
	   wr_ptr <= wr_ptr + 1;
           mem[wr_ptr] <= w_data;
         end
      end
   end

//reading the data from fifo
   always@(posedge rd_clk) 
   begin
      if (reset) 
         rd_ptr<=0;
      else 
      begin 
         if (rd_en && !empty) 
         begin
	   rd_ptr <= rd_ptr + 1;
	   r_data <= mem[rd_ptr];
         end
      end
   end

//wr_ptr,rd_ptr binary to gray
   assign wr_gray_ptr = wr_ptr ^ (wr_ptr>>1) ;
   assign rd_gray_ptr = rd_ptr ^ (rd_ptr>>1) ;

//2ff synchronizer for wr_ptr wrt rd_clk
   always@(posedge rd_clk) 
   begin
      if (reset) 
      begin
	wr_gray_ptr_s1 <= 0;
        wr_gray_ptr_s2 <= 0 ;
      end
      else 
      begin
	wr_gray_ptr_s1 <= wr_gray_ptr;
	wr_gray_ptr_s2 <= wr_gray_ptr_s1 ;
      end
   end	

//2ff synchronizer for rd_ptr wrt wr_clk
   always@(posedge wr_clk) 
   begin
      if (reset) 
      begin
	rd_gray_ptr_s1 <= 0;
        rd_gray_ptr_s2 <= 0 ;
      end
      else 
      begin
	rd_gray_ptr_s1 <= rd_gray_ptr;
	rd_gray_ptr_s2 <= rd_gray_ptr_s1 ;
      end
   end	

//empty and full condition
   assign empty = (rd_gray_ptr == wr_gray_ptr_s2);
   assign full = (wr_gray_ptr[address_size-1] != rd_gray_ptr_s2[address_size-1])
              && (wr_gray_ptr[address_size-2] != rd_gray_ptr_s2[address_size-2])
	      && (wr_gray_ptr[address_size-3:0] == rd_gray_ptr_s2[address_size-3:0]);

//overflow
   always@(posedge wr_clk) 
      overflow = full && wr_en;

//underflow
   always@(posedge rd_clk) 
   begin
      underflow <= empty && rd_en;
      valid <= (rd_en && !empty);
   end

endmodule










