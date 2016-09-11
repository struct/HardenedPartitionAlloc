#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include "../PartitionAlloc.h"

#define BUFFER_SIZE 128

void run_test() {
	void *gp = new_generic_partition();
	void *p = generic_partition_alloc(gp, BUFFER_SIZE);
	ASSERT(p);
	// Should return 0
	int ret = check_partition_pointer(p);
	ASSERT(!ret);

	char *d = (char *) malloc(128);
	// Should assert and crash
	ret = check_partition_pointer(d);
	ASSERT(!ret);
	free(d);

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
