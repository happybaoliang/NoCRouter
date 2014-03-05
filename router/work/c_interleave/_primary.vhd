library verilog;
use verilog.vl_types.all;
entity c_interleave is
    generic(
        width           : integer := 8;
        num_blocks      : integer := 2
    );
    port(
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of num_blocks : constant is 1;
end c_interleave;
