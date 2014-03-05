library verilog;
use verilog.vl_types.all;
entity c_align is
    generic(
        in_width        : integer := 32;
        out_width       : integer := 32;
        offset          : integer := 0
    );
    port(
        data_in         : in     vl_logic_vector;
        dest_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of in_width : constant is 1;
    attribute mti_svvh_generic_type of out_width : constant is 1;
    attribute mti_svvh_generic_type of offset : constant is 1;
end c_align;
