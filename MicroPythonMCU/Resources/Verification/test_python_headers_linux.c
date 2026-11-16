/* Check both inclusion orders, including preservation of existing POSIX features. */
#ifdef TEST_PYTHON_FIRST
#include "../Include/cpython312linux/Python.h"
#ifndef _POSIX_C_SOURCE
#error "Python.h must select a POSIX feature level"
#endif
#else
#include <stdlib.h>

#ifndef _POSIX_C_SOURCE
#error "The system headers must select a POSIX feature level for this test"
#endif
enum { posix_before_python = _POSIX_C_SOURCE };

#include "../Include/cpython312linux/Python.h"

_Static_assert(_POSIX_C_SOURCE == posix_before_python,
               "Python.h changed the POSIX feature level after system headers");
#endif

int main(void) {
    return 0;
}
