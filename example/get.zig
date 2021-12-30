const std = @import("std");
const RingBuffer = @import("ringbuffer").RingBuffer;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}) {};
    var ring = RingBuffer([]const u8).init(allocator.allocator());

    try ring.pushFront("world");
    try ring.pushFront("hi");
    try ring.pushBack("hello");

    std.debug.print("ring[{d}] = \"{s}\"\n", .{ 2, ring.get(2).?.* });
    std.debug.print("ring[{d}] = \"{s}\"\n", .{ 100, ring.get(100) });
}
 