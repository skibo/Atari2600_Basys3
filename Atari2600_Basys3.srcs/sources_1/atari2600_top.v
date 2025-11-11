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

module atari2600_top(
                     output [3:0] vga_r,        // Video
                     output [3:0] vga_g,
                     output [3:0] vga_b,
                     output       vga_hsync,
                     output       vga_vsync,

                     input        start,
                     input        select,
                     input        expert_l,
                     input        expert_r,
                     input        selcolor,

                     input [3:0]  joy_l,        // R L D U
                     input        joy_l_trig,
                     input        padd_l_a,
                     input        padd_l_b,

                     input [3:0]  joy_r,
                     input        joy_r_trig,
                     input        padd_r_a,
                     input        padd_r_b,

                     input        clk,
                     input        reset
           );

   ///////////////////////////////////////////////////
   // CPU
   ///////////////////////////////////////////////////

    wire [15:0]         A;
    wire [7:0]          DO;
    wire [7:0]          DI;
    wire                RW;
    wire                RDY;
    wire                SYNC;

    wire                nmi;
    wire                NMI_ = !nmi;
    wire                irq;
    wire                IRQ_ = !irq;
    wire                RES_ = !reset;

    cpu6502 cpu(.A(A),
                .RW(RW),
                .DO(DO),
                .DI(DI),
                .RDY(RDY),
                .SYNC(SYNC),
                .IRQ_(IRQ_),
                .NMI_(NMI_),
                .PHI(clk),
                .RES_(RES_)
        );

    ///////////////////////////////////////////////////
    // Atari 2600 Hardware
    ///////////////////////////////////////////////////
    atari2600hw hw(.addr(A[12:0]),
                   .data_out(DI),
                   .data_in(DO),
                   .we(!RW),
                   .rdy(RDY),
                   .nmi(nmi),
                   .irq(irq),

                   .vga_r(vga_r),
                   .vga_g(vga_g),
                   .vga_b(vga_b),
                   .vga_hsync(vga_hsync),
                   .vga_vsync(vga_vsync),

                   .start(start),
                   .select(select),
                   .expert_l(expert_l),
                   .expert_r(expert_r),
                   .selcolor(selcolor),

                   .joy_l(joy_l),
                   .joy_l_trig(joy_l_trig),
                   .padd_l_a(padd_l_a),
                   .padd_l_b(padd_l_b),

                   .joy_r(joy_r),
                   .joy_r_trig(joy_r_trig),
                   .padd_r_a(padd_r_a),
                   .padd_r_b(padd_r_b),

                   .clk(clk),
                   .reset(reset)
         );

endmodule // atari2600_top
