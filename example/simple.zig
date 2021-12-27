const std = @import("std");
const RingBuffer = @import("ringbuffer").RingBuffer;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}) {};
    var ring = RingBuffer([]const u8).init(allocator.allocator());

    try ring.pushFront("world");
    try ring.pushFront("hi");
    try ring.pushBack("hello");

    var i: usize = 0;
    while (ring.popBack()) |data| {
        i += 1;
        std.debug.print("ring[{}] = \"{s}\"\n", .{i, data});
    }
}