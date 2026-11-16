#ifndef MICROPYTHONMCU_MCU_THREAD_H
#define MICROPYTHONMCU_MCU_THREAD_H

#include <stdint.h>

#ifdef _WIN32
#include <windows.h>
#include <process.h>

typedef CRITICAL_SECTION McuMutex;
typedef CONDITION_VARIABLE McuCondition;
typedef HANDLE McuThread;
typedef DWORD McuThreadId;
#define MCU_THREAD_RETURN unsigned
#define MCU_THREAD_CALL __stdcall
#define MCU_WAIT_FOREVER INFINITE

static void mcu_mutex_init(McuMutex* mutex) { InitializeCriticalSection(mutex); }
static void mcu_mutex_lock(McuMutex* mutex) { EnterCriticalSection(mutex); }
static void mcu_mutex_unlock(McuMutex* mutex) { LeaveCriticalSection(mutex); }
static void mcu_condition_init(McuCondition* condition) { InitializeConditionVariable(condition); }
static void mcu_condition_signal(McuCondition* condition) { WakeConditionVariable(condition); }
static void mcu_condition_broadcast(McuCondition* condition) { WakeAllConditionVariable(condition); }
static void mcu_condition_wait(McuCondition* condition, McuMutex* mutex, unsigned long milliseconds) {
    if (!SleepConditionVariableCS(condition, mutex, milliseconds)) {
        DWORD error = GetLastError();
        if (error != ERROR_TIMEOUT) {
            ModelicaFormatError("PyRuntime: condition wait failed (Windows error %lu)", error);
        }
    }
}
static McuThreadId mcu_thread_id(void) { return GetCurrentThreadId(); }
static int mcu_thread_id_equal(McuThreadId a, McuThreadId b) { return a == b; }
static int mcu_thread_start(McuThread* thread, MCU_THREAD_RETURN (MCU_THREAD_CALL *worker)(void*), void* arg) {
    *thread = (HANDLE) _beginthreadex(NULL, 0, worker, arg, 0, NULL);
    return *thread != NULL;
}
static int mcu_thread_join(McuThread* thread, unsigned long milliseconds) {
    DWORD result = WaitForSingleObject(*thread, milliseconds);
    if (result == WAIT_FAILED) {
        ModelicaFormatError("PyRuntime: thread wait failed (Windows error %lu)", GetLastError());
    }
    return result == WAIT_OBJECT_0;
}
static uint64_t mcu_monotonic_ms(void) { return (uint64_t) GetTickCount64(); }

#elif defined(__linux__)
#include <errno.h>
#include <pthread.h>
#include <time.h>

typedef pthread_mutex_t McuMutex;
typedef pthread_cond_t McuCondition;
typedef pthread_t McuThreadId;
#define MCU_THREAD_RETURN void*
#define MCU_THREAD_CALL
#define MCU_WAIT_FOREVER ((unsigned long) -1)

typedef struct {
    pthread_t thread;
    pthread_mutex_t mutex;
    pthread_cond_t finished;
    int done;
    MCU_THREAD_RETURN (*worker)(void*);
    void* arg;
} McuThread;

