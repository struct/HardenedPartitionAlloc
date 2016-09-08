// This serves as an example of how to use the various
// C/C++ APIs that ship with Hardened PartitionAlloc
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include "config.h"
#include "PartitionAlloc.h"

PartitionAllocatorGeneric my_partition;

class MyClass : public PartitionBackedBase {
  public:
	MyClass() {
		ptr = NULL;
		idx = 0;
	}

	~MyClass() { }

	void setPtr(char *s) {
		ptr = s;
	}
	char *getPtr() {
		return ptr;
	}

	void setIdx(int i) {
		idx = i;
	}

	int getIdx() {
		return idx;
	}

  private:
	char *ptr;
	int idx;
};

void run_test() {
	// PartitionAlloc API test with global root
	my_partition.init();
	void *p = partitionAllocGeneric(my_partition.root(), 16);
	partitionFreeGeneric(my_partition.root(), p);
	my_partition.shutdown();

	for(int i = 0; i < 512; i++) {
		p = partition_malloc_sz(64);
		ASSERT(p);
		partition_free_sz(p);
	}

	for(int i = 0; i < 512; i++) {
		p = partition_malloc_sz(128);
		ASSERT(p);
		partition_free_sz(p);
	}

	for(int i = 0; i < 512; i++) {
		p = partition_malloc_sz(256);
		ASSERT(p);
		partition_free_sz(p);
	}

	for(int i = 0; i < 32; i++) {
		p = partition_malloc_sz(512);
		ASSERT(p);
		partition_free_sz(p);
	}

	p = partition_malloc_string(128);
	ASSERT(p);
	partition_free_string(p);

	p = partition_malloc(512);
	ASSERT(p);
	partition_free(p);

	// Create a new MyClass which inherits from PartitionBackedBase
	// which overloads the new operator
	MyClass *mc = new MyClass();
	ASSERT(mc);
	delete mc;

	void *gp = new_generic_partition();
	p = generic_partition_alloc(gp, 128);
	ASSERT(p);
	generic_partition_free(gp, p);
	delete_generic_partition(gp);

	// Allocate some memory with glibc ptmalloc2
	void *t = malloc(1024);
	ASSERT(t);
	free(t);
}

int main(int argc, char *argv[]) {
	// Initialize the C API by calling _init() which will
	// make sure all generic partitions are initialized
	partitionalloc_init();

	// Run all tests
	run_test();

	// Shutdown all generic partitions
	partitionalloc_shutdown();

	return 0;
}
