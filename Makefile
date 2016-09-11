## Chris Rohlf - 2016
## chris.rohlf@gmail.com

UNAME := $(shell uname)

CXX = clang++
DEBUG = -ggdb
ASAN = -fsanitize=address
LDFLAGS = -ldl

ifeq ($(UNAME), Darwin)
CXXFLAGS = -std=c++11 -Wall -pedantic -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -DENABLE_ASSERT=1 -framework CoreFoundation
endif

ifeq ($(UNAME), Linux)
CXXFLAGS = -std=c++11 -Wall -pedantic -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -DENABLE_ASSERT=1 $(LDFLAGS)
endif

library:
	$(CXX) $(CXXFLAGS) $(DEBUG) AddressSpaceRandomization.cpp Assertions.cpp PageAllocator.cpp \
		PartitionAlloc.cpp -shared $(LDFLAGS) -o build/partitionalloc.so

tests: library
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/pa_test.cpp build/partitionalloc.so -o build/pa_test
	$(CXX) $(CXXFLAGS) $(DEBUG) tests/linear_overflow.cpp build/partitionalloc.so -o build/linear_overflow

clean:
	rm -rf */*.o build/*