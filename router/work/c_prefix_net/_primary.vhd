library verilog;
use verilog.vl_types.all;
entity c_prefix_net is
    generic(
        width           : integer := 16;
        enable_wraparound: integer := 0
    );
    port(
        g_in            : in     vl_logic_vector;
        p_in            : in     vl_logic_vector;
        g_out           : out    vl_logic_vector;
        p_out           : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of enable_wraparound : constant is 1;
end c_prefix_net;
