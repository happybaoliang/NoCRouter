library verilog;
use verilog.vl_types.all;
entity c_incr is
    generic(
        width           : integer := 3;
        min_value       : vl_logic_vector;
        max_value       : vl_logic_vector
    );
    port(
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of min_value : constant is 4;
    attribute mti_svvh_generic_type of max_value : constant is 4;
end c_incr;
