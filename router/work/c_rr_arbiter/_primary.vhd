library verilog;
use verilog.vl_types.all;
entity c_rr_arbiter is
    generic(
        num_ports       : integer := 32;
        num_priorities  : integer := 1;
        encode_state    : integer := 1;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        req_pr          : in     vl_logic_vector;
        gnt_pr          : out    vl_logic_vector;
        gnt             : out    vl_logic_vector;
        update          : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of num_priorities : constant is 1;
    attribute mti_svvh_generic_type of encode_state : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end c_rr_arbiter;
