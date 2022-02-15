; RUN: llc -mtriple=aarch64-- < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=aarch64-- -global-isel < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=aarch64-- -stop-before=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,ISEL
; RUN: llc -mtriple=aarch64-- -stop-before=finalize-isel -global-isel < %s | FileCheck %s --check-prefixes=MIR,ISEL
; RUN: llc -mtriple=aarch64-- -stop-after=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,FINAL
; RUN: llc -mtriple=aarch64-- -stop-after=finalize-isel -global-isel < %s | FileCheck %s --check-prefixes=MIR,FINAL
; RUN: llc -mtriple=aarch64-- -mattr=harden-sls-blr -stop-before=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,ISEL-SLS
; RUN: llc -mtriple=aarch64-- -mattr=harden-sls-blr -stop-before=finalize-isel -global-isel < %s | FileCheck %s --check-prefixes=MIR,ISEL-SLS
; RUN: llc -mtriple=aarch64-- -mattr=harden-sls-blr -stop-after=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,FINAL-SLS
; RUN: llc -mtriple=aarch64-- -mattr=harden-sls-blr -stop-after=finalize-isel -global-isel < %s | FileCheck %s --check-prefixes=MIR,FINAL-SLS

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

; ISEL:       KCFI_BLR 12345678, %0
; FINAL:      KCFI_CHECK %0, 12345678, implicit-def $x16, implicit-def $x17, implicit-def $nzcv
; FINAL-NEXT: BLR %0

; ISEL-SLS:        KCFI_BLRNoIP 12345678, %0
; FINAL-SLS:       KCFI_CHECK %0, 12345678, implicit-def $x16, implicit-def $x17, implicit-def $nzcv
; FINAL-SLS-NEXT:  BLRNoIP %0
  call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

; ASM-NOT: .word:
define void @f2(ptr noundef %x) {
; ASM-LABEL: f2:
; ASM:       // %bb.0:
; ASM:         ldur w16, [x0, #-4]
; ASM-NEXT:    movk w17, #24910
; ASM-NEXT:    movk w17, #188, lsl #16
; ASM-NEXT:    cmp w16, w17
; ASM-NEXT:    b.eq .Ltmp1
; ASM-NEXT:    brk #0x8220
; ASM-NEXT:  .Ltmp1:
; ASM-NEXT:    br x0

; MIR-LABEL: name: f2
; MIR: body:

; ISEL:       KCFI_TCRETURNri 12345678, %0, 0

; FINAL:      KCFI_CHECK %0, 12345678, implicit-def $x16, implicit-def $x17, implicit-def $nzcv
; FINAL-NEXT: TCRETURNri %0, 0
  tail call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

attributes #0 = { "kcfi-target" }
