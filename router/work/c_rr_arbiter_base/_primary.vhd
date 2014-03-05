library verilog;
use verilog.vl_types.all;
entity c_rr_arbiter_base is
    generic(
        num_ports       : integer := 32
    );
    port(
        mask            : in     vl_logic_vector;
        req             : in     vl_logic_vector;
        gnt             : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
end c_rr_arbiter_base;
