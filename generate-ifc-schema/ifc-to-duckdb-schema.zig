const std = @import("std");

const c = @cImport({
    @cInclude("duckdb/extensions.h");
    @cInclude("ifcopenshell_zig.h");
});

// need a zig wrapper... all duckdb_logical_type's must be destroyed
pub fn ifc_entity_to_duckdb_type(entity: *const c.IfcParse_entity) c.duckdb_logical_type {
    const attrs = entity.all_attributes();

    // TODO: stack allocate memory under a certain threshold?
    const attr_names = std.ArrayList(*[*:0]const u8).initCapacity(std.heap.c_allocator, attrs.len);
    defer attr_names.deinit(std.heap.c_allocator);

    const attr_types = std.ArrayList(c.duckdb_logical_type).initCapacity(std.heap.c_allocator, attrs.len);
    defer attr_types.deinit(std.heap.c_allocator);

    for (attrs.items, 0..) |attr, i| {
        attr_names.getptr(i).* = attr.name;
        attr_types.getptr(i).* = switch (attr.type) {
            c.IFC_TYPE_BOOLEAN => c.DUCKDB_TYPE_BOOLEAN,
            else => c.DUCKDB_TYPE_BOOLEAN,
        };
    }

    return c.duckdb_create_struct_type(
        attr_types,
        attr_names,
        attrs.items.len,
    );
}
