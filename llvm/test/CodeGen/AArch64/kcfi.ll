; RUN: llc -mtriple=aarch64-- < %s | FileCheck %s
; RUN: llc -mtriple=aarch64-- -stop-before=finalize-isel < %s | FileCheck %s --check-prefix=ISEL

; CHECK:       .word 12345678
define void @f1(ptr noundef %x) #0 prefix i32 12345678 {

; CHECK-LABEL: f1:
; CHECK:       // %bb.0:
; CHECK:         ldur w16, [x0, #-4]
; CHECK-NEXT:    movk w17, #24910
; CHECK-NEXT:    movk w17, #188, lsl #16
; CHECK-NEXT:    cmp w16, w17
; CHECK-NEXT:    b.eq .Ltmp0
; CHECK-NEXT:    brk #0x8220
; CHECK-NEXT:  .Ltmp0:
; CHECK-NEXT:    blr x0

; ISEL: name: f1
; ISEL: body:
; ISEL: KCFI_CHECK %[[#CALL:]], 12345678, implicit-def dead $x16, implicit-def dead $x17, implicit-def dead $nzcv
; ISEL: BLR %[[#CALL]]

  call void @llvm.kcfi.check(ptr %x, i32 12345678)
  call void %x()
  ret void
}

declare void @llvm.kcfi.check(ptr, i32 immarg)

attributes #0 = { "kcfi" }
