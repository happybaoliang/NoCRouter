library verilog;
use verilog.vl_types.all;
entity c_multi_hot_det is
    generic(
        width           : integer := 8
    );
    port(
        data            : in     vl_logic_vector;
        multi_hot       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
end c_multi_hot_det;
