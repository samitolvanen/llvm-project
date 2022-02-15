; RUN: llc -mtriple=aarch64-- < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=aarch64-- -stop-before=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,ISEL
; RUN: llc -mtriple=aarch64-- -stop-after=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,FINAL

; ASM:       .word 12345678
define void @f1(ptr noundef %x) #0 prefix i32 12345678 {
; ASM-LABEL: f1:
; ASM:       // %bb.0:
; ASM:         ldur w16, [x0, #-4]
; ASM-NEXT:    movk w17, #24910
; ASM-NEXT:    movk w17, #188, lsl #16
; ASM-NEXT:    cmp w16, w17
; ASM-NEXT:    b.eq .Ltmp0
; ASM-NEXT:    brk #0x8220
; ASM-NEXT:  .Ltmp0:
; ASM-NEXT:    blr x0

; MIR-LABEL: name: f1
; MIR: body:
; ISEL:       CFI_BLR 12345678, %0
; FINAL:      CFI_CHECK %0, 12345678, implicit-def $x16, implicit-def $x17, implicit-def $nzcv
; FINAL-NEXT: BLR %0
  call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

; ASM:       .word 12345678
define void @f2(ptr noundef %x) #0 prefix i32 12345678 {
; ASM-LABEL: f2:
; ASM:       // %bb.0:
; ASM:         ldur w16, [x0, #-4]
; ASM-NEXT:    movk w17, #24910
; ASM-NEXT:    movk w17, #188, lsl #16
; ASM-NEXT:    cmp w16, w17
; ASM-NEXT:    b.eq .Ltmp1
; ASM-NEXT:    brk #0x8220
; ASM-NEXT:  .Ltmp1:
; ASM-NEXT:    blr x0

; MIR-LABEL: name: f2
; MIR: body:
; ISEL:       CFI_BLR_BTI 12345678, %0
; FINAL:      CFI_CHECK %0, 12345678, implicit-def $x16, implicit-def $x17, implicit-def $nzcv
; FINAL-NEXT: BLR_BTI %0
  call void %x() #1 [ "kcfi"(i32 12345678) ]
  ret void
}

; ASM-NOT: .word:
define void @f3(ptr noundef %x) #0 {
; ASM-LABEL: f3:
; ASM:       // %bb.0:
; ASM:         ldur w9, [x16, #-4]
; ASM-NEXT:    movk w10, #24910
; ASM-NEXT:    movk w10, #188, lsl #16
; ASM-NEXT:    cmp w9, w10
; ASM-NEXT:    b.eq .Ltmp2
; ASM-NEXT:    brk #0x8150
; ASM-NEXT:  .Ltmp2:
; ASM-NEXT:    br x16

; MIR-LABEL: name: f3
; MIR: body:
; ISEL:       CFI_TCRETURNriBTI 12345678, %1, 0
; FINAL:      CFI_CHECK_BTI %1, 12345678, implicit-def $x9, implicit-def $x10, implicit-def $nzcv
; FINAL-NEXT: TCRETURNriBTI %1, 0
  tail call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

attributes #0 = { "kcfi-target" }
attributes #1 = { returns_twice }

!llvm.module.flags = !{!0, !1}
!0 = !{i32 8, !"branch-target-enforcement", i32 1}
!1 = !{i32 4, !"kcfi", i32 1}
