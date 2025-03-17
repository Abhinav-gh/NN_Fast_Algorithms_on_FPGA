/*
Description
How do I create a .vcd file in Vivado XSIM?
Solution
1.    Run the simulation.
2.    When the XSIM simulation window appears, enter these commands in the tcl console: */
// open_vcd
// log_vcd [get_object /<toplevel_testbench/uut/*>]
// run *ns
// close_vcd
    

`timescale 1ns / 1ps

module input_control_unit_tb();

    localparam CLK_PERIOD = 10;  // 10ns clock period
    localparam M = 3;            // Number of channels
    localparam W = 512;          // Width of each image
    localparam n = 4;            // Input tile size
    
    // Testbench signals
    reg clk;
    reg rst;
    reg [7:0] pixel_data;
    reg pixel_data_valid;
    reg proc_finish;
    wire [M*n*n*8-1:0] output_tile;
    wire ready;
    
    // Debug signals to view portions of the large output
    wire [7:0] output_sample_1;
    wire [7:0] output_sample_2;
    wire [7:0] output_sample_3;
    wire [7:0] output_sample_4;
    
    // Counters for test generation
    integer pixel_counter;
    integer state_count;
    integer ready_count;
    
    // For file I/O
    integer file;
    
    // Connect debug signals to view important parts of the output
    assign output_sample_1 = output_tile[7:0];                   // First byte of output
    assign output_sample_2 = output_tile[M*n*8-1:M*n*8-8];       // Last byte of first row
    assign output_sample_3 = output_tile[2*M*n*8-1:2*M*n*8-8];   // Last byte of second row
    assign output_sample_4 = output_tile[M*n*n*8-1:M*n*n*8-8];   // Last byte of output

    // Instantiate the unit under test (UUT)
    input_control_unit uut (
        .i_clk(clk),
        .i_rst(rst),
        .i_pixel_data(pixel_data),
        .i_pixel_data_valid(pixel_data_valid),
        .proc_finish(proc_finish),
        .o_input_tile_across_all_channel(output_tile),
        .o_ready(ready)
    );
    
    // Clock generation - starts with high edge
    initial begin
        clk = 1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Monitor outputs
    initial begin
        file = $fopen("output_results.txt", "w");
        if (file == 0) begin
            $display("Error: Could not open file");
            $finish;
        end
        
        $fwrite(file, "Time\tState\tPixel Counter\tReady\tOutput Samples\n");
        
        forever begin
            @(posedge clk);
            if (ready) begin
                ready_count = ready_count + 1;
                $fwrite(file, "%0t\t%0d\t%0d\t%0d\t%0d %0d %0d %0d\n", 
                        $time, uut.current_state, pixel_counter, ready,
                        output_sample_1, output_sample_2, output_sample_3, output_sample_4);
                
                // Also display to console for key checkpoints
                if (ready_count % 10 == 0 || ready_count < 5) begin
                    $display("Time=%0t, State=%0d, Ready=%0d, Output=[%0d,%0d,%0d,%0d]", 
                            $time, uut.current_state, ready,
                            output_sample_1, output_sample_2, output_sample_3, output_sample_4);
                    
                    // Dump additional debugging info for tile structure
                    $display("Tile Top Row (CH0): %h", output_tile[M*n*8-1:M*n*8-n*8]);
                    $display("Tile Top Row (CH1): %h", output_tile[2*M*n*8-1:2*M*n*8-n*8]);
                    $display("Tile Top Row (CH2): %h", output_tile[3*M*n*8-1:3*M*n*8-n*8]);
                end
            end
        end
    end
    
    // Test sequence
    initial begin
        // Initialize
        rst = 0;
        pixel_data = 0;
        pixel_data_valid = 0;
        proc_finish = 0;
        pixel_counter = 0;
        state_count = 0;
        ready_count = 0;
        
        // Apply reset for 30ns
        #1 rst = 1;
        #29 rst = 0;
        
        // Wait a few cycles after reset
        repeat(5) @(posedge clk);
        
        // Main test sequence - run until we've seen each state multiple times
        while (state_count < 10) begin  // Run through several state cycles
            @(posedge clk);
            
            // Generate pixel data - index modulo 256
            pixel_data = pixel_counter % 256;
            pixel_data_valid = 1;
            pixel_counter = pixel_counter + 1;
            
            // Track state transitions
            if (uut.next_state != uut.current_state && uut.next_state == 2'b01) begin
                state_count = state_count + 1;
                $display("Time=%0t: Transitioning to STATE1, state_count=%0d", $time, state_count);
            end
            
            // For longer simulations, print status periodically
            if (pixel_counter % 1000 == 0) begin
                $display("Time=%0t: Processed %0d pixels, current_state=%0d", 
                        $time, pixel_counter, uut.current_state);
            end
            
            // Occasional delays to test robustness
            if (pixel_counter % 500 == 499) begin
                pixel_data_valid = 0;
                repeat(3) @(posedge clk);
            end
        end
        
        // Process a bit more data after state transitions to see output stability
        repeat(W*M) @(posedge clk);
        
        // Finish the process
        proc_finish = 1;
        @(posedge clk);
        proc_finish = 0;
        
        // Run for a bit more after proc_finish
        repeat(100) @(posedge clk);
        
        // Close file and finish simulation
        $fclose(file);
        $display("Simulation complete after %0d cycles, %0d state transitions", pixel_counter, state_count);
        $finish;
    end
    
    // Additional debug monitors
    initial begin
        $monitor("Time=%0t: State=%0d, Fill=%0d, Read=%0d, ReadCycle=%0d", 
                $time, uut.current_state, uut.fill_counter, uut.read_counter, uut.read_cycle);
    end
    
    // Waveform dump for Vivado simulation
    initial begin
        $dumpfile("input_control_unit_tb.vcd");
        $dumpvars(0, input_control_unit_tb);
    end

endmodule