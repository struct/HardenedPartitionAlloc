## Chris Rohlf - 2016
## chris.rohlf@gmail.com

UNAME := $(shell uname)

CXX = clang++

ifeq ($(UNAME), Darwin)
CXXFLAGS = -std=c++11 -Wall -pedantic -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -DENABLE_ASSERT=1 -framework CoreFoundation
endif

ifeq ($(UNAME), Linux)
CXXFLAGS = -std=c++11 -Wall -pedantic -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -DENABLE_ASSERT=1
endif

DEBUG = -ggdb
ASAN = -fsanitize=address
LDFLAGS =

prepare:
	mkdir build

library: prepare
	$(CXX) $(CXXFLAGS) $(DEBUG) AddressSpaceRandomization.cpp Assertions.cpp PageAllocator.cpp \
		PartitionAlloc.cpp -shared $(LDFLAGS) -o build/partitionalloc.so

test: library
	$(CXX) $(CXXFLAGS) $(DEBUG) pa_test.cpp build/partitionalloc.so -o build/pa_test

clean:
	rm -rf */*.o build/*
