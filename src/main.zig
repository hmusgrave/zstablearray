const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn ArrayList(comptime T: type) type {
    return struct {
        small_slab: []T,
        big_slab: []T,
        allocator: Allocator,
        size: usize,
        ever_toggled: bool,

        pub fn init(allocator: Allocator) !@This() {
            var big_slab = try allocator.alloc(T, 2);
            errdefer allocator.free(big_slab);

            var small_slab = try allocator.alloc(T, 1);
            errdefer allocator.free(small_slab);

            return .{
                .small_slab = small_slab,
                .big_slab = big_slab,
                .allocator = allocator,
                .size = 0,
                .ever_toggled = false,
            };
        }

        pub fn deinit(self: *const @This()) void {
            defer self.allocator.free(self.big_slab);
            defer self.allocator.free(self.small_slab);
        }

        pub inline fn at(self: *const @This(), i: usize) *T {
            if (i < self.small_slab.len and self.ever_toggled)
                return &self.small_slab[i];
            return &self.big_slab[i];
        }

        pub fn append(self: *@This(), x: T) !void {
            defer self.size += 1;
            if (self.size == self.big_slab.len) {
                defer self.ever_toggled = true;
                self.allocator.free(self.small_slab);
                self.small_slab = self.big_slab;
                self.big_slab = try self.allocator.alloc(T, self.small_slab.len * 2);
                self.big_slab[0] = self.small_slab[0];
                self.big_slab[self.size] = x;
            } else {
                self.big_slab[self.size] = x;
                if (self.ever_toggled) {
                    const i = self.size - self.small_slab.len;
                    self.big_slab[i] = self.small_slab[i];
                }
            }
        }
    };
}

test {
    const allocator = std.testing.allocator;
    const A = ArrayList(f32);

    var arr = try A.init(allocator);
    defer arr.deinit();

    var data = [_]f32{ 2, 4, 5, 314, 2178, 217, -2, 0, 23, 9 };
    for (data, 0..) |x, i| {
        try arr.append(x);
        for (0..i + 1) |j|
            try std.testing.expectEqual(data[j], arr.at(j).*);
    }
}
