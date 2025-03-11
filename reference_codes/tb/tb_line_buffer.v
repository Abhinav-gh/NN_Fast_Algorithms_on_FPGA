`timescale 1ns/1ps
`include "../lineBuffer.v"

module line_buffer_tb;

    // Inputs
    reg i_clk;
    reg i_rst;
    reg [7:0] i_data;
    reg i_data_valid;
    reg i_rd_data;

    // Outputs
    wire [23:0] o_data;

    // Instantiate the module under test
    line_buffer uut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_data),
        .i_data_valid(i_data_valid),
        .o_data(o_data),
        .i_rd_data(i_rd_data)
    );

    // Clock generation (10 ns period)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // Toggle every 5 ns for a 10 ns period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        i_rst = 1; // Reset is high for the first 20 ns
        i_data_valid = 0;
        i_data = 8'h00;
        i_rd_data = 0;

        // Wait for 20 ns (reset period)
        #20;

        // Release reset
        i_rst = 0;

        // Test sequence
        #10; // Wait 10 ns
        i_data_valid = 0; // i_data_valid low, i_data = 1F
        i_data = 8'h1F;

        #10; // Wait 10 ns
        i_data_valid = 1; // i_data_valid high, i_data = 2F
        i_data = 8'h2F;

        #10; // Wait 10 ns
        i_data_valid = 0; // i_data_valid low, i_data = 3F
        i_data = 8'h3F;

        #10; // Wait 10 ns
        i_data_valid = 1; // i_data_valid high, i_data = 4F
        i_data = 8'h4F;

        #10; // Wait 10 ns
        i_data_valid = 0; // i_data_valid low
        i_data = 8'h00;

        // Add more test cases if needed

        // End simulation
        #100; // Wait for some time to observe outputs
        $stop; // Stop simulation
    end

    // Monitor signals
    // initial begin
    //     $monitor("Time: %0t | i_rst: %b | i_data_valid: %b | i_data: %h | o_data: %h",
    //              $time, i_rst, i_data_valid, i_data, o_data);
    // end

endmodule