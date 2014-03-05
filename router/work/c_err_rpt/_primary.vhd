library verilog;
use verilog.vl_types.all;
entity c_err_rpt is
    generic(
        num_errors      : integer := 1;
        capture_mode    : integer := 1;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        errors_in       : in     vl_logic_vector;
        errors_out      : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_errors : constant is 1;
    attribute mti_svvh_generic_type of capture_mode : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end c_err_rpt;
