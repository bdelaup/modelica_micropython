/* Standalone test of the worker synchronization abstraction. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void ModelicaFormatError(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fputc('\n', stderr);
    exit(1);
}

#include "../Include/mcu_thread.h"

struct TestState {
    McuMutex mutex;
    McuCondition condition;
    int ready;
    int released;
    McuThreadId id;
};

static MCU_THREAD_RETURN MCU_THREAD_CALL worker(void* arg) {
    struct TestState* state = (struct TestState*) arg;
    mcu_mutex_lock(&state->mutex);
    state->id = mcu_thread_id();
    state->ready = 1;
    mcu_condition_signal(&state->condition);
    while (!state->released) {
        mcu_condition_wait(&state->condition, &state->mutex, MCU_WAIT_FOREVER);
    }
    mcu_mutex_unlock(&state->mutex);
    return 0;
}

int main(void) {
    struct TestState state;
    McuThread thread;
    uint64_t before;
#ifdef __linux__
    struct timespec deadline;
    struct timespec now;
    mcu_deadline(&deadline, 0);
    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0 ||
        deadline.tv_sec < now.tv_sec - 1 || deadline.tv_sec > now.tv_sec) {
        fprintf(stderr, "condition deadline does not use the monotonic clock\n");
        return 1;
    }
#endif
    memset(&state, 0, sizeof(state));
    mcu_mutex_init(&state.mutex);
    mcu_condition_init(&state.condition);
    if (!mcu_thread_start(&thread, worker, &state)) {
        fprintf(stderr, "thread creation failed\n");
        return 1;
    }
    mcu_mutex_lock(&state.mutex);
    while (!state.ready) mcu_condition_wait(&state.condition, &state.mutex, MCU_WAIT_FOREVER);
    if (mcu_thread_id_equal(state.id, mcu_thread_id())) {
        fprintf(stderr, "worker has the main thread's identity\n");
        return 1;
    }
    before = mcu_monotonic_ms();
    mcu_condition_wait(&state.condition, &state.mutex, 30);
    if (mcu_monotonic_ms() - before < 20) {
        fprintf(stderr, "condition wait returned too early\n");
        return 1;
    }
    mcu_mutex_unlock(&state.mutex);
    if (mcu_thread_join(&thread, 30)) {
        fprintf(stderr, "thread unexpectedly stopped\n");
        return 1;
    }
    mcu_mutex_lock(&state.mutex);
    state.released = 1;
    mcu_condition_broadcast(&state.condition);
    mcu_mutex_unlock(&state.mutex);
    if (!mcu_thread_join(&thread, 2000)) {
        fprintf(stderr, "worker did not stop\n");
        return 1;
    }
    puts("PASS: MCU worker synchronization");
    return 0;
}
