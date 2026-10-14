`timescale 1ns/1ns

module contador_m_tb;
    localparam M = 6;

    reg clock = 1'b0;
    reg zera_as = 1'b0;
    reg zera_s = 1'b0;
    reg conta = 1'b0;
    wire [2:0] Q;
    wire fim;
    wire meio;

    integer ciclos;

    always #5 clock = ~clock;

    contador_m #(
        .M(M),
        .N(3)
    ) dut (
        .clock   (clock),
        .zera_as (zera_as),
        .zera_s  (zera_s),
        .conta   (conta),
        .Q       (Q),
        .fim     (fim),
        .meio    (meio)
    );

    task tick;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    task expect_count(input [2:0] expected, input [8*48-1:0] description);
        begin
            if (Q !== expected)
                $fatal(1, "%0s: expected Q=%0d, got Q=%0d",
                       description, expected, Q);
        end
    endtask

    initial begin
        zera_as = 1'b1;
        #1;
        expect_count(3'd0, "asynchronous clear");
        if (fim || meio)
            $fatal(1, "terminal and half flags must be low after clear");
        zera_as = 1'b0;

        // Counting disabled must hold the current count.
        repeat (2) tick;
        expect_count(3'd0, "hold while count disabled");

        conta = 1'b1;
        for (ciclos = 1; ciclos < M; ciclos = ciclos + 1) begin
            tick;
            expect_count(ciclos[2:0], "increment while enabled");
            if ((ciclos == M/2 - 1) !== meio)
                $fatal(1, "half-count flag incorrect at Q=%0d", Q);
            if ((ciclos == M - 1) !== fim)
                $fatal(1, "terminal flag incorrect at Q=%0d", Q);
        end

        // The terminal flag is asserted at M-1; rollover occurs next edge.
        tick;
        expect_count(3'd0, "rollover after terminal count");
        if (fim || meio)
            $fatal(1, "flags must clear after rollover");

        tick;
        expect_count(3'd1, "count after rollover");
        zera_s = 1'b1;
        tick;
        zera_s = 1'b0;
        expect_count(3'd0, "synchronous clear");

        tick;
        expect_count(3'd1, "restart after synchronous clear");
        zera_as = 1'b1;
        #1;
        expect_count(3'd0, "asynchronous clear while counting");
        zera_as = 1'b0;
        conta = 1'b0;
        tick;
        expect_count(3'd0, "hold after asynchronous clear");

        $display("PASS: contador_m enable, terminal/half flags, rollover, and clears");
        $finish;
    end

    initial begin
        #1_000;
        $fatal(1, "counter diagnostic test timed out");
    end
endmodule
