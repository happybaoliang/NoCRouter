library verilog;
use verilog.vl_types.all;
entity c_scatter is
    generic(
        out_width       : integer := 32;
        mask            : vl_logic_vector
    );
    port(
        data_in         : in     vl_logic_vector;
        dest_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of out_width : constant is 1;
    attribute mti_svvh_generic_type of mask : constant is 4;
end c_scatter;
