library verilog;
use verilog.vl_types.all;
entity c_rotate is
    generic(
        width           : integer := 8;
        rotate_dir      : integer := 0
    );
    port(
        amount          : in     vl_logic_vector;
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of rotate_dir : constant is 1;
end c_rotate;
