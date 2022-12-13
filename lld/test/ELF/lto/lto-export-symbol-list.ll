; REQUIRES: x86
; RUN: llvm-as %s -o %t1.o

; RUN: ld.lld %t1.o -r -o %t2.o
; RUN: llvm-readobj --symbols %t2.o | FileCheck %s --check-prefixes=CHECK,NOLIST

; RUN: echo "{ f2; };" > %t.list
; RUN: ld.lld %t1.o -r --lto-export-symbol-list %t.list -o %t
; RUN: llvm-readobj --symbols %t | FileCheck %s --check-prefixes=CHECK,LIST

;; f3 is referenced, but not in --lto-export-symbol-list.
; LIST:           Name: f3
; LIST-NEXT:      Value:
; LIST-NEXT:      Size:
; LIST-NEXT:      Binding: Local
; LIST-NEXT:      Type: Function
; LIST-NEXT:      Other:
; LIST-NEXT:      Section: .text
; LIST-NEXT:   }

;; f1 is not used and not in --export-symbol-list.
; LIST-NOT:       Name: f1
; NOLIST:         Name: f1
; NOLIST-NEXT:    Value:
; NOLIST-NEXT:    Size:
; NOLIST-NEXT:    Binding: Global
; NOLIST-NEXT:    Type: Function
; NOLIST-NEXT:    Other:
; NOLIST-NEXT:    Section: .text
; NOLIST-NEXT: }

;; f2 must always be exported.
; CHECK:          Name: f2
; CHECK-NEXT:     Value:
; CHECK-NEXT:     Size:
; CHECK-NEXT:     Binding: Global
; CHECK-NEXT:     Type: Function
; CHECK-NEXT:     Other:
; CHECK-NEXT:     Section: .text
; CHECK-NEXT:  }

;; f3 without --lto-export-symbol-list must be exported.
; NOLIST:         Name: f3
; NOLIST-NEXT:    Value:
; NOLIST-NEXT:    Size:
; NOLIST-NEXT:    Binding: Global
; NOLIST-NEXT:    Type: Function
; NOLIST-NEXT:    Other:
; NOLIST-NEXT:    Section: .text
; NOLIST-NEXT: }

;; p is not in an executable section, so it must not be affected.
; CHECK:          Name: p
; CHECK-NEXT:     Value:
; CHECK-NEXT:     Size:
; CHECK-NEXT:     Binding: Global
; CHECK-NEXT:     Type: Object
; CHECK-NEXT:     Other:
; CHECK-NEXT:     Section: .data
; CHECK-NEXT:  }

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @f1() {
  ret void
}

define void @f2() {
  ret void
}

define void @f3() {
  ret void
}

@p = global ptr @f3, align 8
