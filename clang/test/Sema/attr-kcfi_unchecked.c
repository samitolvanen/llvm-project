// RUN: %clang_cc1 %s -verify -fsyntax-only

int a __attribute__((kcfi_unchecked));   // expected-warning {{'kcfi_unchecked' attribute only applies to functions and function pointers}}
void *p __attribute__((kcfi_unchecked)); // expected-warning {{'kcfi_unchecked' attribute only applies to functions and function pointers}}
void (*f)(void) __attribute__((kcfi_unchecked));
void (*g)(void) __attribute__((kcfi_unchecked("argument"))); // expected-error {{'kcfi_unchecked' attribute takes no arguments}}

typedef unsigned long l_unchecked_t __attribute__((kcfi_unchecked)); // expected-warning {{'kcfi_unchecked' attribute only applies to functions and function pointers}}
typedef int (*f_unchecked_t)(void) __attribute__((kcfi_unchecked));

void f1(unsigned long p __attribute__((kcfi_unchecked))) {} // expected-warning {{'kcfi_unchecked' attribute only applies to functions and function pointers}}
void f2(void *p __attribute__((kcfi_unchecked))) {}         // expected-warning {{'kcfi_unchecked' attribute only applies to functions and function pointers}}
void f3(void (*p)(void) __attribute__((kcfi_unchecked))) {}

void f4(void) __attribute__((kcfi_unchecked)) {}
void test(void) {
  ((void (*__attribute__((kcfi_unchecked)))(void))f4)();
}
