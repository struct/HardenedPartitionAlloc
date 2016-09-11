# Introduction

This is a standalone library containing PartitionAlloc, the allocator used in Chrome's Blink engine. It needs a lot of work and testing before it should be used on production code. This code is changing rapidly and should be considered unstable and untested until this notice is removed.

# PartitionAlloc

This is a fork of the PartitionAlloc code from Chrome's Blink engine. If you're not familiar with PartitionAlloc go read [this](http://struct.github.io/partition_alloc.html). The TLDR is that PartitionAlloc is a heap allocator that segments allocations based on size or type. This provides the ability to separate sensitive data structures from those tainted by user inputs if the API is used correctly. The PartitionAlloc developers offer the following security guarantees:

	* Linear overflows cannot corrupt into the partition
	* Linear overflows cannot corrupt out of the partition
	* Freed pages will only be re-used within the partition (exception: large allocations > ~1MB)
	* Freed pages will only hold same-sized objects when re-used
	* Dereference of freelist pointer should fault
	* Out-of-line main metadata: linear over or underflow cannot corrupt it
	* Partial pointer overwrite of freelist pointer should fault
	* Rudimentary double-free detection
	* Large allocations (> ~1MB) are guard-paged at the beginning and end

# Hardening

PartitionAlloc provides some good security against heap exploits right out of the box. However there is always room for improvement. Many additional security mechanisms can be enabled if performance is not an issue. And that is precisely what I have done with this fork of the code. Some of these have been documented [here](http://struct.github.io/partition_alloc.html). All calls to ASSERT have been replaced with ASSERT_WITH_SECURITY_IMPLICATION and enabled by default. This has obvious performance penalities.

The following changes have been made to the original PartitionAlloc code base.

## Allocate

	* Randomization of the freelist upon creation
	* Freelist entries are randomly selected upon allocation
	* Allocations are preceeded by a canary value that is unique per-partition and XOR'd by the last byte of the address of where it resides in memory
	* New allocations are memset with 0xDE
	* All freelist pointers are checked for a valid page mask and root inverted self value

## Free

	* Free'd allocations have their user data memset before they're added to delayed free list
	* Better double free detection upon free
	* Delayed free via a vector stored with the partition root

## Design

Some of the changes made to PartitionAlloc for security were thought through and the result of years of exploit writing. Others were made on a whim because they seemed like a good idea, I told you this wasn't ready for primetime yet 8)

The delayed free list is a std::vector stored within the partition root itself. This location was chosen for mainly two reasons: 1) To keep the PartitionPage and PartitionBucket structures at their current size and 2) To keep a separate freelist per-partition. The latter, in theory, helps with performance but I have no hard data to back that up.

The user data canary secret value is also stored in the partition root itself which means that each root has its own unique canary value. Each canary written to the beginning and end of a user allocation is XOR'd by the last byte of the address of where it resides in memory. This may change in the future as I research more into memory disclosure attacks against PartitionAlloc.

# API Additions

This fork also includes a basic C API with the following interfaces:

	* void *new_generic_partition() - Returns a void pointer to a PartitionAllocatorGeneric class
	* void *generic_partition_alloc(void *r, size_t s) - Returns an allocation from a PartitionAllocatorGeneric root r of size s
	* void generic_partition_free(void *r, void *a) - Frees an allocation a from a root r
	* void delete_generic_partition(void *r) - Deletes a PartitionAllocatorGeneric r
	* void partitionalloc_init() - Initializes all global partitions used in the C interface
	* void partitionalloc_shutdown() Shuts down all global partitions used in the C interface
	* void *partition_malloc_sz(size_t s) - Allocates s bytes from a global size specific partition
	* void partition_free_sz(void *p) - Free a memory allocation p from a global size specific partition
	* void *partition_malloc_string(size_t s) - Allocates s bytes from a global partition specifically for strings
	* void partition_free_string(void *p) - Frees a memory allocation p from a global partition specifically for strings
	* void *partition_malloc(size_t s) - Allocates s bytes from a global generic partition
	* void partition_free(void *p) - Frees a memory allocation p from a global generic partition
	* int check_partition_pointer(void *p) - Checks if p is a valid pointer with a partition (will assert if the check fails)

The following additional things have been added:

	* 4 Size specific partition templates for 64, 128, 256, and 512 byte allocations
	* 2 Generic partitions, one for strings, one for general use
	* A C++ class PartitionBackedBase which can be used as a base class which overloads new/delete operators to allocate from a size specific partition

# Exploitation

_This is a work in progress_

Modern memory safety exploitation is typically viewed as how much influence or control an untrusted input has over a read, write, or execute primitive. Exploit developers chain these primitives together in order to gain complete control of the process. Therefore it is important to make this process as difficult as possible. But default exploit mitigations such as DEP and ASLR only go so far and theres a fine balance between performance and security.

Heap allocators are a good target for exploit writers. They are usually where C++ objects, strings, and other data structures are stored during runtime. By design PartitionAlloc attempts to separate these types of objects in order to minimize the control an exploit developer has. But seperation of data types is not enough to stop exploitation. We need to be sure the heap allocator itself does not introduce any additional risk. We need to defend against a number of different bug classes with these objects such as double delete, overwrites, use-after-free's and so on.

# Usage

Type `make test` and then run `build/pa_test`. The pa_test.cpp program will show you the basics of using the C API.

# Performance

Do not use Hardened PartitionAlloc if performance is important for your application. There are plenty of fast user space allocators out there. They don't have the same security properties, they are designed for speed. If you want an allocator that tries to strike a balance between the two then you can likely just stick with your system allocator (ptmalloc2, LFH, etc). If you want an allocator that doesn't try to strike that balance and instead only cares about security then you may want to give Hardened PartitionAlloc a try.

# Todo

This is a work in progress and I would like to reach a stable release at some point soon. The goal is for it to be packaged for popular Linux distributions and actually used in production.

	* Improved delayed free implementation
	* More efficient double free detection
	* Document other security relevant asserts
	* Research memalign support https://github.com/struct/HardenedPartitionAlloc/issues/1

# Who

The fork of PartitionAlloc and hardening patches are maintained by Chris Rohlf chris.rohlf@gmail.com

The original PartitionAlloc (Google) and WebKit (Apple, Google) code are copyrighted by their respective authors. All licenses and code copyright headers have been preserved.

# Thanks

The following people are owed a thank you for their suggestions and ideas:

[CopperheadOS](https://twitter.com/copperheados)