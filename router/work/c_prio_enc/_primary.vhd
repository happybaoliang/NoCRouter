library verilog;
use verilog.vl_types.all;
entity c_prio_enc is
    generic(
        num_ports       : integer := 8;
        offset          : integer := 0
    );
    port(
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of offset : constant is 1;
end c_prio_enc;
