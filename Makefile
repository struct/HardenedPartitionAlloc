## Hardened Partition Alloc Makefile
## chris.rohlf@gmail.com - 2018

UNAME := $(shell uname)

CXX = clang++
DEBUG = -ggdb
HPA_DEBUG = -DHPA_DEBUG=1
ASAN = -fsanitize=address
LINUX_LDFLAGS = -ldl
MACOS_FLAGS = -framework CoreFoundation
CFLAGS = -std=c++11 -Wall -pedantic -D_FORTIFY_SOURCE=2 -fstack-protector-all -DENABLE_ASSERT=1

ifeq ($(UNAME), Darwin)
CXXFLAGS = $(CFLAGS) -fPIC $(MACOS_FLAGS)
endif

ifeq ($(UNAME), Linux)
CXXFLAGS = $(CFLAGS) -fPIC -fPIE $(LINUX_LDFLAGS)
endif

library:
	@mkdir -p build
	$(CXX) $(CXXFLAGS) AddressSpaceRandomization.cpp Assertions.cpp PageAllocator.cpp \
		PartitionAlloc.cpp -shared $(LDFLAGS) -o build/partitionalloc.so

debug_library:
	@mkdir -p build
	$(CXX) $(CXXFLAGS) $(DEBUG) $(HPA_DEBUG) AddressSpaceRandomization.cpp Assertions.cpp PageAllocator.cpp \
		PartitionAlloc.cpp -shared $(LDFLAGS) -o build/partitionalloc.so

tests: debug_library
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/pa_test.cpp build/partitionalloc.so -o build/pa_test
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/pointer_check.cpp build/partitionalloc.so -o build/pointer_check
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/linear_overflow.cpp build/partitionalloc.so -o build/linear_overflow

clean:
	rm -rf */*.o build/*