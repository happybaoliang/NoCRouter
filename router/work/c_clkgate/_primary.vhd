library verilog;
use verilog.vl_types.all;
entity c_clkgate is
    port(
        clk             : in     vl_logic;
        active          : in     vl_logic;
        clk_gated       : out    vl_logic
    );
end c_clkgate;
