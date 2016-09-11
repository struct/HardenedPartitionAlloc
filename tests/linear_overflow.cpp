// This serves as an example of how to use the various
// C/C++ APIs that ship with Hardened PartitionAlloc
#include <stdio.h>
#include <stdlib.h>
#include "../PartitionAlloc.h"

// This program should result in the following ASSERT
// ASSERTION FAILED: *cookiePtr == root->kCookieValue[i]

#define BUFFER_SIZE 128

void run_test() {
	void *gp = new_generic_partition();
	void *p = generic_partition_alloc(gp, BUFFER_SIZE);
	ASSERT(p);
	memset(p, 0x41, BUFFER_SIZE*2);
	generic_partition_free(gp, p);
	delete_generic_partition(gp);
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