static void mcu_thread_check(int result, const char* operation) {
    if (result != 0) ModelicaFormatError("PyRuntime: %s failed (error %d)", operation, result);
}
static void mcu_mutex_init(McuMutex* mutex) { mcu_thread_check(pthread_mutex_init(mutex, NULL), "mutex initialization"); }
static void mcu_mutex_lock(McuMutex* mutex) { mcu_thread_check(pthread_mutex_lock(mutex), "mutex lock"); }
static void mcu_mutex_unlock(McuMutex* mutex) { mcu_thread_check(pthread_mutex_unlock(mutex), "mutex unlock"); }
static void mcu_condition_init(McuCondition* condition) {
    pthread_condattr_t attributes;
    mcu_thread_check(pthread_condattr_init(&attributes), "condition attributes initialization");
    mcu_thread_check(pthread_condattr_setclock(&attributes, CLOCK_MONOTONIC), "condition clock selection");
    mcu_thread_check(pthread_cond_init(condition, &attributes), "condition initialization");
    mcu_thread_check(pthread_condattr_destroy(&attributes), "condition attributes destruction");
}
static void mcu_condition_signal(McuCondition* condition) { mcu_thread_check(pthread_cond_signal(condition), "condition signal"); }
static void mcu_condition_broadcast(McuCondition* condition) { mcu_thread_check(pthread_cond_broadcast(condition), "condition broadcast"); }
static void mcu_deadline(struct timespec* deadline, unsigned long milliseconds) {
    if (clock_gettime(CLOCK_MONOTONIC, deadline) != 0)
        ModelicaFormatError("PyRuntime: monotonic clock failed (error %d)", errno);
    deadline->tv_sec += (time_t) (milliseconds / 1000);
    deadline->tv_nsec += (long) (milliseconds % 1000) * 1000000L;
    if (deadline->tv_nsec >= 1000000000L) { deadline->tv_sec++; deadline->tv_nsec -= 1000000000L; }
}
static void mcu_condition_wait(McuCondition* condition, McuMutex* mutex, unsigned long milliseconds) {
    int result;
    if (milliseconds == MCU_WAIT_FOREVER) {
        result = pthread_cond_wait(condition, mutex);
    } else {
        struct timespec deadline;
        mcu_deadline(&deadline, milliseconds);
        result = pthread_cond_timedwait(condition, mutex, &deadline);
    }
    if (result != ETIMEDOUT) mcu_thread_check(result, "condition wait");
}
static McuThreadId mcu_thread_id(void) { return pthread_self(); }
static int mcu_thread_id_equal(McuThreadId a, McuThreadId b) { return pthread_equal(a, b); }
static void* mcu_thread_entry(void* arg) {
    McuThread* thread = (McuThread*) arg;
    void* result = thread->worker(thread->arg);
    mcu_mutex_lock(&thread->mutex);
    thread->done = 1;
    mcu_condition_signal(&thread->finished);
    mcu_mutex_unlock(&thread->mutex);
    return result;
}
static int mcu_thread_start(McuThread* thread, MCU_THREAD_RETURN (MCU_THREAD_CALL *worker)(void*), void* arg) {
    int result;
    mcu_mutex_init(&thread->mutex);
    mcu_condition_init(&thread->finished);
    thread->done = 0;
    thread->worker = worker;
    thread->arg = arg;
    result = pthread_create(&thread->thread, NULL, mcu_thread_entry, thread);
    if (result != 0) {
        mcu_thread_check(pthread_cond_destroy(&thread->finished), "condition destruction");
        mcu_thread_check(pthread_mutex_destroy(&thread->mutex), "mutex destruction");
        return 0;
    }
    return 1;
}
static int mcu_thread_join(McuThread* thread, unsigned long milliseconds) {
    struct timespec deadline;
    int result = 0;
    mcu_deadline(&deadline, milliseconds);
    mcu_mutex_lock(&thread->mutex);
    while (!thread->done && result == 0) {
        result = pthread_cond_timedwait(&thread->finished, &thread->mutex, &deadline);
    }
    if (result != ETIMEDOUT) mcu_thread_check(result, "thread completion wait");
    if (!thread->done) {
        mcu_mutex_unlock(&thread->mutex);
        return 0;
    }
    mcu_mutex_unlock(&thread->mutex);
    mcu_thread_check(pthread_join(thread->thread, NULL), "thread join");
    mcu_thread_check(pthread_cond_destroy(&thread->finished), "condition destruction");
    mcu_thread_check(pthread_mutex_destroy(&thread->mutex), "mutex destruction");
    return 1;
}
static uint64_t mcu_monotonic_ms(void) {
    struct timespec now;
    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0)
        ModelicaFormatError("PyRuntime: monotonic clock failed (error %d)", errno);
    return (uint64_t) now.tv_sec * 1000 + (uint64_t) now.tv_nsec / 1000000;
}
#else
#error Unsupported microcontroller runtime platform
#endif

#endif
