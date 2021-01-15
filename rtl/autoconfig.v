`timescale 1ns / 1ps
/*
    Copyright (C) 2018, Stephen J. Leary
    All rights reserved.
    
    This file is part of  TF530 (Terrible Fire 030 Accelerator).

    TF530 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TF530 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TF530. If not, see <http://www.gnu.org/licenses/>.
*/


module autoconfig(

           input    RESET,
           input 	AS20,
           input 	RW20,
           input 	DS20,

           input [31:0] A,

           output [7:4] DOUT,

           output  ACCESS,
           output  DECODE

       );

reg config_out = 'd0;
reg configured = 'd0;
reg shutup = 'd0;
reg [7:4] data_out = 'd0;

// 0xE80000
wire Z2_ACCESS = ({A[31:16]} != {16'h00E8}) | (&config_out);
wire Z2_WRITE = (Z2_ACCESS | RW20);
wire [5:0] zaddr = {A[6:1]};

always @(posedge AS20 or negedge RESET) begin

    if (RESET == 1'b0) begin

        config_out <= 'd0;

    end else begin

        config_out <= configured | shutup;

    end

end

always @(negedge DS20 or negedge RESET) begin

    if (RESET == 1'b0) begin

        configured <= 'd0;
        shutup <= 'd0;
        data_out[7:4] <= 4'hf;

    end else begin

            if (Z2_WRITE == 1'b0) begin

                    case (zaddr)
                    'h22: begin //configure logic
                        configured <= 1'b1;
                    end
                    'h26: begin // shutup logic
                        shutup <= 1'b1;
                    end
                endcase

            end

            // autoconfig ROMs
            case (zaddr)
                'h00: data_out[7:4] <= 4'ha;
                'h01: data_out[7:4] <= 4'h3; // Go0se - 128MB extended Z3 config size
                'h03: data_out[7:4] <= 4'hc;
                'h04: data_out[7:4] <= 4'h4;
                'h08: data_out[7:4] <= 4'he;
                'h09: data_out[7:4] <= 4'hc;
                'h0a: data_out[7:4] <= 4'h2;
                'h0b: data_out[7:4] <= 4'h7;
                'h11: data_out[7:4] <= 4'he;
                'h12: data_out[7:4] <= 4'hb;
                'h13: data_out[7:4] <= 4'h5;
                default: data_out[7:4] <= 4'hf;
            endcase
            
    end
end

// decode the base addresses
// these are hardcoded to the address they always get assigned to.
assign DECODE = ({A[31:27]} != {5'b0100_0}) | shutup;  // Go0se - not passed back to 330 main_top

assign ACCESS = Z2_ACCESS;
assign DOUT = data_out;

endmodule
