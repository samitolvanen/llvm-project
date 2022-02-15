// RUN: %clang_cc1 -triple x86_64-unknown-unknown -verify -std=c++11 -fsyntax-only %s

typedef void (*fn_unchecked_t)(void) [[clang::kcfi_unchecked]]; // no-warning
typedef void (*fn_t)(void);

int [[clang::kcfi_unchecked]] i;               // expected-error {{'kcfi_unchecked' attribute cannot be applied to types}}
void f1(double i [[clang::kcfi_unchecked]]) {} // expected-warning {{'kcfi_unchecked' attribute only applies to functions and function pointers}}

void f2(fn_t f) {
  fn_unchecked_t p = f; // expected-error {{cannot initialize a variable of type}}
  p();                  // no-warning
}

[[clang::kcfi_unchecked("argument")]] int f3(); // expected-error {{'kcfi_unchecked' attribute takes no arguments}}
