/**
 ***************************************************************************************** 
 * LLVM CRT file for DA14531 (Cortex M0+)
 *
 * Copyright (c) 2025 gilroy619
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * 
 ****************************************************************************************
 */

#include <stdint.h>

/* Weak declarations for runtime hooks (may be provided by newlib/clang runtime) */
void __libc_init_array(void) __attribute__((weak));
void __libc_fini_array(void) __attribute__((weak));
void _exit(int) __attribute__((noreturn, weak));

/* Some toolchains expect __main; keep weak to be safe */
void __main(void) __attribute__((weak));

/* Provide main as weak in case SDK/app doesn't define it (avoids link error) */
int main(void) __attribute__((weak));

/* _stack_init: optional stack initialization called by some crt0 implementations.
   On Renesas DA14531 the Reset_Handler sets stack(s), so make this a no-op. */
void _stack_init(void)
{
    /* intentionally empty */
}

/* _mainCRTStartup: perform runtime init and call main (GCC-like behaviour) */
__attribute__((noreturn))
void _mainCRTStartup(void)
{
    /* Run C++ constructors / init-array if provided by runtime */
    if (__libc_init_array) {
        __libc_init_array();
    }

    /* Legacy hook many toolchains expect */
    if (__main) {
        __main();
    }

    /* Call main if present; if not, just loop forever */
    if (main) {
        int ret = main();
        (void)ret;
    }

    /* If present, run fini array (unlikely on embedded) */
    if (__libc_fini_array) {
        __libc_fini_array();
    }

    /* If an _exit implementation exists, call it; otherwise loop forever */
    if (_exit) {
        _exit(0);
    }

    for (;;);
}

/* _start: glue used by some crt0 variants. Make it call _mainCRTStartup to
   match what GCC's crt0.o typically chains together. Renesas __cmsis_start()
   will call _start(), so this bridges to the CRT main startup. */
__attribute__((noreturn))
void _start(void)
{
    _mainCRTStartup();
}

/* Provide weak stub for _exit if nothing else is provided */
__attribute__((noreturn))
void _exit(int status)
{
    (void)status;
    for (;;);
}