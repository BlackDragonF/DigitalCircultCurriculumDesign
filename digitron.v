module frequency_divider (input clock,
                          output reg new_clock);
reg [14:0] counter;

initial
begin
  counter = 0;
  new_clock = 0;
end

always @ (posedge clock)
begin
  counter <= counter + 1;
  if (counter == 16383)
  begin
    counter <= 0;
    new_clock <= ~new_clock;
  end
end
endmodule

module hello_printer (input switch,
                      input clock,
                      output reg [7:0] seq,
                      output reg [7:0] an);
parameter character_h = 8'b10010001,
          character_e = 8'b01100001,
          character_l = 8'b11100011,
          character_o = 8'b00000011;
parameter A0 = 8'b11111110,
          A1 = 8'b11111101,
          A2 = 8'b11111011,
          A3 = 8'b11110111,
          A4 = 8'b11101111;

reg [2:0] count;

initial
begin
    count = 0;
end

always @ (posedge clock)
begin
  if (switch)
  begin
    case (count)
    0: begin seq <= character_h; an <= A0; end
    1: begin seq <= character_e; an <= A1; end
    2: begin seq <= character_l; an <= A2; end
    3: begin seq <= character_l; an <= A3; end
    4: begin seq <= character_o; an <= A4; end
    default: begin seq <= character_h; an <= A0; end
    endcase
    if (count == 5) count <= 0; else count <= count + 1;
    //count <= count + 1;
    //if (count == 5) count <= 0;
  end
  else
  begin
    seq <= 8'b11111111;
    an <= 8'b11111111;
  end
end
endmodule

module fin_printer (input switch,
                   input clock,
                   output reg [7:0] seq,
                   output reg [7:0] an);
parameter character_f = 8'b01110001,
         character_i = 8'b11011111,
         character_n = 8'b11010101;
parameter A5 = 8'b11011111,
         A6 = 8'b10111111,
         A7 = 8'b01111111;

reg [2:0] count;

initial
begin
 count = 0;
end

always @ (posedge clock)
begin
if (switch)
 begin
   case (count)
   0: begin seq <= character_f; an <= A5; end
   1: begin seq <= character_i; an <= A6; end
   2: begin seq <= character_n; an <= A7; end
   default: begin seq <= character_f; an <= A5; end
   endcase
   if (count == 3) count <= 0; else count <= count + 1;
 end
 else
 begin
   seq <= 8'b11111111;
   an <= 8'b11111111;
 end
end
endmodule

module digit_printer (input switch,
                      input clock,
                      input [4:0] val,
                      output reg [7:0] seq,
                      output reg [7:0] an);
parameter digit_0 = 8'b00000011,
          digit_1 = 8'b10011111,
          digit_2 = 8'b00100101,
          digit_3 = 8'b00001101,
          digit_4 = 8'b10011001,
          digit_5 = 8'b01001001,
          digit_6 = 8'b01000001,
          digit_7 = 8'b00011111,
          digit_8 = 8'b00000001,
          digit_9 = 8'b00001001,
          non_digit = 8'b11111111;
parameter A5 = 8'b11011111,
           A6 = 8'b10111111,
           A7 = 8'b01111111;

reg [2:0] count;
reg half;
reg [3:0] low_bit;
reg [3:0] high_bit;
reg [7:0] small_digit;
reg [7:0] low_digit;
reg [7:0] high_digit;


initial
begin
  count = 0;
end

always @ (val)
begin
  low_bit = val[3:0] % 10;
  high_bit = val[3:0] / 10;
  half = val[4:4];
end

always @ (high_bit)
begin
  case (high_bit)
  0: high_digit = non_digit;
  1: high_digit = digit_1;
  2: high_digit = digit_2;
  3: high_digit = digit_3;
  4: high_digit = digit_4;
  5: high_digit = digit_5;
  6: high_digit = digit_6;
  7: high_digit = digit_7;
  8: high_digit = digit_8;
  9: high_digit = digit_9;
  default: high_digit = non_digit;
  endcase
end

always @ (low_bit)
begin
  case (low_bit)
  0: low_digit = digit_0;
  1: low_digit = digit_1;
  2: low_digit = digit_2;
  3: low_digit = digit_3;
  4: low_digit = digit_4;
  5: low_digit = digit_5;
  6: low_digit = digit_6;
  7: low_digit = digit_7;
  8: low_digit = digit_8;
  9: low_digit = digit_9;
  default: low_digit = non_digit;
  endcase
  low_digit = low_digit & 8'b11111110;
end
always @ (half)
begin
  case (half)
  0: small_digit <= digit_0;
  1: small_digit <= digit_5;
  endcase
end


always @ (posedge clock)
begin
  if (switch)
  begin
    case (count)
    0: begin seq <= high_digit; an <= A5; end
    1: begin seq <= low_digit; an <= A6; end
    2: begin seq <= small_digit; an <= A7; end
    default: begin seq <= high_digit; an <= A5; end
    endcase
    if (count == 3) count <= 0; else count <= count + 1;
  end
  else
  begin
    seq <= 8'b11111111;
    an <= 8'b11111111;
  end
end
endmodule

