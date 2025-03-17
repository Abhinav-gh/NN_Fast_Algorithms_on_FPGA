
//module PE_tb;

//    // Parameters
//    parameter KERNEL_SIZE = 3;
//    parameter INPUT_TILE_SIZE = 4;
//    parameter INPUT_DATA_WIDTH = 8;
//    parameter KERNEL_DATA_WIDTH = 8;
//    parameter CHANNELS = 3;
    
//    // Calculated parameters
//    parameter OUTPUT_TILE_SIZE = INPUT_TILE_SIZE - KERNEL_SIZE + 1;
//    parameter OUTPUT_DATA_WIDTH = KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 8;
    
//    // Input and output vectors size
//    parameter KERNEL_SIZE_BITS = KERNEL_SIZE * KERNEL_SIZE * KERNEL_DATA_WIDTH * CHANNELS;
//    parameter INPUT_SIZE_BITS = INPUT_TILE_SIZE * INPUT_TILE_SIZE * INPUT_DATA_WIDTH * CHANNELS;
//    parameter OUTPUT_SIZE_BITS = OUTPUT_TILE_SIZE * OUTPUT_TILE_SIZE * OUTPUT_DATA_WIDTH;
    
//    // Inputs
//    reg clk;
//    reg reset;
//    reg [KERNEL_SIZE_BITS-1:0] Kernel;
//    reg [INPUT_SIZE_BITS-1:0] inpData;
    
//    // Outputs
//    wire [OUTPUT_SIZE_BITS-1:0] outData;
    
//    // Instantiate the Unit Under Test (UUT)
//    PE #(
//        .KERNEL_SIZE(KERNEL_SIZE),
//        .INPUT_TILE_SIZE(INPUT_TILE_SIZE),
//        .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH),
//        .KERNEL_DATA_WIDTH(KERNEL_DATA_WIDTH),
//        .CHANNELS(CHANNELS)
//    ) uut (
//        .clk(clk),
//        .reset(reset),
//        .Kernel(Kernel),
//        .inpData(inpData),
//        .outData(outData)
//    );
    
//    // Clock generation
//    initial begin
//        clk = 0;
//        forever #5 clk = ~clk; // 100MHz clock
//    end
    
//    // Test data generation
//    reg [INPUT_DATA_WIDTH-1:0] input_data [0:INPUT_TILE_SIZE-1][0:INPUT_TILE_SIZE-1][0:CHANNELS-1];
//    reg [KERNEL_DATA_WIDTH-1:0] kernel_data [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1][0:CHANNELS-1];
    
//    // Expected output calculation
//    reg [OUTPUT_DATA_WIDTH-1:0] expected_output [0:OUTPUT_TILE_SIZE-1][0:OUTPUT_TILE_SIZE-1];
    
//    // Function to convert 3D array to flattened vector (for kernel)
//    task flatten_kernel;
//        integer i, j, k, idx;
//        begin
//            Kernel = 0;
//            for (k = 0; k < CHANNELS; k = k + 1) begin
//                for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
//                    for (j = 0; j < KERNEL_SIZE; j = j + 1) begin
//                        idx = ((KERNEL_SIZE * i + j) + (KERNEL_SIZE * KERNEL_SIZE * k)) * KERNEL_DATA_WIDTH;
//                        Kernel[idx +: KERNEL_DATA_WIDTH] = kernel_data[i][j][k];
//                    end
//                end
//            end
//        end
//    endtask
    
//    // Function to convert 3D array to flattened vector (for input)
//    task flatten_input;
//        integer i, j, k, idx;
//        begin
//            inpData = 0;
//            for (k = 0; k < CHANNELS; k = k + 1) begin
//                for (i = 0; i < INPUT_TILE_SIZE; i = i + 1) begin
//                    for (j = 0; j < INPUT_TILE_SIZE; j = j + 1) begin
//                        idx = ((INPUT_TILE_SIZE * i + j) + (INPUT_TILE_SIZE * INPUT_TILE_SIZE * k)) * INPUT_DATA_WIDTH;
//                        inpData[idx +: INPUT_DATA_WIDTH] = input_data[i][j][k];
//                    end
//                end
//            end
//        end
//    endtask
    
//    // Function to perform direct convolution for verification
//    task compute_expected_output;
//        integer i, j, ki, kj, c, sum;
//        begin
//            for (i = 0; i < OUTPUT_TILE_SIZE; i = i + 1) begin
//                for (j = 0; j < OUTPUT_TILE_SIZE; j = j + 1) begin
//                    sum = 0;
//                    for (ki = 0; ki < KERNEL_SIZE; ki = ki + 1) begin
//                        for (kj = 0; kj < KERNEL_SIZE; kj = kj + 1) begin
//                            for (c = 0; c < CHANNELS; c = c + 1) begin
//                                sum = sum + input_data[i+ki][j+kj][c] * kernel_data[ki][kj][c];
//                            end
//                        end
//                    end
//                    expected_output[i][j] = sum;
//                end
//            end
//        end
//    endtask
    
