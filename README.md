# ringbuffer.zig

A dynamic [ring buffer](https://en.wikipedia.org/wiki/Circular_buffer) (AKA circular buffer, circular queue, or cyclic buffer) implemented in [Zig](https://ziglang.org/).

Ring buffers are similar to arrays, but they can efficiently push and pop from both ends.

# Documentation

Zig Version: `v0.9.0`.
Simple Example:
```zig
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
```

## Initialization

A new `RingBuffer` type can be constructed with `RingBuffer(type)` function.
```zig
const RingBufferOfStrings = RingBuffer([]const u8);
```

A new *instance* can be created with `RingBuffer.init(std.mem.Allocator)` function.
```zig
var my_ring = RingBuffer(u32).init(my_allocator);
```

Note that `RingBuffer.init()` does not allocate until the buffer is modified.

To construct a buffer with an initial pool of memory use `RingBuffer.initCapacity(std.mem.Allocator, usize)`.
```zig
var my_ring = RingBuffer(u32).initCapacity(my_allocator, 16)
```
This buffer will hold *at least* 16 elements before needing to reallocate.

## Resetting

The buffer can be reset without freeing memory using `RingBuffer.clearRetainingCapacity()`.

## Freeing

A `RingBuffer` can be cleared, and all memory cleaned up with `RingBuffer.deinit()`.
Operations on a `RingBuffer` after calling `deinit()` are still valid. 

## Length and Capacity

Use `RingBuffer.len() usize` to get the number of items the buffer currently holds.\
Use `RingBuffer.capacity() usize` to get the number of items the buffer can hold before reallocating.

## Pushing Elements

Elements can be appended and prepended with the `RingBuffer.pushFront(T) !void` and `RingBuffer.pushBack(T) !void` functions.
This function may fail if it needs to allocate and the allocation fails.
```zig
var my_ring = RingBuffer([]const u8).init(my_allocator);

try my_ring.pushBack("one");
try my_ring.pushBack("two");
try my_ring.pushFront("three");
```
After these operations the buffer would look like
|  0    |  1  |  2  |
|-------|-----|-----|
| three | one | two |

## Popping Elements

Elements can be removed from the beginning and end of the queue with `RingBuffer.popFront() ?T` and `RingBuffer.popBack() ?T`.
These methods will remove either the first or last element and return it, or return null if there are no elements left.
```zig
var my_ring = RingBuffer([]const u8).init(my_allocator);

try my_ring.pushBack("one");
try my_ring.pushBack("two");
try my_ring.pushBack("three");
try my_ring.pushBack("four");

my_ring.popFront(); // returns "one"
my_ring.popBack();  // returns "four"
```
After these operations the buffer would look like
|   0   |   1   |
|-------|-------|
| two   | three |

## Random Access

Random access into the buffer with the `RingBuffer.get(usize) ?*T`.
If the index is outside the bounds of the buffer `null` is returned.

> **WARNING** Unlike `std.ArrayList` the underlying slice of `RingBuffer` cannot be accessed directly!

```zig
var my_ring = RingBuffer([]const u8).init(my_allocator);

try my_ring.pushBack("one");
try my_ring.pushBack("two");
try my_ring.pushBack("three");
try my_ring.pushBack("four");

my_ring.get(3); // returns "three"
```

## Iterators

For convience with while loops the `RingBuffer.Iterator` type can be constructed with `RingBuffer.iter() Iterator` and `RingBuffer.iterReverse() Iterator` functions.
Call `Iterator.next()` to advance the iterator, if it returns `null` than it has reached the end of the buffer.


Forward and reverse iterators have the exact same API.
Once they are constructed the direction cannot change

```zig
var iter = my_ring.iter();
while(iter.next()) |val| {
    // do something with `val`...
}
```

### Mutation While Iterating

Effects of pushing and popping from while an iterator is running is guarteed to be safe and the behavior is well defined.
However, can still lead to some odd results especially when adding elements to the same side thats being iterated over.

When iterating from one end and removing from the other the iterator will work normally.
```zig
try my_ring.pushBack(0);
try my_ring.pushBack(1);

// this will run once, then stop.
var iter = my_ring.iter();
while (iter.next()) |_| {
    try my_ring.popBack();
}
```

When popping and iterating from one end the iterator will be shifted up with each pop.
```zig
try my_ring.pushBack(0);
try my_ring.pushBack(1);
try my_ring.pushBack(2);

// this will run once, then stop.
var iter = my_ring.iterReverse();
while (iter.next()) |x| {
    // this will run twice
    //    first: x = 2
    //    second: x = 0
    try my_ring.popBack();
}
```

You can `deinit` the `RingBuffer`, and it will not invalidate the iterator:
```zig
try my_ring.pushBack(0);
try my_ring.pushBack(1);

var iter = my_ring.iter();
while (iter.next()) |x| {
    // this will run once, with x = 0
    try my_ring.deinit();
}
```

However, you cannot free the source ring buffer itself:
```zig
var iter = undefined;
{
    var my_ring = RingBuffer(u32).init();
    iter = my_ring.iter();
}

// `iter` is invalid here!!!
```

If the elements are pushed to one side while the iterator is running on the other the new elements will be iterated over.
```zig
my_ring.pushBack(0);
var iter = my_ring.iter();
while (iter.next()) |_| {
    // this is an infinite loop
    try my_ring.pushBack(0);
}
```

If elements are pushed onto the same side as the iterator they *do not* shift the iterator with them.
This can lead to elements being iterated over twice, and some being skipped.
For example, consider the queue with a running iterator:
```
"a", "b", "c", "d"
      ^
```

When the elements `"x", "y", "z"` are added to the front, it will now look like 
```
"x", "y", "z", "a", "b", "c", "d"
      ^
```
Now, if the user begins iterating again `"x"` will be skipped, and `"a"` will be seen again

