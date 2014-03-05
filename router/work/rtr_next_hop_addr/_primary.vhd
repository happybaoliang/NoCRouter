library verilog;
use verilog.vl_types.all;
entity rtr_next_hop_addr is
    generic(
        num_resource_classes: integer := 2;
        num_routers_per_dim: integer := 4;
        num_dimensions  : integer := 2;
        num_nodes_per_router: integer := 1;
        connectivity    : integer := 0;
        routing_type    : integer := 0
    );
    port(
        router_address  : in     vl_logic_vector;
        dest_info       : in     vl_logic_vector;
        lar_info        : in     vl_logic_vector;
        next_router_address: out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_resource_classes : constant is 1;
    attribute mti_svvh_generic_type of num_routers_per_dim : constant is 1;
    attribute mti_svvh_generic_type of num_dimensions : constant is 1;
    attribute mti_svvh_generic_type of num_nodes_per_router : constant is 1;
    attribute mti_svvh_generic_type of connectivity : constant is 1;
    attribute mti_svvh_generic_type of routing_type : constant is 1;
end rtr_next_hop_addr;
