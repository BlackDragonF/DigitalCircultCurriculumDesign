module top_module (input clock,
                   input reset,
                   input op_start,
                   input goods_mark,
                   input val_mark,
                   input coin_confirm,
                   input cancel_flag,
                   output reset_led,
                   output hold_led,
                   output coin_led,
                   output drinktk_led,
                   output charge_led,
                   output reg [7:0] seq,
                   output reg [7:0] an);
// Instantiation of other modules
wire [3:0] coin_val;
wire [3:0] goods_val;
wire [3:0] goods_val_now;
wire hold_ind;
wire coin_ind;
wire drinktk_ind;
wire charge_ind;
wire [3:0] charge_val;
wire new_clock;
wire [7:0] seq1;
wire [7:0] seq2;
wire [7:0] seq3;
wire [7:0] seq4;
wire [7:0] seq5;
wire [7:0] an1;
wire [7:0] an2;
wire [7:0] an3;
wire [7:0] an4;
wire [7:0] an5;
wire drinktk_signal;
wire charge_signal;

frequency_divider devider(clock, new_clock);
main_controller controller(reset, clock, op_start, coin_val, goods_val, cancel_flag, drinktk_signal, charge_signal, hold_ind, coin_ind, drinktk_ind, charge_ind, goods_val_now, charge_val);
coin_inserter inserter(hold_ind, coin_confirm, val_mark, coin_val);
goods_picker picker(goods_mark, goods_val);
hello_printer hello((~hold_ind & reset), new_clock, seq1, an1);
digit_printer goods((hold_ind & (~coin_ind) & (~charge_ind) & (~drinktk_ind)), new_clock, goods_val_now, seq2, an2);
digit_printer coin(coin_ind, new_clock, coin_val, seq3, an3);
digit_printer charge(charge_ind, new_clock, charge_val, seq4, an4);
fin_printer fin(drinktk_ind, new_clock, seq5, an5);
delay_timer drinktk_timer(drinktk_ind, clock, drinktk_signal);
delay_timer charge_timer(charge_ind, clock, charge_signal);

assign reset_led = reset;
assign hold_led = hold_ind;
assign coin_led = coin_ind;
assign drinktk_led = drinktk_ind;
assign charge_led = charge_ind;

always @ (*)
begin
  seq = ~((~seq1) | (~seq2) | (~seq3) | (~seq4) | (~seq5));
  an = ~((~an1) | (~an2) | (~an3) | (~an4) | (~an5));
end
endmodule

module coin_inserter (input reset,
                    input coin_confirm,
                    input val_mark,
                    output reg [3:0] coin_val);
// Inserting coins and valuing
initial
begin
  coin_val = 0;
end

always @ (negedge reset or posedge coin_confirm)
begin
  if (!reset) coin_val <= 0;
  else
  begin
    if (val_mark == 0)
        coin_val <= coin_val + 1;
    else
        coin_val <= coin_val + 10;
  end
end
endmodule

module goods_picker (input goods_mark,
                  output reg [3:0] goods_val);
// Picking up certain goods and valuing
always @ (goods_mark)
begin
  if (goods_mark == 0)
    goods_val = 2;
  else
    goods_val = 5;
end
endmodule

module main_controller (input reset,
                input clock,
                input op_start,
                input [3:0] coin_val,
                input [3:0] goods_val,
                input cancel_flag,
                input drinktk_signal,
                input charge_signal,
                output reg hold_ind,
                output reg coin_ind,
                output reg drinktk_ind,
                output reg charge_ind,
                output reg [3:0] goods_val_now,
                output reg [3:0] charge_val);
// Maintaining a state machine
reg [4:0] current_state, next_state;
reg [31:0] count;
wire delay_signal;



initial
begin
    goods_val_now = 0;
    count = 0;
end
parameter S0 = 5'b00000,
          S1 = 5'b10000,
          S2 = 5'b01000,
          S3 = 5'b00100,
          S4 = 5'b00010,
          S5 = 5'b00001;

always @ (posedge clock or negedge reset)
begin
  if (!reset)
    current_state <= S0;
  else
    current_state <= next_state;
end

always @ (*)
begin
  next_state = S0;
  case (current_state)                                                                                                                                                                                                     
    S0: begin
      if (reset == 1)
        next_state = S1;
    end
    S1: begin
      if (op_start == 1)
      begin
        next_state = S2;
        goods_val_now = goods_val;
      end
      else
        next_state = S1;
    end
    S2: begin
      if (coin_val != 4'b0000)
        next_state = S3;
      else if (cancel_flag == 1)
        next_state = S5;
      else
        next_state = S2;
    end
    S3: begin
      if (cancel_flag == 1)
        next_state = S5;
      else if (coin_val >= goods_val_now)
        next_state = S4;
      else
        next_state = S3;
    end
    S4: begin
      if (drinktk_signal)
        begin
        if (coin_val - goods_val_now == 4'b0000)
          next_state = S1;
        else
          next_state = S5;
        end
      else
        next_state = S4;
    end
    S5: begin
      if (charge_signal)
        next_state = S1;
      else
        next_state = S5;
    end
    default:  begin
      next_state = S0;
    end
  endcase
end

always @ (posedge clock or negedge reset)
begin
  if (!reset) begin
    hold_ind <= 0;
    coin_ind <= 0;
    drinktk_ind <= 0;
    charge_ind <= 0;
    charge_val <= 0;
  end
  else begin
    case (next_state)
      S2: begin hold_ind <= 1; end
      S3: coin_ind <= 1;
      S4: begin drinktk_ind <= 1; coin_ind <= 0; end
      S5: begin drinktk_ind <= 0; coin_ind <= 0; charge_ind <= 1; charge_val <= (coin_val > goods_val_now)?(coin_val - goods_val_now):(coin_val); end
      default:  begin
        hold_ind <= 0;
        coin_ind <= 0;
        drinktk_ind <= 0;
        charge_ind <= 0;
        charge_val <= 0;
      end
    endcase
  end
end
endmodule

module delay_timer (input start,
		            input clock,
		            output reg signal);

reg [31:0] count;
reg wake;

initial
begin
  signal = 0;
end

always @ (start)
begin
  if (start == 1)
    wake = 1;
  else
    wake = 0;
end

always @ (posedge clock)
begin
  if (wake == 1)
  begin
    signal <= 0;
    count <= count + 1;
  end
  if (count >= 400000000)
  begin
    signal <= 1;
    count <= 0;
  end
end
endmodule
