#include "thread-pool.h"
using namespace std;

ThreadPool::ThreadPool(size_t numThreads) : 
    wts(numThreads), 
    done(false), 
    workersAvailable(numThreads)
    {
    for (size_t i = 0; i < numThreads; ++i) {
    wts[i].available = true;
    wts[i].ts = thread([this, i]() { worker(i); });
    }
    dt = thread([this]() { dispatcher(); });
}


void ThreadPool::schedule(const function<void(void)>& thunk) {
    {
        lock_guard<mutex> lock(queueLock); // hago un mutex a la cola porque esta es compartida con varios threads  
        tasks.push(thunk);   // pusheo la nueva tarea (thunk) a la cola
        pendingTasks++;     // aumento la # de tareas pendientes
    }
    taskAvailable.signal();

}

void ThreadPool::wait() {
    /*
    Mientras que halla tareas pendientes, lo mando a dormir. Para esto inicializo una condition variable. 
    Genera un mutex para 
    Solo cuando las tareas pendientes llegan a 0 se desbloquea el mutex */
    unique_lock<mutex> lock(waitMutex);
    waitCv.wait(lock, [this]() { return pendingTasks == 0; });
}

ThreadPool::~ThreadPool() {
    /*
    Se espera a que terminen las tareas pendientes, se despierta al dispacher y a todos los workers 
    y por ultimo te asegurás que el dispatcher y 
    todos los workers efectivamente terminen antes de destruir el ThreadPool*/
    wait();
    done = true;

    taskAvailable.signal(); // despierto al dispacher
    for (size_t i = 0; i < wts.size(); ++i) {
        wts[i].hasWork.signal();
    } //despierto a cada worker

    if (dt.joinable()) dt.join();

    for (auto& worker : wts) {
        if (worker.ts.joinable()) worker.ts.join();
    }

}