//    // Test procedure
//    initial begin
//        // Initialize Inputs
//        reset = 1;
//        Kernel = 0;
//        inpData = 0;
        
//        // Wait for global reset
//        #100;
//        reset = 0;
        
//        // Initialize test data
//        // Simple test case: kernel of all 1s, input data incrementing values
//        for (integer k = 0; k < CHANNELS; k = k + 1) begin
//            for (integer i = 0; i < KERNEL_SIZE; i = i + 1) begin
//                for (integer j = 0; j < KERNEL_SIZE; j = j + 1) begin
//                    kernel_data[i][j][k] = 1; // All 1s kernel
//                end
//            end
//        end
        
//        for (integer k = 0; k < CHANNELS; k = k + 1) begin
//            for (integer i = 0; i < INPUT_TILE_SIZE; i = i + 1) begin
//                for (integer j = 0; j < INPUT_TILE_SIZE; j = j + 1) begin
//                    input_data[i][j][k] = i + j + k + 1; // Incrementing values
//                end
//            end
//        end
        
//        // Flatten input and kernel data
//        flatten_kernel();
//        flatten_input();
        
//        // Calculate expected output
//        compute_expected_output();
        
//        // Apply inputs
//        @(posedge clk);
        
//        // Wait for processing to complete (10 clock cycles)
//        repeat(10) @(posedge clk);
        
//        // Verify outputs
//        for (integer i = 0; i < OUTPUT_TILE_SIZE; i = i + 1) begin
//            for (integer j = 0; j < OUTPUT_TILE_SIZE; j = j + 1) begin
//                integer idx = (OUTPUT_TILE_SIZE * i + j) * OUTPUT_DATA_WIDTH;
//                reg [OUTPUT_DATA_WIDTH-1:0] actual_out = outData[idx +: OUTPUT_DATA_WIDTH];
                
//                $display("Output[%0d][%0d]: Expected=%0d, Actual=%0d", 
//                         i, j, expected_output[i][j], actual_out);
                
//                if (expected_output[i][j] != actual_out) begin
//                    $display("ERROR: Output mismatch at [%0d][%0d]", i, j);
//                end
//            end
//        end
        
//        // Test with different data
//        // Random values for kernel and input
//        for (integer k = 0; k < CHANNELS; k = k + 1) begin
//            for (integer i = 0; i < KERNEL_SIZE; i = i + 1) begin
//                for (integer j = 0; j < KERNEL_SIZE; j = j + 1) begin
//                    kernel_data[i][j][k] = $random % (2**KERNEL_DATA_WIDTH);
//                end
//            end
//        end
        
//        for (integer k = 0; k < CHANNELS; k = k + 1) begin
//            for (integer i = 0; i < INPUT_TILE_SIZE; i = i + 1) begin
//                for (integer j = 0; j < INPUT_TILE_SIZE; j = j + 1) begin
//                    input_data[i][j][k] = $random % (2**INPUT_DATA_WIDTH);
//                end
//            end
//        end
        
//        // Flatten input and kernel data
//        flatten_kernel();
//        flatten_input();
        
//        // Calculate expected output
//        compute_expected_output();
        
//        // Apply inputs
//        @(posedge clk);
        
//        // Wait for processing to complete (10 clock cycles)
//        repeat(10) @(posedge clk);
        
//        // Verify outputs
//        for (integer i = 0; i < OUTPUT_TILE_SIZE; i = i + 1) begin
//            for (integer j = 0; j < OUTPUT_TILE_SIZE; j = j + 1) begin
//                integer idx = (OUTPUT_TILE_SIZE * i + j) * OUTPUT_DATA_WIDTH;
//                reg [OUTPUT_DATA_WIDTH-1:0] actual_out = outData[idx +: OUTPUT_DATA_WIDTH];
                
//                $display("Output[%0d][%0d]: Expected=%0d, Actual=%0d", 
//                         i, j, expected_output[i][j], actual_out);
                
//                if (expected_output[i][j] != actual_out) begin
//                    $display("ERROR: Output mismatch at [%0d][%0d]", i, j);
//                end
//            end
//        end
        
//        // End simulation
//        #100;
//        $finish;
//    end
    
//    // Monitor for debugging
//    initial begin
//        $monitor("Time=%0t, Reset=%b", $time, reset);
//    end

//endmodule