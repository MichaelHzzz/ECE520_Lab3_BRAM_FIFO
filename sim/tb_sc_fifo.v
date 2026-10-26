`timescale 1ns / 1ps

module tb_sc_fifo;

    reg clk = 0;
    reg srst = 1;
    reg write_enable = 0;
    reg read_enable = 0;
    reg [15:0] data_in = 0;

    wire [15:0] data_out;
    wire valid;
    wire full;
    wire empty;
    wire almost_full;
    wire almost_empty;
    wire [5:0] data_count;

    reg [15:0] test_data [0:35];

    integer i;
    integer errors = 0;

    sc_fifo DUT (
        .clk(clk),
        .srst(srst),
        .data_in(data_in),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .data_out(data_out),
        .valid(valid),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .data_count(data_count)
    );

    always #10 clk = ~clk;

    // Write one word.
    task write_fifo;
        input [15:0] value;
        begin
            @(negedge clk);
            data_in = value;
            write_enable = 1;

            @(negedge clk);
            write_enable = 0;
        end
    endtask

    // Read one word and check it.
    task read_fifo;
        input [15:0] expected;
        begin
            @(negedge clk);
            read_enable = 1;

            @(negedge clk);
            read_enable = 0;

            @(posedge clk);
            #1;

            if (valid !== 1'b1 || data_out !== expected) begin
                $display("ERROR: expected %h, got %h, valid=%b",
                         expected, data_out, valid);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("Starting FIFO simulation");

        $readmemh("input_data.txt", test_data);

        // Stop if the input file did not load correctly.
        for (i = 0; i < 36; i = i + 1) begin
            if ((^test_data[i]) === 1'bx) begin
                $display("TEST FAILED: invalid input data at entry %0d", i);
                $finish;
            end
        end

        // Test 1: Reset.
        $display("TEST 1: Reset");

        repeat (3) @(negedge clk);
        srst = 0;

        if (data_count !== 0 || empty !== 1'b1 ||
            full !== 1'b0 || valid !== 1'b0 ||
            data_out !== 16'h0000 ||
            almost_empty !== 1'b1 || almost_full !== 1'b0) begin
            $display("ERROR: reset failed");
            errors = errors + 1;
        end

        // Test 2: Data patterns and FIFO order.
        $display("TEST 2: Data patterns and ordering");

        write_fifo(16'hFFFF);
        write_fifo(16'h0000);
        write_fifo(16'hAAAA);
        write_fifo(16'h5555);

        read_fifo(16'hFFFF);
        read_fifo(16'h0000);
        read_fifo(16'hAAAA);
        read_fifo(16'h5555);

        // Test 3: Fill all 32 locations.
        $display("TEST 3: Full and almost-full flags");

        for (i = 0; i < 32; i = i + 1)
            write_fifo(i);

        if (full !== 1'b1 || almost_full !== 1'b1 ||
            data_count !== 32) begin
            $display("ERROR: full flags or count failed");
            errors = errors + 1;
        end

        // Test 4: Reject an extra write when full.
        $display("TEST 4: Write while full");

        write_fifo(16'hDEAD);

        if (data_count !== 32) begin
            $display("ERROR: full write changed count");
            errors = errors + 1;
        end

        // Reading the original values also checks that
        // the rejected write did not overwrite them.
        for (i = 0; i < 32; i = i + 1)
            read_fifo(i);

        if (empty !== 1'b1 || almost_empty !== 1'b1 ||
            data_count !== 0) begin
            $display("ERROR: empty flags or count failed");
            errors = errors + 1;
        end

        // Test 5: Reject a read when empty.
        $display("TEST 5: Read while empty");

        @(negedge clk);
        read_enable = 1;

        @(negedge clk);
        read_enable = 0;

        @(posedge clk);
        #1;

        if (valid !== 1'b0 || data_count !== 0 ||
            empty !== 1'b1) begin
            $display("ERROR: empty read was not rejected");
            errors = errors + 1;
        end

        // Test 6: Read and write on the same clock edge.
        $display("TEST 6: Simultaneous read and write");

        write_fifo(16'h1111);

        @(negedge clk);
        data_in = 16'h2222;
        write_enable = 1;
        read_enable = 1;

        @(negedge clk);
        write_enable = 0;
        read_enable = 0;

        @(posedge clk);
        #1;

        if (data_count !== 1 || valid !== 1'b1 ||
            data_out !== 16'h1111) begin
            $display("ERROR: simultaneous read/write failed");
            errors = errors + 1;
        end

        read_fifo(16'h2222);

        // Test 7: Python-generated data.
        // These operations also wrap the pointers around.
        $display("TEST 7: Python data and pointer wraparound");

        for (i = 0; i < 36; i = i + 1) begin
            write_fifo(test_data[i]);
            read_fifo(test_data[i]);
        end

        if (empty !== 1'b1 || data_count !== 0) begin
            $display("ERROR: final FIFO count failed");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule