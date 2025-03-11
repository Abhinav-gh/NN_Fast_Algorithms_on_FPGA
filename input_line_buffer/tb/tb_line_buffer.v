`timescale 1ns / 1ps


// module line_buffer_tb_vivado;

//     // Parameters
//     parameter integer M = 3;
//     parameter integer W = 512;
//     parameter integer n = 4;

//     // Calculated parameters
//     parameter integer DATA_WIDTH = M*n*8;

//     // Signals
//     reg clk;
//     reg rst;
//     reg [7:0] data_in;
//     reg data_valid;
//     wire [DATA_WIDTH-1:0] data_out;
//     reg rd_data;

//     // Instantiate the Unit Under Test (UUT)
//     line_buffer #(
//         .M(M),
//         .W(W),
//         .n(n)
//     ) uut (
//         .i_clk(clk),
//         .i_rst(rst),
//         .i_data(data_in),
//         .i_data_valid(data_valid),
//         .o_data(data_out),
//         .i_rd_data(rd_data)
//     );
    
    
//     // Variables for testing
//     integer write_count;
//     integer read_count;
//     integer total_elements;
//     integer i, j;
//     integer num_reads_to_validate;
//     reg continue_reading;
    
//     // For output verification
//     reg [7:0] expected_data [M*W-1:0];
//     reg [DATA_WIDTH-1:0] expected_output;
    
//     // For memory viewing assistance
//     // THESE ARE MY MAGNIFYING GLASSES FOR 
//     // viewing specific memory locations of REALLY BIG MEMORY (line buffer)

//     reg [7:0] mem_channel_0___0;
//     reg [7:0] mem_channel_0___1;
//     reg [7:0] mem_channel_0___2;
//     reg [7:0] mem_channel_0___3;

//     reg [7:0] mem_channel_1___0;
//     reg [7:0] mem_channel_1___1;
//     reg [7:0] mem_channel_1___2;
//     reg [7:0] mem_channel_1___3;

//     reg [7:0] mem_channel_2___0;
//     reg [7:0] mem_channel_2___1;
//     reg [7:0] mem_channel_2___2;
//     reg [7:0] mem_channel_2___3;

//     // Clock generation
//     always #5 clk = ~clk; // 10ns period

//     // Update these signals for waveform viewing
//     always @(posedge clk) begin
//         mem_channel_0___0 <= uut.line[0];
//         mem_channel_0___1 <= uut.line[1];
//         mem_channel_0___2 <= uut.line[2];
//         mem_channel_0___3 <= uut.line[3];

//         mem_channel_1___0 <= uut.line[W + 0];
//         mem_channel_1___1 <= uut.line[W + 1];
//         mem_channel_1___2 <= uut.line[W + 2];
//         mem_channel_1___3 <= uut.line[W + 3];

//         mem_channel_2___0 <= uut.line[2*w + 0];
//         mem_channel_2___1 <= uut.line[2*w + 1];
//         mem_channel_2___2 <= uut.line[2*w + 2];
//         mem_channel_2___3 <= uut.line[2*w + 3];
//     end
    
//     initial begin
//         // Initialize signals
//         clk = 0;
//         rst = 1;
//         data_in = 0;
//         data_valid = 0;
//         rd_data = 0;
//         write_count = 0;
//         read_count = 0;
//         total_elements = M * W;
//         num_reads_to_validate = 10; // We'll validate 10 reads
//         continue_reading = 1;
        
//         // Reset for 30ns
//         #30;
//         rst = 0;
        
//         // Fill the line buffer
//         $display("Starting to fill the line buffer with %0d elements", total_elements);
        
//         // Pre-fill the expected data array
//         for (i = 0; i < total_elements; i = i + 1) begin
//             expected_data[i] = i % 256;
//         end
        
//         // Write data into the buffer
//         repeat (total_elements) begin
//             @(posedge clk);
//             data_valid = 1;
//             data_in = write_count % 256; // Values 0-255 repeating
//             write_count = write_count + 1;
//         end
        
//         @(posedge clk);
//         data_valid = 0;
//         $display("Finished filling the line buffer with %0d elements", write_count);
        
//         // Wait a few clock cycles
//         repeat(5) @(posedge clk);
        
//         // Read and validate data
//         $display("Starting to read and validate data");
        
//         // Without using 'break', we'll use a flag to limit validation
//         continue_reading = 1;
//         repeat (W) begin
//             if (continue_reading) begin
//                 // Assert read enable for one cycle
//                 @(posedge clk);
//                 rd_data = 1;
                
//                 // Calculate expected output
//                 expected_output = 0;
//                 for (i = 0; i < M; i = i + 1) begin
//                     for (j = 0; j < n; j = j + 1) begin
//                         expected_output[((M-1-i)*n*8 + (n-1-j)*8) +: 8] = expected_data[i*W + read_count + j];
//                     end
//                 end
                
//                 // Check output on next clock
//                 @(posedge clk);
//                 rd_data = 0;
                
//                 if (data_out !== expected_output) begin
//                     $display("ERROR at read_count=%0d: Expected %h, Got %h", read_count, expected_output, data_out);
//                 end else begin
//                     $display("Validation PASSED at read_count=%0d", read_count);
//                 end
                
//                 read_count = read_count + 1;
                
//                 // Only validate a few reads to keep output manageable
//                 if (read_count >= num_reads_to_validate) begin
//                     $display("Truncating validation after %0d reads", num_reads_to_validate);
//                     continue_reading = 0;
//                 end
//             end
//         end
        
//         #100;
//         $display("Testbench completed");
//         $finish;
//     end
    
//     // Monitor for debug
//     initial begin
//         $monitor("Time=%0t, Reset=%b, WrPtr=%0d, RdPtr=%0d, Data_Valid=%b, Rd_Data=%b", 
//                  $time, rst, uut.wrPntr, uut.rdPntr, data_valid, rd_data);
//     end

// endmodule



module line_buffer_tb_from_gemini;

  // Parameters from the module
    parameter integer M = 3 ;
    parameter integer W = 512 ;
    parameter integer n = 4 ;
    parameter integer M_W = M * W;
    parameter integer PNTR_WIDTH = (M_W <= 1) ? 1 :
                                    (M_W <= 2) ? 2 :
                                    (M_W <= 4) ? 3 :
                                    (M_W <= 8) ? 4 :
                                    (M_W <= 16) ? 5 :
                                    (M_W <= 32) ? 6 :
                                    (M_W <= 64) ? 7 :
                                    (M_W <= 128) ? 8 :
                                    (M_W <= 256) ? 9 :
                                    (M_W <= 512) ? 10 :
                                    (M_W <= 1024) ? 11 :
                                    (M_W <= 2048) ? 12 :
                                    (M_W <= 4096) ? 13 :
                                    (M_W <= 8192) ? 14 :
                                    (M_W <= 16384) ? 15 :
                                    (M_W <= 32768) ? 16 :
                                    (M_W <= 65536) ? 17 :
                                    (M_W <= 131072) ? 18 :
                                    (M_W <= 262144) ? 19 :
                                    (M_W <= 524288) ? 20 :
                                    (M_W <= 1048576) ? 21 :
                                    (M_W <= 2097152) ? 22 :
                                    (M_W <= 4194304) ? 23 :
                                    (M*W <= 8388608) ? 24 :
                                    (M*W <= 16777216) ? 25 :
                                    (M*W <= 33554432) ? 26 :
                                    (M*W <= 67108864) ? 27 :
                                    (M*W <= 134217728) ? 28 :
                                    (M*W <= 268435456) ? 29 :
                                    (M*W <= 536870912) ? 30 :
                                    (M*W <= 1073741824) ? 31 : 32;

    integer expected_index;
    integer expected_value;
    integer o_data_byte_end;
    integer o_data_byte_start;

    // Inputs to the module
    reg i_clk;
    reg i_rst;
    reg [7:0] i_data;
    reg i_data_valid;
    reg i_rd_data;

    // Outputs from the module
    wire [M*n*8-1:0] o_data;

    // Internal signals for monitoring
    reg [PNTR_WIDTH-1:0] wrPntr_tb;
    reg [PNTR_WIDTH-1:0] rdPntr_tb;
    reg [7:0] line_tb [M*W-2:0];

    // Instantiate the line_buffer module
    line_buffer #(
        .M(M),
        .W(W),
        .n(n),
        .PNTR_WIDTH(PNTR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_data),
        .i_data_valid(i_data_valid),
        .o_data(o_data),
        .i_rd_data(i_rd_data)
    );

    // Clock generation
    always #5 i_clk = ~i_clk;

    initial begin
        i_clk = 1'b0;
        i_rst = 1'b1;
        i_data_valid = 1'b0;
        i_rd_data = 1'b0;
        i_data = 8'b0;

        // Initialize internal signals for monitoring (optional, but good practice)
        wrPntr_tb = 12'b0;
        rdPntr_tb = 12'b0;
        for (integer k=0; k<M*W-1; k=k+1) begin
        line_tb[k] = 8'b0;
        end

        // Reset sequence
        #30; // Hold reset for 30ns
        i_rst = 1'b0;
        @(posedge i_clk); // wait for one clock cycle after reset

        // --- Filling the Line Buffer ---
        $display("--- Filling Line Buffer ---");
        for (integer index = 0; index < M*W; index = index + 1) begin
            i_data = index % 256;
            i_data_valid = 1'b1;

            @(posedge i_clk); i_data_valid = 1'b0;

        end
        $display("Line buffer filled in %0d clock cycles.", M*W);

        @(posedge i_clk); // Extra clock cycle to ensure last write is done.

        // --- Validation Read ---
        $display("--- Validating Output Data ---");
        i_rd_data = 1'b1;
        for (integer read_count = 0; read_count < 10; read_count = read_count + 1) begin
        @(posedge i_clk);
        $display("Read %0d: rdPntr=%0d, o_data=0x%h", read_count, dut.rdPntr, o_data);

        // Expected output calculation and verification (Example for first read only)
        if (read_count == 0) begin
            for (integer i = 0; i < M; i = i + 1) begin
            for (integer j = 0; j < n; j = j + 1) begin
                expected_index = i * W + dut.rdPntr + j;
                expected_value = expected_index % 256;
                o_data_byte_start = (M-1-i)*n*8 + (n-1-j)*8;
                o_data_byte_end   = o_data_byte_start + 7;
                if (o_data[o_data_byte_end:o_data_byte_start] !== expected_value) begin
                $error("Mismatch at read %0d, channel %0d, byte %0d. Expected 0x%h, Got 0x%h",
                        read_count, i, j, expected_value, o_data[o_data_byte_end:o_data_byte_start]);
                end else begin
                $display("Match at read %0d, channel %0d, byte %0d. Expected 0x%h, Got 0x%h",
                        read_count, i, j, expected_value, o_data[o_data_byte_end:o_data_byte_start]);
                end
            end
            end
        end
        end
        i_rd_data = 1'b0;

        $finish;
    end

    // Monitoring always block (optional, for waveform viewing help)
    always @(posedge i_clk) begin
        wrPntr_tb <= dut.wrPntr;
        rdPntr_tb <= dut.rdPntr;
        for (integer k=0; k<M*W-1; k=k+1) begin
        line_tb[k] <= dut.line[k];
        end
    end


endmodule