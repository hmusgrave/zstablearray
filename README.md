# zstablearray

O(1) worst-case array-list

## Purpose

Amortized operations can seriously screw with the latency and stability of complicated systems. Paying a small cost to keep worst-case performance low can be beneficial.

## Status

This is just a sketch of the core of a data structure. You're still limited by the performance of your allocator, but allocations are typically quite cheap, especially for power-of-2 sized structures. The ArrayList itself splays the copies from one buffer to the next over the period of many insertions so that each append actually does constant work.
