module SR_latch_gate (
    input S,
    input R,
    output wire Q,
    output wire Qbar
);

    nor (Q, R, Qbar);
    nor (Qbar, S, Q);
endmodule
