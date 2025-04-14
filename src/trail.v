module array_filler(
    input clk,
    input rst,
    input [7:0] data_in,
    input data_valid
);

    reg [7:0] line_buffer[10:0];
    reg [3:0] write_pointer ;

    always @(posedge clk) begin
        if (rst) begin
            write_pointer  <= 0;
        end else if (data_valid) begin
            line_buffer[write_pointer ] <= data_in;
            write_pointer  <= write_pointer  + 1;
        end
    end

endmodule


module array_filler_tb;

    reg clk, rst;
    reg [7:0] data_in;
    reg data_valid;
    wire [3:0] write_pointer;

    array_filler UUT (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid)
    );

    // THIS IS THE TRICKY PART ; If we simulate this, we'll ONLY SEE don't cares
    // Since the current_write_pointer points to the next location that needs to be written.
    // And in next location CURRENTLY, the line buffer has don't cares.
    assign write_pointer = UUT.write_pointer;
    assign line_buffer_content_wrong = UUT.line_buffer[write_pointer];
    // assign line_buffer_content_wrong = UUT.line_buffer[write_pointer-1]; // THIS WORKS ABSOLUTELY FINE

    // => So in Verilog/Hardware, when we say read or write pointer, we mean the NEXT location to be written or read.
    // better namning would be next_write_pointer or next_read_pointer ----------------------- > REMEMBER !!

    // CORRECT WAY 
    wire [3:0] previous_index =  (write_pointer - 1);
    wire [7:0]line_buffer_content_correct = UUT.line_buffer[previous_index];


    initial begin
        clk = 1;
        rst = 1;
        data_in = 0;
        data_valid = 0;

        // Generate clock
        forever #5 clk = ~clk;
    end

    initial begin

        // Test sequence
        #30 rst = 0;                            // Deassert reset after 30ns
        #10 data_valid = 1; data_in = 10;       // Pass 10 with valid high
        #10 data_in = 20;                       // Pass 20 with valid high
        #10 data_valid = 0; data_in = 30;       // Pass 30 with valid low
        #10 data_in = 40;                        // Pass 40 with valid low
        #10 data_valid = 1; data_in = 50;       // Pass 50 with valid high
        #10 $finish;                            // End simulation
    end

endmodule


// It's alkways a BETTER to write NAMES like the below
module array_filler_BETTER(
    input clk,
    input rst,
    input [7:0] data_in,
    input data_valid
);

    reg [7:0] line_buffer[10:0];
    reg [3:0] next_location_to_write_po ;

    always @(posedge clk) begin
        if (rst) begin
            next_location_to_write_po  <= 0;
        end else if (data_valid) begin
            line_buffer[next_location_to_write_po ] <= data_in;
            next_location_to_write_po  <= next_location_to_write_po  + 1;
        end
    end

endmodule