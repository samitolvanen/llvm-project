; RUN: llc -mtriple=x86_64-unknown-linux-gnu < %s | FileCheck %s
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -stop-before=finalize-isel < %s | FileCheck %s --check-prefix=ISEL

; CHECK:       .type __cfi_f1,@function
; CHECK-LABEL: __cfi_f1:
; CHECK-NEXT:    int3
; CHECK-NEXT:    int3
; CHECK-NEXT:    movl $12345678, %eax
; CHECK-NEXT:    int3
; CHECK-NEXT:    int3
; CHECK-LABEL: .L__cfi_func_end0:
; CHECK-NEXT:  .size   __cfi_f1, .L__cfi_func_end0-__cfi_f1
define void @f1(ptr noundef %x) #0 prefix i32 12345678 {

; CHECK-LABEL: f1:
; CHECK:       # %bb.0:
; CHECK:         cmpl $12345678, -6(%rdi) # imm = 0xBC614E
; CHECK-NEXT:    je .Ltmp0
; CHECK-NEXT:  .Ltmp1:
; CHECK-NEXT:    ud2
; CHECK-NEXT:    .section .kcfi_traps,"awo",@progbits,.text
; CHECK-NEXT:    .quad .Ltmp1
; CHECK-NEXT:    .text
; CHECK-NEXT:  .Ltmp0:
; CHECK-NEXT:    callq *%rdi

; ISEL: name: f1
; ISEL: body:
; ISEL: KCFI_CHECK %[[#CALL:]], 12345678, implicit-def dead $eflags
; ISEL: CALL64r %[[#CALL]], csr_64, implicit $rsp, implicit $ssp, implicit-def $rsp, implicit-def $ssp

  call void @llvm.kcfi.check(ptr %x, i32 12345678)
  call void %x()
  ret void
}

declare void @llvm.kcfi.check(ptr, i32 immarg)

attributes #0 = { "kcfi" }
