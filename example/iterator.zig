const std = @import("std");
const RingBuffer = @import("ringbuffer").RingBuffer;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}) {};
    var ring = RingBuffer(u32).init(allocator.allocator());

    try ring.pushFront(3);
    try ring.pushFront(2);
    try ring.pushBack(5);
    try ring.pushBack(4);
    try ring.pushFront(1);
    try ring.pushBack(6);

    // Forward Iterator:
    var iter = ring.iter();
    std.debug.print("forward:", .{});
    while(iter.next()) |val| {
        std.debug.print(" {}", .{ val.* });
    }

    // Reverse Iterator:
    var iter_rev = ring.iterReverse();
    std.debug.print("\nbackward:", .{});
    while(iter_rev.next()) |val| {
        std.debug.print(" {}", .{ val.* });
    }
    std.debug.print("\n", .{});
}
 