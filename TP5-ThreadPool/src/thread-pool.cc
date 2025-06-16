#include "thread-pool.h"
using namespace std;

ThreadPool::ThreadPool(size_t numThreads) : wts(numThreads), done(false) {
    for (size_t i = 0; i < numThreads; ++i) {
    wts[i].available = true;
    wts[i].ts = thread([this, i]() { worker(i); });
    }
}


void ThreadPool::schedule(const function<void(void)>& thunk) {}

void ThreadPool::wait() {}

ThreadPool::~ThreadPool() {}
