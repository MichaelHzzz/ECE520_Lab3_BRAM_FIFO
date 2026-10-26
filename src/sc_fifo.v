`timescale 1ns / 1ps

module sc_fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 32,
    parameter ALMOST_EMPTY_THRESHOLD = 1,
    parameter ALMOST_FULL_THRESHOLD = 31,
    parameter READ_LATENCY = 1,
    parameter ADDR_WIDTH = 5,
    parameter COUNT_WIDTH = 6
)(
    input  wire                   clk,
    input  wire                   srst,
    input  wire [WIDTH-1:0]       data_in,
    input  wire                   write_enable,
    input  wire                   read_enable,
    output reg  [WIDTH-1:0]       data_out,
    output reg                    valid,
    output wire                   full,
    output wire                   empty,
    output wire                   almost_full,
    output wire                   almost_empty,
    output reg  [COUNT_WIDTH-1:0] data_count
);

    (* ram_style = "block" *) reg [WIDTH-1:0] memory [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] write_pointer;
    reg [ADDR_WIDTH-1:0] read_pointer;

    reg [WIDTH-1:0] data_pipe [0:READ_LATENCY-1];
    reg valid_pipe [0:READ_LATENCY-1];

    wire write_success;
    wire read_success;

    integer i;

    assign full = (data_count == DEPTH);
    assign empty = (data_count == 0);
    assign almost_full = (data_count >= ALMOST_FULL_THRESHOLD);
    assign almost_empty = (data_count <= ALMOST_EMPTY_THRESHOLD);

    assign write_success = write_enable && !full;
    assign read_success = read_enable && !empty;

    always @(posedge clk) begin
        if (srst) begin
            write_pointer <= 0;
            read_pointer <= 0;
            data_count <= 0;
            data_out <= 0;
            valid <= 0;

            for (i = 0; i < READ_LATENCY; i = i + 1) begin
                data_pipe[i] <= 0;
                valid_pipe[i] <= 0;
            end
        end
        else begin
            if (write_success) begin
                memory[write_pointer] <= data_in;
                write_pointer <= write_pointer + 1;
            end

            if (read_success) begin
                data_pipe[0] <= memory[read_pointer];
                valid_pipe[0] <= 1'b1;
                read_pointer <= read_pointer + 1;
            end
            else begin
                data_pipe[0] <= 0;
                valid_pipe[0] <= 1'b0;
            end

            for (i = 1; i < READ_LATENCY; i = i + 1) begin
                data_pipe[i] <= data_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end

            data_out <= data_pipe[READ_LATENCY-1];
            valid <= valid_pipe[READ_LATENCY-1];

            if (write_success && !read_success) begin
                data_count <= data_count + 1;
            end
            else if (!write_success && read_success) begin
                data_count <= data_count - 1;
            end
        end
    end

endmodule