module UMBRELLA (input logic [1:0] KEY, //control inputs (clock,reset)
						input logic [5:0] SW, //switch inputs
						output logic [3:0] LEDG, 
						output logic [2:0] LEDR, 
						output logic [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

	logic [7:0]LOC_STATE; //8bit location fsm state variable
	logic [2:0]ELEVATOR_STATE; //3 bit elevator fsm state variable
	logic [2:0]WEAPON_STATE; //3 bit weapon fsm state variable


	LOCATION_FSM mod1(KEY[1], KEY[0], LEDG[3], LEDG[2], SW[4], SW[5], SW[3], SW[1], SW[2],	SW[0], LEDR[2], LEDR[1], LEDR[0], LEDG[1], LEDG[0], LOC_STATE[7:0]);
	
	ELEVATOR_FSM mod2(KEY[1], KEY[0], LEDG[0], LEDG[1],SW[5], SW[4], LEDG[2],LEDG[3], ELEVATOR_STATE[2:0]);


	WEAPONS_FSM mod3(KEY[1], KEY[0], LEDR[0], LEDR[1], LEDR[2],WEAPON_STATE[2:0]);

//decoders to display fsm states on 7-segment displays



	LOC_DECODE mod4(LOC_STATE[7:0], HEX0[6:0], HEX1[6:0], HEX2[6:0], HEX3[6:0]);

	ELEVATOR_DECODE mod5(ELEVATOR_STATE[2:0], HEX4[6:0], HEX5[6:0]);

	WEAPON_DECODE mod6(WEAPON_STATE[2:0], HEX6[6:0],HEX7[6:0]);

endmodule

module LOCATION_FSM (input logic clk,
							input logic reset, 
							input logic FN1, FN0, 
							input logic DOWN, UP, 
							input logic NORTH, SOUTH, EAST, WEST, 
							input logic V, 
							output logic W2, W1, 
							output logic E2, E1, 
							output logic [7:0]LOC_STATE);
							
//define state encoding for locations							

typedef enum logic [7:0]{EA=8'b0000_0001, L=8'b0000_0010, EB=8'b0000_0100, ST=8'b0000_1000, WBS=8'b0001_0000, EC=8'b0010_0000,UAW=8'b0100_0000, UAL=8'b1000_0000} statetype;
(*fsm_encoding = "one_hot"*) statetype state, nextstate;

//sequential logic for state transition on clock or reset 

always_ff@ (posedge clk or posedge ~reset) 
begin 
if (~reset)
 state <= EA;
else
 state <= nextstate;
end

//combinational logic to determine next state based on current state and inputs

always_comb
case(state)

EA: 
begin 

	if(NORTH)  nextstate=L;
	 else if (UP & FN0 & ~FN1)  nextstate = EB;
	 else   nextstate = EA;
	 end 
	 
L:
begin 
 if(SOUTH) nextstate=EA;
	else      nextstate=L;
	end 
	
EB:
begin 
 if(~FN0 & DOWN & FN1)  nextstate = EA;
	 else if (UP & FN1 & ~FN0) nextstate = EC; 
	 else if (NORTH) nextstate = ST;
	 else if (WEST) nextstate = WBS;
	 else  nextstate = EB; 
	 end 
	 
ST:
begin 
 if (SOUTH)  nextstate = EB;
	 else        nextstate = ST;
	 end 
	 
WBS:
begin 
 if(EAST)  nextstate = EB;
	  else  		 nextstate = WBS;
	  
	 end 
	  
EC:
begin 
 if(~V & FN1 & FN0) nextstate = UAL; 
	 else if (V & FN1 & FN0) nextstate = UAW;
	 else	 nextstate = EC;
	 end 
	 
UAW: nextstate = UAW; 

UAL: nextstate = UAL; 

default: nextstate = EA;
endcase

//assign output LEDs based on current state

assign E1 = (state == EA);
assign W2 = (state == L);
assign E2 = (state == EB);
assign W1 = (state == WBS);
assign LOC_STATE = state;
endmodule 

module ELEVATOR_FSM (input logic clk, 
							input logic reset, 
							input logic E1, E2, 
							input logic UP, DOWN,
							output logic FN0, FN1,
							output logic [2:0]ELEVATOR_STATE);
							
//define state encoding for elevator states							

typedef enum logic [2:0]{FA = 3'b001, FB=3'b010, FC=3'b100} statetype;
(*fsm_encoding = "one_hot"*) statetype state, nextstate;

//state and next state variables with one hot encoding

always_ff @ (posedge clk, posedge ~reset)
		if (~reset) state <= FA; 
		else state <= nextstate;
		
always_comb
case(state) 


FA:
begin 
 if(E1 & UP) nextstate=FB; 
	 else   nextstate = FA;
	 end
	 
FB:
begin 
 if (E2 & DOWN) nextstate = FA; 
	 else if (E2 & UP) nextstate = FC;
	 else  nextstate = FB; 
	 end 

FC: nextstate = FC; 

default: nextstate = FA;

endcase 

//output assignments based on current state

assign FN1 = (state == FB) | (state == FC);

assign FN0 = (state == FA) | (state == FC);
assign ELEVATOR_STATE = (state);

endmodule 

module WEAPONS_FSM (input logic clk, 
						  input logic reset, 
						  input logic W1, W2, 
						  output logic V,
						  output logic [2:0] WEAPON_STATE);

	//define state encoding for weapon states					  
						  
typedef enum logic [2:0]{NW=3'b001, OW=3'b010, BW=3'b100} statetype; 
(*fsm_encoding = "one_hot"*) statetype state, nextstate;

//state and next state variables with one hot encoding 

always_ff @ (posedge clk, posedge ~reset)
if (~reset) state <= NW; 
else state <= nextstate;

always_comb
case(state)


NW:
begin 
 if (W1)  nextstate = OW;
	 else   nextstate = NW;
	 end
	 
OW:
begin 
 if (W2)  nextstate = BW;
	 else   nextstate = OW; 
	 end
	 
BW: nextstate = BW;

default: nextstate= NW;
endcase 

//assign outputs based on current state


assign V = (state == BW);
assign WEAPON_STATE = (state);

endmodule 

//decoder for LOC_STATE, outputs on 7 segment display
 
module LOC_DECODE(input logic [7:0]LOC_STATE,
						 output logic [6:0]HEX0, HEX1, HEX2, HEX3);
						 
//define logic for displaying LOC_STATE on displays						 
	always_comb
		begin

			case(LOC_STATE) //define cases to display binary state values on display
 

				//EA 
				8'b0000_0001:
					begin
						HEX3 = 7'b111_1111;
						HEX2 = 7'b111_1111;
						HEX1 = 7'b000_0110;
						HEX0 = 7'b000_1000;
					end
					
//L 
8'b0000_0010:
begin
					HEX3 = 7'b100_0111;
					HEX2 = 7'b000_0011; 
					HEX1 = 7'b000_0011;
					HEX0 = 7'b001_1001;
end 		
			
//EB 
8'b0000_0100:
begin
					HEX3 = 7'b111_1111;
					HEX2 = 7'b111_1111;
					HEX1 = 7'b000_0110;
					HEX0 = 7'b000_0011;
end 
	
//ST 
8'b0000_1000: 
begin
					HEX3 = 7'b001_0010;
					HEX2 = 7'b000_0110;
					HEX1 = 7'b010_0111;
					HEX0 = 7'b000_1111;
end 

//WBS 

8'b0001_0000:
begin 
					HEX3 = 7'b011_0000;
					HEX2 = 7'b000_1111;
					HEX1 = 7'b000_0011;
					HEX0 = 7'b001_0010;
end 

//EC 
8'b0010_0000:
begin
					HEX3 = 7'b111_1111;
					HEX2 = 7'b111_1111;
					HEX1 = 7'b000_0110;
					HEX0 = 7'b100_0110;
end 

//UAW 
8'b0100_0000:
begin 
					HEX3 = 7'b111_1111;
					HEX2 = 7'b011_0000;
					HEX1 = 7'b111_1001;
					HEX0 = 7'b010_1011;
end 

//UAL
8'b1000_0000:
					begin 
						HEX3 = 7'b100_0111;
						HEX2 = 7'b100_0000;
						HEX1 = 7'b001_0010;
						HEX0 = 7'b000_0110;
					end 	
	
	
				default:
					begin
					   HEX3 = 7'b111_1111;
						HEX2 = 7'b111_1111;
						HEX1 = 7'b000_0110;
						HEX0 = 7'b000_1000;
					
					end
endcase 
end
 
endmodule


//decoder for ELEVATOR_STATE, outputs on display

module ELEVATOR_DECODE (input logic [2:0]ELEVATOR_STATE, 
							   output logic [6:0]HEX4, HEX5);
								

always_comb 

case(ELEVATOR_STATE) //define cases to display binary state values

//FA
3'b001: 
begin 
				HEX5 = 7'b000_1110;
				HEX4 = 7'b000_1000;
end 

//FB 
3'b010:
begin 
				HEX5 = 7'b000_1110;
				HEX4 = 7'b000_0000;
				
end 

//FC 
3'b100:
begin 
				HEX5 = 7'b000_1110;
				HEX4 = 7'b100_0110;
end 
				
				default: 
				begin 
				HEX5 = 7'b000_1110;
				HEX4 = 7'b000_1000;
				end 
				
			
endcase 

endmodule

//decoder for WEAPON_STATE, outputs state on display
							
module WEAPON_DECODE (input logic [2:0]WEAPON_STATE,
								output logic [6:0]HEX6, HEX7);
							
							
							
						
always_comb

case(WEAPON_STATE) //define cases to display binary state values on displaye

//NW
3'b001:
begin
HEX7 = 7'b100_0000;
HEX6 = 7'b111_1001;
end

3'b010:
begin 
HEX7 = 7'b100_0000;
HEX6 = 7'b010_0100;
end 

3'b100:
begin 
HEX7 = 7'b000_0011;
HEX6 = 7'b010_0011;
end 



				default: 
				begin 
				HEX7 = 7'b100_0000;
            HEX6 = 7'b111_1001;
				end
endcase		
				

endmodule