// RUN: %clang_cc1 -triple x86_64-unknown-linux -fsanitize=cfi-icall -emit-llvm -o - %s | FileCheck --check-prefixes=NOALIASES %s
// RUN: %clang_cc1 -triple x86_64-unknown-linux -fsanitize=cfi-icall -fsanitize-cfi-promotion-aliases -emit-llvm -o - %s | FileCheck --check-prefixes=ALIASES %s

void a(void) {}

// NOALIASES: !{i32 4, !"CFI Promotion Aliases", i32 0}
// ALIASES: !{i32 4, !"CFI Promotion Aliases", i32 1}
