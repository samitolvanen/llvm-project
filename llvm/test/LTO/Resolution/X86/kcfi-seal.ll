; RUN: opt %s -o %t1.o
; RUN: llvm-lto2 run -O0 -o %t2.o %t1.o -r %t1.o,a,px -r %t1.o,b,p -r %t1.o,c,p -r %t1.o,p,p
; RUN: llvm-nm --numeric-sort %t2.o.0 | FileCheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

;; VisibleToRegularObj && !AddressTaken
; CHECK: T __cfi_a
; CHECK: T a
define void @a() !kcfi_type !1 {
  ret void
}

;; !VisibleToRegularObj && !AddressTaken
; CHECK-NOT: __cfi_b
; CHECK: t b
define void @b() !kcfi_type !1 {
  ret void
}

;; !VisibleToRegularObj && AddressTaken
; CHECK: t __cfi_c
; CHECK: t c
define void @c() !kcfi_type !1 {
  ret void
}

@p = global ptr @c

!llvm.module.flags = !{!0}
!0 = !{i32 4, !"kcfi", i32 1}
!1 = !{i32 12345678}
