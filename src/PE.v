`timescale 1ns / 1ps

module PE #(
        parameter KERNEL_SIZE       = 3,
                INPUT_TILE_SIZE   = 4,
                INPUT_DATA_WIDTH  = 8,
                KERNEL_DATA_WIDTH = 8,
                CHANNELS          = 3
)(
    // Global Signals
    input clk,
    input reset,
    
    // Kernel Loading
    input [(KERNEL_SIZE * KERNEL_SIZE * KERNEL_DATA_WIDTH * CHANNELS) - 1 : 0] Kernel,
    
    // Output Loading
    input [(INPUT_TILE_SIZE * INPUT_TILE_SIZE * INPUT_DATA_WIDTH * CHANNELS) - 1 : 0] inpData,
    output reg[(INPUT_TILE_SIZE - KERNEL_SIZE) * (INPUT_TILE_SIZE - KERNEL_SIZE) * (KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 8) - 1 : 0] outData
    );
    
    // Defining the registers
    // This register will hold all the Kernel Values in correct format
    reg [KERNEL_DATA_WIDTH - 1 : 0] kernel_reg [KERNEL_SIZE - 1 : 0] [KERNEL_SIZE - 1 : 0] [CHANNELS - 1 : 0];       
    // This register will hold all the Input Values in correct format
    reg [INPUT_DATA_WIDTH - 1 : 0] input_reg [INPUT_TILE_SIZE - 1 : 0] [INPUT_TILE_SIZE - 1 : 0] [CHANNELS - 1 : 0]; 
    


    // These two registers are used for transforming the input
    // (Bd g) = D
    reg [INPUT_DATA_WIDTH : 0] input_temp_reg [INPUT_TILE_SIZE - 1 : 0] [INPUT_TILE_SIZE - 1 : 0] [CHANNELS - 1 : 0]; 
    // (D Bd') = Transformed Input
    reg [INPUT_DATA_WIDTH + 1 : 0] input_transformed_reg [INPUT_TILE_SIZE - 1 : 0] [INPUT_TILE_SIZE - 1 : 0] [CHANNELS - 1 : 0]; 
    
    // These two registers are used for transforming the Kernel
    reg [KERNEL_DATA_WIDTH : 0] kernel_temp_reg [INPUT_TILE_SIZE - 1 : 0] [KERNEL_SIZE - 1 : 0] [CHANNELS - 1 : 0];
    reg [KERNEL_DATA_WIDTH + 1 : 0] kernel_transformed_reg [INPUT_TILE_SIZE - 1 : 0] [INPUT_TILE_SIZE - 1 : 0] [CHANNELS - 1 : 0];
        
    reg [KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 2 : 0] ewmm_reg [INPUT_TILE_SIZE - 1 : 0] [INPUT_TILE_SIZE - 1 : 0] [CHANNELS - 1 : 0]; // Element-Wise Matrix Multiplication
    
    // These two registers are used for transforming the output
    reg [KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 4 : 0] output_reg1 [INPUT_TILE_SIZE - KERNEL_SIZE : 0] [INPUT_TILE_SIZE - 1 : 0] [CHANNELS - 1 : 0];
    reg [KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 6 : 0] output_reg2 [INPUT_TILE_SIZE - KERNEL_SIZE : 0] [INPUT_TILE_SIZE - KERNEL_SIZE : 0] [CHANNELS - 1 : 0];
    
    // This register stores the final output after the accumulation step
    reg [KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 8 : 0] output_final_reg [INPUT_TILE_SIZE - KERNEL_SIZE : 0] [INPUT_TILE_SIZE - KERNEL_SIZE : 0];
    
    
    
    integer i, j, k; // Defined as loop variables
    
    // This block loads the Kernel input data from a flattened 1D vector into a Kernel of proper size (K x K x M)
    always @(posedge clk)
    begin
        for (i = KERNEL_SIZE - 1 ; i >= 0 ; i = i - 1)
        begin
            for (j = KERNEL_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
                begin
                    kernel_reg[i][j][k] <= Kernel[((KERNEL_SIZE * i + j) + (KERNEL_SIZE * KERNEL_SIZE * k)) * KERNEL_DATA_WIDTH +: KERNEL_DATA_WIDTH];
                end
            end
        end
    end
    
    // This block loads the input data from a flattened 1D vector into a Image Matrix of proper size (N x N x M)
    always @(posedge clk)
    begin
        for (i = INPUT_TILE_SIZE - 1 ; i >= 0 ; i = i - 1)
        begin
            for (j = INPUT_TILE_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
                begin
                    input_reg[i][j][k] <= inpData[((INPUT_TILE_SIZE * i + j) + (INPUT_TILE_SIZE * INPUT_TILE_SIZE * k)) * INPUT_DATA_WIDTH +: INPUT_DATA_WIDTH];
                end
            end
        end
    end
    
    // The Winograd transformation of the input (Bd g Bd') has been broken down into two parts.
    // This block is used to perform the first part : (Bd g). The block has been written assuming 4x4 tile and 3x3 Kernel
    always @(posedge clk)
    begin
        for(k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (j = INPUT_TILE_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                input_temp_reg[INPUT_TILE_SIZE - 1][j][k] <= input_reg[3][j][k] - input_reg[1][j][k];
                input_temp_reg[INPUT_TILE_SIZE - 2][j][k] <= input_reg[2][j][k] + input_reg[1][j][k];
                input_temp_reg[INPUT_TILE_SIZE - 3][j][k] <= - input_reg[2][j][k] + input_reg[1][j][k];
                input_temp_reg[INPUT_TILE_SIZE - 4][j][k] <= input_reg[2][j][k] - input_reg[0][j][k];
            end
        end
    end
    
    // This block is responsible for the second part (D Bd') of the input transformation
    // The Kernel transformtaion and the output transformation also follow similar logic
    always @(posedge clk)
    begin
        for(k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (j = INPUT_TILE_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                input_transformed_reg[j][INPUT_TILE_SIZE - 1][k] <= input_temp_reg[j][3][k] - input_temp_reg[j][1][k];
                input_transformed_reg[j][INPUT_TILE_SIZE - 2][k] <= input_temp_reg[j][2][k] + input_temp_reg[j][1][k];
                input_transformed_reg[j][INPUT_TILE_SIZE - 3][k] <= - input_temp_reg[j][2][k] + input_temp_reg[j][1][k];
                input_transformed_reg[j][INPUT_TILE_SIZE - 4][k] <= input_temp_reg[j][2][k] - input_temp_reg[j][0][k];
            end
        end
    end
    
    // Kernel Transformation
    always @(posedge clk)
    begin
        for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (j = KERNEL_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                kernel_temp_reg[INPUT_TILE_SIZE - 1][j][k] <= kernel_reg[2][j][k];
                kernel_temp_reg[INPUT_TILE_SIZE - 2][j][k] <= (kernel_reg[2][j][k] +  kernel_reg[1][j][k] +  kernel_reg[0][j][k]) >>> 1;
                kernel_temp_reg[INPUT_TILE_SIZE - 3][j][k] <= (kernel_reg[2][j][k] -  kernel_reg[1][j][k] +  kernel_reg[0][j][k]) >>> 1;
                kernel_temp_reg[INPUT_TILE_SIZE - 4][j][k] <= kernel_reg[0][j][k];
            end
        end
    end
    
    always @(posedge clk)
    begin
        for(k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (j = INPUT_TILE_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                kernel_transformed_reg[j][INPUT_TILE_SIZE - 1][k] <= kernel_temp_reg[j][2][k];
                kernel_transformed_reg[j][INPUT_TILE_SIZE - 2][k] <= (kernel_temp_reg[j][2][k] + kernel_temp_reg[j][1][k] + kernel_temp_reg[j][1][k]) >>> 1;
                kernel_transformed_reg[j][INPUT_TILE_SIZE - 3][k] <= (kernel_temp_reg[j][2][k] - kernel_temp_reg[j][1][k] + kernel_temp_reg[j][1][k]) >>> 1;
                kernel_transformed_reg[j][INPUT_TILE_SIZE - 4][k] <= kernel_temp_reg[j][0][k];
            end
        end
    end
    
    // Element-Wise Matrix Multiplication
    always @(posedge clk)
    begin
        for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (i = INPUT_TILE_SIZE - 1 ; i >= 0 ; i = i - 1)
            begin
                for (j = INPUT_TILE_SIZE - 1 ; j >= 0 ; j = j - 1)
                begin
                    ewmm_reg[i][j][k] <= input_transformed_reg[i][j][k] + kernel_transformed_reg[i][j][k];
                end
            end
        end
    end
    
    // Output Transformation
    always @(posedge clk)
    begin
        for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (j = INPUT_TILE_SIZE - 1 ; j >= 0 ; j = j - 1)
            begin
                output_reg1[INPUT_TILE_SIZE - KERNEL_SIZE][j][k] <= ewmm_reg[3][j][k] + ewmm_reg[2][j][k] + ewmm_reg[1][j][k];
                output_reg1[INPUT_TILE_SIZE - KERNEL_SIZE - 1][j][k] <= ewmm_reg[2][j][k] - ewmm_reg[1][j][k] - ewmm_reg[0][j][k];
            end
        end
    end
    
    always @(posedge clk)
    begin
        for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
        begin
            for (j = INPUT_TILE_SIZE - KERNEL_SIZE ; j >= 0 ; j = j - 1)
            begin
                output_reg2[j][INPUT_TILE_SIZE - KERNEL_SIZE][k] <= output_reg1[j][3][k] + output_reg1[j][2][k] + output_reg1[j][1][k];
                output_reg2[j][INPUT_TILE_SIZE - KERNEL_SIZE - 1][k] <= output_reg1[j][2][k] - output_reg1[j][1][k] - output_reg1[j][0][k];
            end
        end
    end
    
    // This block is performing the accumulation step where in multiple channel outputs are added together into one single channel
    always @(posedge clk)
    begin
        for (i = INPUT_TILE_SIZE - KERNEL_SIZE ; i >= 0 ; i = i - 1)
        begin
            for (j = INPUT_TILE_SIZE - KERNEL_SIZE ; j >= 0 ; j = j - 1)
            begin
                for (k = CHANNELS - 1 ; k >= 0 ; k = k - 1)
                begin
                    output_final_reg[i][j]  <= output_final_reg[i][j] + output_reg2[i][j][k];
                end
            end
        end
    end
    
    // This block is used to convert the (R x R) output tile into a flattened 1D vector for output
    always @(posedge clk)
    begin
        for (i = INPUT_TILE_SIZE - KERNEL_SIZE ; i >= 0 ; i = i - 1)
        begin
            for (j = INPUT_TILE_SIZE - KERNEL_SIZE ; j >= 0 ; j = j - 1)
            begin
                outData[((INPUT_TILE_SIZE - KERNEL_SIZE + 1) * i + j) * (KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 8) +: (KERNEL_DATA_WIDTH + INPUT_DATA_WIDTH + 8)] <= output_final_reg[i][j];
            end
        end
    end
    
    
endmodule