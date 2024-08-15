`timescale 1ns/1ps

module async_fifo_tb;

   parameter data_width = 8;
   parameter fifo_depth = 16; 
   parameter address_size = 5;

   // Testbench Signals
   reg rd_clk;
   reg wr_clk;
   reg reset;
   reg rd_en;
   reg wr_en;
   reg [data_width-1:0] w_data;

   wire [data_width-1:0] r_data;
   wire full;
   wire empty;
   wire valid;
   wire overflow;
   wire underflow;

   // Instantiate the DUT (Device Under Test)
   async_fifo #(
      .data_width(data_width),
      .fifo_depth(fifo_depth),
      .address_size(address_size)
   ) uut (
      .rd_clk(rd_clk),
      .wr_clk(wr_clk),
      .reset(reset),
      .rd_en(rd_en),
      .wr_en(wr_en),
      .w_data(w_data),
      .r_data(r_data),
      .full(full),
      .empty(empty),
      .valid(valid),
      .overflow(overflow),
      .underflow(underflow)
   );

   // Clock Generation
   initial begin
      rd_clk = 0;
      wr_clk = 0;
      forever begin
         #5 wr_clk = ~wr_clk; // 100MHz write clock
         #3 rd_clk = ~rd_clk; // 166.67MHz read clock
      end
   end

   // Test Sequence
   initial begin
      // Initializations
      reset = 1;
      rd_en = 0;
      wr_en = 0;
      w_data = 0;

      // Apply reset
      #20 reset = 0;
      
      // Write to FIFO
      #10 write_fifo(8'hA1);
      #10 write_fifo(8'hB2);
      #10 write_fifo(8'hC3);
      #10 write_fifo(8'hD4);

      // Read from FIFO
      #10 read_fifo();
      #10 read_fifo();
      #10 read_fifo();
      #10 read_fifo();

      // Check underflow
      #10 read_fifo(); // Attempt to read from empty FIFO

      // Write until FIFO is full
      repeat(fifo_depth) begin
         #10 write_fifo($random % 256);
      end

      // Check overflow
      #10 write_fifo(8'hFF); // Attempt to write to full FIFO

      // Deassert reset and test again
      #10 reset = 1;
      #10 reset = 0;

      // Write and read after reset
      #10 write_fifo(8'h11);
      #10 write_fifo(8'h22);
      #10 read_fifo();
      #10 read_fifo();

      // End of simulation
      #100 $finish;
   end

   // Task to write data to FIFO
   task write_fifo(input [data_width-1:0] data);
      begin
         @(posedge wr_clk);
         w_data = data;
         wr_en = 1;
         #10 wr_en = 0;
      end
   endtask

   // Task to read data from FIFO
   task read_fifo;
      begin
         @(posedge rd_clk);
         rd_en = 1;
         #10 rd_en = 0;
      end
   endtask

   // Monitor signals
   initial begin
      $monitor("Time: %0t | Reset: %b | Write En: %b | Read En: %b | Write Data: %h | Read Data: %h | Full: %b | Empty: %b | Valid: %b | Overflow: %b | Underflow: %b",
                $time, reset, wr_en, rd_en, w_data, r_data, full, empty, valid, overflow, underflow);
   end

   // Dump waveforms
   initial begin
      $dumpfile("async_fifo_tb.vcd");
      $dumpvars(0, async_fifo_tb);
   end

endmodule

