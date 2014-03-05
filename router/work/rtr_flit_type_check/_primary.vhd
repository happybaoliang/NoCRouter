library verilog;
use verilog.vl_types.all;
entity rtr_flit_type_check is
    generic(
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        flit_valid      : in     vl_logic;
        flit_head       : in     vl_logic;
        flit_tail       : in     vl_logic;
        error           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_flit_type_check;
