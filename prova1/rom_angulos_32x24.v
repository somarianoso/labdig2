module rom_angulos_32x24 (
    input  wire [4:0]  endereco,
    output reg  [23:0] saida
);

    always @* begin
        case (endereco)
            5'd0:  saida = 24'h303230; // 020
            5'd1:  saida = 24'h303235; // 025
            5'd2:  saida = 24'h303239; // 029
            5'd3:  saida = 24'h303334; // 034
            5'd4:  saida = 24'h303338; // 038
            5'd5:  saida = 24'h303433; // 043
            5'd6:  saida = 24'h303437; // 047
            5'd7:  saida = 24'h303532; // 052
            5'd8:  saida = 24'h303536; // 056
            5'd9:  saida = 24'h303631; // 061
            5'd10: saida = 24'h303635; // 065
            5'd11: saida = 24'h303730; // 070
            5'd12: saida = 24'h303734; // 074
            5'd13: saida = 24'h303739; // 079
            5'd14: saida = 24'h303833; // 083
            5'd15: saida = 24'h303838; // 088
            5'd16: saida = 24'h303932; // 092
            5'd17: saida = 24'h303937; // 097
            5'd18: saida = 24'h313031; // 101
            5'd19: saida = 24'h313036; // 106
            5'd20: saida = 24'h313130; // 110
            5'd21: saida = 24'h313135; // 115
            5'd22: saida = 24'h313139; // 119
            5'd23: saida = 24'h313234; // 124
            5'd24: saida = 24'h313238; // 128
            5'd25: saida = 24'h313333; // 133
            5'd26: saida = 24'h313337; // 137
            5'd27: saida = 24'h313432; // 142
            5'd28: saida = 24'h313436; // 146
            5'd29: saida = 24'h313531; // 151
            5'd30: saida = 24'h313535; // 155
            5'd31: saida = 24'h313630; // 160
            default: saida = 24'h303230;
        endcase
    end

endmodule
