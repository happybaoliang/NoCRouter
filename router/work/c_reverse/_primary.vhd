library verilog;
use verilog.vl_types.all;
entity c_reverse is
    generic(
        width           : integer := 32
    );
    port(
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
end c_reverse;
