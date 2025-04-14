`timescale 1ns / 1ps


module input_control_unit_tb;
    // Parameters
    parameter integer M = 3;        // Number of channels
    parameter integer W = 512;      // Width of each Image
    parameter integer n = 4;        // Input Tile size
    
    // Testbench signals
    reg                    i_clk;
    reg                    i_rst;
    reg [7:0]       i_pixel_data;
    reg                    i_pixel_data_valid;
    reg                    proc_finish;
    wire [3*4*4*8-1:0]     o_input_tile_across_all_channel;
    wire                   o_ready;
    
    // Counters
    integer pixel_counter;
    integer fill_count;
    integer read_cycles;
    integer i, j;
    
    // Index for monitoring line buffer contents
    reg [10:0] monitor_index;
    
    input_control_unit #(
        .M(M),
        .W(W),
        .n(n)
    ) UUT (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_pixel_data(i_pixel_data),
        .i_pixel_data_valid(i_pixel_data_valid),
        .proc_finish(proc_finish),
        .o_input_tile_across_all_channel(o_input_tile_across_all_channel),
        .o_ready(o_ready)
    );
    
    // Access line buffer memory cells via hierarchical paths
    // These will update dynamically based on monitor_index
    // Use hierarchical paths with variable indices
    wire [7:0] lb1_cell = UUT.LB1.line[monitor_index-1];
    wire [7:0] lb2_cell = UUT.LB2.line[monitor_index-1];
    wire [7:0] lb3_cell = UUT.LB3.line[monitor_index-1];
    wire [7:0] lb4_cell = UUT.LB4.line[monitor_index-1];
    wire [7:0] lb5_cell = UUT.LB5.line[monitor_index-1];
    wire [7:0] lb6_cell = UUT.LB6.line[monitor_index-1];
    
    // Access to write pointers for monitoring
    wire [10:0] lb1_wr_ptr = UUT.LB1.wrPntr;
    wire [10:0] lb2_wr_ptr = UUT.LB2.wrPntr;
    wire [10:0] lb3_wr_ptr = UUT.LB3.wrPntr;
    wire [10:0] lb4_wr_ptr = UUT.LB4.wrPntr;
    wire [10:0] lb5_wr_ptr = UUT.LB5.wrPntr;
    wire [10:0] lb6_wr_ptr = UUT.LB6.wrPntr;
    
    wire [19:0]fill_counter_UUT = UUT.fill_counter;
    wire [19:0]read_counter_UUT = UUT.read_counter;

    wire [7:0]pixel_to_lb1 = UUT.pixel_to_lb1;
    wire [7:0]pixel_to_lb2 = UUT.pixel_to_lb2;
    wire [7:0]pixel_to_lb3 = UUT.pixel_to_lb3;
    wire [7:0]pixel_to_lb4 = UUT.pixel_to_lb4;
    wire [7:0]pixel_to_lb5 = UUT.pixel_to_lb5;
    wire [7:0]pixel_to_lb6 = UUT.pixel_to_lb6;

    wire valid_to_lb1 = UUT.valid_to_lb1;
    wire valid_to_lb2 = UUT.valid_to_lb2;
    wire valid_to_lb3 = UUT.valid_to_lb3;
    wire valid_to_lb4 = UUT.valid_to_lb4;
    wire valid_to_lb5 = UUT.valid_to_lb5;
    wire valid_to_lb6 = UUT.valid_to_lb6;
    
    // State monitoring
    wire [1:0] current_state = UUT.current_state;
    reg  [1:0] prev_state;
    
    // Output data verification
    reg [3*4*4*8-1:0] expected_output;
    reg [7:0] output_data[0:3*4*4-1];
    
    // Clock generation - starts with high, period of 10ns
    initial begin
        i_clk = 1;
        forever #5 i_clk = ~i_clk;  // Toggle every 5ns -> 10ns period
    end
    
    // Initialize all signals
    initial begin
        i_rst = 1;
        i_pixel_data = 0;
        i_pixel_data_valid = 0;
        proc_finish = 0;
        pixel_counter = 0;
        fill_count = 0;
        read_cycles = 0;
        monitor_index=0;
        prev_state = 0;
        
        // Initialize expected output
        expected_output = 0;
        for (i = 0; i < 3*4*4; i = i + 1) begin
            output_data[i] = 0;
        end
        
        // Apply reset for 30ns, and make it low
        #30;
        i_rst = 0;
        
        // Start testing
        $display("Starting test sequence at %0t", $time);
        
        // Begin data feeding
        i_pixel_data_valid = 1;
    end
    
    // Generate pixel data based on counter, mod 256
    always @(posedge i_clk) begin
        if (i_pixel_data_valid) begin
            i_pixel_data <= (pixel_counter % 256);
            pixel_counter <= pixel_counter + 1;
        end
    end
    
    // Monitor state transitions ( THIS NEVER WENT OFF )
    always @(posedge i_clk) begin
        prev_state <= current_state;
        
        // Display state transition
        if (prev_state != current_state) begin
            case (current_state)
                0: $display("Transitioned to INIT_STATE at %0t", $time);
                1: $display("Transitioned to STATE1 at %0t", $time);
                2: $display("Transitioned to STATE2 at %0t", $time);
                3: $display("Transitioned to STATE3 at %0t", $time);
                default: $display("Unknown state at %0t", $time);
            endcase
        end
    end
    
    // Update monitor_index to track line buffer filling
    // Cycle through different indices to monitor different parts of the line buffers
    always @(posedge i_clk) begin
        if (i_rst) begin
            monitor_index <= 0;
        end
        else if (i_pixel_data_valid) begin
            // (M*W-1) is the maximum index for the line buffer ; 
            if (monitor_index >= M*W-1)
                monitor_index <= 0;
            else
                monitor_index <= monitor_index + 1;
                
            // Display line buffer contents periodically
            if (monitor_index % 100 == 0) begin
                $display("Time: %0t, Monitor Index: %0d", $time, monitor_index);
                $display("LB1[%0d]: %0d, WrPtr: %0d", monitor_index, lb1_cell, lb1_wr_ptr);
                $display("LB2[%0d]: %0d, WrPtr: %0d", monitor_index, lb2_cell, lb2_wr_ptr);
                $display("LB3[%0d]: %0d, WrPtr: %0d", monitor_index, lb3_cell, lb3_wr_ptr);
                $display("LB4[%0d]: %0d, WrPtr: %0d", monitor_index, lb4_cell, lb4_wr_ptr);
                $display("LB5[%0d]: %0d, WrPtr: %0d", monitor_index, lb5_cell, lb5_wr_ptr);
                $display("LB6[%0d]: %0d, WrPtr: %0d", monitor_index, lb6_cell, lb6_wr_ptr);
            end
        end
    end
    
    // Capture and verify outputs when ready signal is asserted
    always @(posedge i_clk) begin
        if (o_ready) begin
            read_cycles <= read_cycles + 1;
            
            // Display output data
            $display("Output Ready at cycle %0d, State: %0d, Time: %0t", read_cycles, current_state, $time);
            
            // Extract and display a portion of the output data
            for (i = 0; i < 3; i = i + 1) begin // For each channel
                $display("Channel %0d output:", i);
                for (j = 0; j < 4; j = j + 1) begin // Show 4x4 tile
                    // $write("%3d %3d %3d %3d | ", 
                    //         o_input_tile_across_all_channel[(i*4*4*8) + (j*4*8) + 7 : (i*4*4*8) + (j*4*8)],
                    //         o_input_tile_across_all_channel[(i*4*4*8) + (j*4*8) + 15 : (i*4*4*8) + (j*4*8) + 8],
                    //         o_input_tile_across_all_channel[(i*4*4*8) + (j*4*8) + 23 : (i*4*4*8) + (j*4*8) + 16],
                    //         o_input_tile_across_all_channel[(i*4*4*8) + (j*4*8) + 31 : (i*4*4*8) + (j*4*8) + 24]);
                    $write("\n");
                end
            end
        end
    end
    
    // Keep track of fill count for debugging
    always @(posedge i_clk) begin
        if (i_rst)
            fill_count <= 0;
        else if (i_pixel_data_valid)
            fill_count <= fill_count + 1;
    end
    
    // Monitor write pointers of all line buffers
    always @(posedge i_clk) begin
        if (fill_count % 1000 == 0 && fill_count > 0) begin
            $display("Fill count: %0d at %0t", fill_count, $time);
            $display("Write Pointers - LB1: %0d, LB2: %0d, LB3: %0d, LB4: %0d, LB5: %0d, LB6: %0d", lb1_wr_ptr, lb2_wr_ptr, lb3_wr_ptr, lb4_wr_ptr, lb5_wr_ptr, lb6_wr_ptr);
        end
    end
    
    // Test duration control
    initial begin
        // Run for enough cycles to observe all states
        // Testbench for ININT, STATE1, STATE2, STATE3
        // #(M*W*4 + 3*M*W*2 + 3*M*W*2  + 3*M*W*2 ) 
        
        // $display("Testbench completed at %0t", $time);
        // $display("Total read cycles: %0d", read_cycles);
        
        // $finish;
    end

endmodule
