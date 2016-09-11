## Chris Rohlf - 2016
## chris.rohlf@gmail.com

UNAME := $(shell uname)

CXX = clang++
DEBUG = -ggdb
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
	$(CXX) $(CXXFLAGS) $(DEBUG) AddressSpaceRandomization.cpp Assertions.cpp PageAllocator.cpp \
		PartitionAlloc.cpp -shared $(LDFLAGS) -o build/partitionalloc.so

tests: library
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/pa_test.cpp build/partitionalloc.so -o build/pa_test
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/linear_overflow.cpp build/partitionalloc.so -o build/linear_overflow

clean:
	rm -rf */*.o build/*