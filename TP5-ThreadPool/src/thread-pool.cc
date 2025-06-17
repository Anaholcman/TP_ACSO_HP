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
    /*
    Se hace un mutex a la cola porque esta es compartida con varios threads/
    Se pushea la nueva tarea (thunk) a la cola y se aumenta la # de tareas pendientes
    */
    if (!thunk) {
        throw invalid_argument("Null function error");
    }
    {
        lock_guard<mutex> lock(queueLock); 
        tasks.push(thunk);  
        pendingTasks++;   
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

    taskAvailable.signal(); 
    for (size_t i = 0; i < wts.size(); ++i) {
        wts[i].hasWork.signal();
    }

    if (dt.joinable()) dt.join();

    for (auto& worker : wts) {
        if (worker.ts.joinable()) worker.ts.join();
    }

}

void ThreadPool::worker(int id) {
    /*
    Primero espera a que el dispacher le asigne trabajo, ejecuta el trabajo asignado, 
    decrementa la cantidad de tareas pendientes (para el funcionameinto del wait),
    se marca como disponible devuelta y le avisa al dispatcher que ya hay un worker libre */
    while (true) {
        wts[id].hasWork.wait();

        if (done) break;
        wts[id].thunk();

        if (--pendingTasks == 0) {
            unique_lock<mutex> lock(waitMutex);
            waitCv.notify_all();
        }
        {
            lock_guard<mutex> lock(queueLock);
            wts[id].available = true;
        }

        workersAvailable.signal();
    }
}


void ThreadPool::dispatcher() {
    /*
    Espera a que haya tareas y un worker libre. Se busca el primer worker disponible y se marca cono ocupado.
    Se hace un mutex para que nadie modifique la cola de tareas  ni el vector de workers
    Se saca la tarea de la cola se le asigna el trabajo al worker y lo despierta para que lo ejecute*/
    while (true) {
        taskAvailable.wait();  

        if (done) break;  

        workersAvailable.wait();  

        int id = -1;
        {
            lock_guard<mutex> lock(queueLock);
            for (size_t i = 0; i < wts.size(); ++i) {
                if (wts[i].available) {
                    id = i;
                    wts[i].available = false;  
                    break;
                }
            }

            wts[id].thunk = tasks.front();
            tasks.pop();
        }

        wts[id].hasWork.signal();
    }
}

