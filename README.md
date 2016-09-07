# PartitionAlloc

This is a fork of the PartitionAlloc code from Chrome's Blink engine. If you're not familiar with PartitionAlloc go read [this](http://struct.github.io/partition_alloc.html). The TLDR is that PartitionAlloc is a heap allocator that segments allocations based on size or type. This provides the ability to separate sensitive data structures from those tainted by user inputs if the API is used correctly. The PartitionAlloc developers offer the following security guarantees:

* Linear overflows cannot corrupt into the partition
* Linear overflows cannot corrupt out of the partition
* Freed pages will only be re-used within the partition (exception: large allocations > ~1MB)
* Freed pages will only hold same-sized objects when re-used.
* Dereference of freelist pointer should fault.
* Out-of-line main metadata: linear over or underflow cannot corrupt it.
* Partial pointer overwrite of freelist pointer should fault.
* Rudimentary double-free detection.
* Large allocations (> ~1MB) are guard-paged at the beginning and end.

# Hardening

PartitionAlloc provides some good security against heap exploits right out of the box. However there is always room for improvement. Many additional security mechanisms can be enabled if performance is not an issue. And that is precisely what I have done with this fork of the code. Some of these have been documented [here](http://struct.github.io/partition_alloc.html). The following changes have been made to the original PartitionAlloc code base:

* Randomization of the freelist upon creation
* Freelist entries are randomly selected upon allocation
* Better double free detection upon free
* All calls to ASSERT have been replaced with ASSERT_WITH_SECURITY_IMPLICATION and enabled by default
* Delayed free via a vector stored with the partition root

# Other additions

This fork also includes a basic C API with the following interfaces:

* new_generic_partition() - Returns a void pointer to a PartitionAllocatorGeneric class
* generic_partition_alloc(void *r, size_t s) - Returns an allocation from a PartitionAllocatorGeneric root r of size s
* generic_partition_free(void *r, void *a) - Frees an allocation a from a root r
* delete_generic_partition(void *r) - Deletes a PartitionAllocatorGeneric r
* partitionalloc_init() - Initializes all global partitions used in the C interface
* partitionalloc_shutdown() Shuts down all global partitions used in the C interface
* partition_malloc_sz(size_t s) - Allocates s bytes from a global size specific partition
* partition_free_sz(void *p) - Free a memory allocation p from a global size specific partition
* partition_malloc_string(size_t s) - Allocates s bytes from a global partition specifically for strings
* partition_free_string(void *p) - Frees a memory allocation p from a global partition specifically for strings
* partition_malloc(size_t s) - Allocates s bytes from a global generic partition
* partition_free(void *p) - Frees a memory allocation p from a global generic partition

The following additional things have been added:

* 4 Size specific partition templates for 64, 128, 256, and 512 byte allocations
* 2 Generic partitions, one for strings, one for general use
* A C++ class PartitionBackedBase which can be used as a base class which overloads new/delete operators to allocate from a size specific partition

# Usage

Type `make test` and then run `build/pa_test`. The pa_test.cpp program will show you the basics of using the C API.