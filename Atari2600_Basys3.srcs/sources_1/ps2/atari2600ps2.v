`timescale 1ns / 1ps
//
// Copyright (c) 2025 Thomas Skibo.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//

// Take PS2 input and produce joystick controls

//	Joystick Left:
//		UP, DOWN, LEFT, RIGHT Arrows.
//		Space -> Left Trigger
//	Joystick Right:
//		T - Up, G - Down, F - Left, H - Right
//		A -> Right Trigger
//	Enter -> Start switch
//	Tab -> Select switch
//

module atari2600ps2(
                    output reg [3:0] joy_l,
                    output reg       joy_l_trig,
                    output reg [3:0] joy_r,
                    output reg       joy_r_trig,

                    output reg       start,
                    output reg       select,

                    input            ps2_clk,
                    input            ps2_data,

                    input            clk,
                    input            reset
               );

    //////////////////////// PS2 serial interface //////////////////////
    //
    wire [7:0]  ps2_code;
    wire        ps2_wr;

    ps2_intf
        ps2if(.ps2_code(ps2_code),
              .ps2_wr(ps2_wr),

              .ps2_clk(ps2_clk),
              .ps2_data(ps2_data),

              .reset(reset),
              .clk(clk)
              );

    //////////////////////// PS2 decode ////////////////////////////////
    //
    reg         key_release;    // set by an 0xF0 code.  key is being released.
    reg         key_extended;   // set by an 0xE0 code.  key is extended.
    reg         key_shift;      // shift key is down

    localparam [7:0]
        PS2_RELEASE =   8'hf0,
        PS2_EXTENDED =  8'he0,
        PS2_SHIFT1 =    8'h59,
        PS2_SHIFT2 =    8'h12,
        PS2_ALT =       8'h11,
        PS2_CTRL =      8'h14,
        PS2_X_UP =      8'h75,
        PS2_X_DOWN =    8'h72,
        PS2_X_LEFT =    8'h6b,
        PS2_X_RIGHT =   8'h74,
        PS2_SPACE =     8'h29,
        PS2_ENTER =     8'h5a,
        PS2_TAB =       8'h0d,
        PS2_H =         8'h33,
        PS2_T =         8'h2c,
        PS2_F =         8'h2b,
        PS2_G =         8'h34,
        PS2_A =         8'h1c;

    always @(posedge clk)
        if (reset) begin
            key_release <= 0;
            key_shift <= 0;
            key_extended <= 0;
            joy_l <= 4'hf;
            joy_l_trig <= 1;
            joy_r <= 4'hf;
            joy_r_trig <= 1;
            start <= 1;
            select <= 1;
        end
        else if (ps2_wr) begin
            case (ps2_code)
                PS2_RELEASE:
                    key_release <= 1;
                PS2_SHIFT1, PS2_SHIFT2:
                    key_shift <= ! key_release;
                PS2_EXTENDED:
                    key_extended <= 1;
                PS2_X_UP:
                    joy_l[0] <= key_release;
                PS2_X_DOWN:
                    joy_l[1] <= key_release;
                PS2_X_LEFT:
                    joy_l[2] <= key_release;
                PS2_X_RIGHT:
                    joy_l[3] <= key_release;
                PS2_SPACE:
                    joy_l_trig <= key_release;
                PS2_T:
                    joy_r[0] <= key_release;
                PS2_G:
                    joy_r[1] <= key_release;
                PS2_F:
                    joy_r[2] <= key_release;
                PS2_H:
                    joy_r[3] <= key_release;
                PS2_A:
                    joy_r_trig <= key_release;
                PS2_ENTER:
                    start <= key_release;
                PS2_TAB:
                    select <= key_release;
            endcase
            if (ps2_code != PS2_RELEASE)
                key_release <= 0;
            if (ps2_code != PS2_EXTENDED && ps2_code != PS2_RELEASE)
                key_extended <= 0;
        end

endmodule // atari2600ps2
