; RUN: llc -mtriple=x86_64-unknown-linux-gnu < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -stop-before=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,ISEL
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -stop-after=finalize-isel < %s | FileCheck %s --check-prefixes=MIR,FINAL
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -stop-after=x86-pseudo < %s | FileCheck %s --check-prefixes=MIR,PSEUDO

; ASM:       .type __cfi_f1,@function
; ASM-LABEL: __cfi_f1:
; ASM-NEXT:    int3
; ASM-NEXT:    int3
; ASM-NEXT:    movl $12345678, %eax
; ASM-NEXT:    int3
; ASM-NEXT:    int3
; ASM-LABEL: .Lcfi_func_end0:
; ASM-NEXT:  .size   __cfi_f1, .Lcfi_func_end0-__cfi_f1
define void @f1(ptr noundef %x) #0 prefix i32 12345678 {
; ASM-LABEL: f1:
; ASM:       # %bb.0:
; ASM:         cmpl $12345678, -6(%rdi) # imm = 0xBC614E
; ASM-NEXT:    je .Ltmp0
; ASM-NEXT:  .Ltmp1:
; ASM-NEXT:    ud2
; ASM-NEXT:    .section .kcfi_traps,"ao",@progbits,.text
; ASM-NEXT:  .Ltmp2:
; ASM-NEXT:    .long .Ltmp1-.Ltmp2
; ASM-NEXT:    .text
; ASM-NEXT:  .Ltmp0:
; ASM-NEXT:    callq *%rdi

; MIR-LABEL: name: f1
; MIR: body:
; ISEL:   CFI_CALL64r 12345678, %[[#]], csr_64, implicit $rsp, implicit $ssp, implicit-def $rsp, implicit-def $ssp
; PSEUDO:       BUNDLE implicit-def $eflags, implicit-def $rsp, implicit-def $esp, implicit-def $sp, implicit-def $spl, implicit-def $sph, implicit-def $hsp, implicit-def $ssp, implicit killed $rdi, implicit $rsp, implicit $ssp {
; PSEUDO-NEXT:    KCFI_CHECK killed renamable $rdi, 12345678, implicit-def $eflags
; PSEUDO-NEXT:    CALL64r killed renamable $rdi, csr_64, implicit $rsp, implicit $ssp, implicit-def $rsp, implicit-def $ssp
; PSEUDO-NEXT:  }
  call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

; ASM-NOT: __cfi_f2:
define void @f2(ptr noundef %x) {
; ASM-LABEL: f2:

; MIR-LABEL: name: f2
; MIR: body:
; ISEL:   CFI_TCRETURNri64 12345678, %[[#]], 0, csr_64, implicit $rsp, implicit $ssp
; PSEUDO:       BUNDLE implicit-def $eflags, implicit killed $rdi, implicit $rsp, implicit $ssp {
; PSEUDO-NEXT:    KCFI_CHECK killed renamable $rdi, 12345678, implicit-def $eflags
; PSEUDO-NEXT:    TAILJMPr64 killed renamable $rdi, csr_64, implicit $rsp, implicit $ssp, implicit $rsp, implicit $ssp
; PSEUDO-NEXT:  }
  tail call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

; ASM-NOT: __cfi_f3:
define void @f3(ptr noundef %x) #1 {
; ASM-LABEL: f3:
; MIR-LABEL: name: f3
; MIR: body:
; ISEL:   CFI_INDIRECT_THUNK_CALL64 12345678, %0, csr_64, implicit $rsp, implicit $ssp, implicit-def $rsp, implicit-def $ssp
; FINAL:  CFI_CALL64pcrel32 12345678, &__llvm_retpoline_r11, csr_64, implicit $rsp, implicit $ssp, implicit-def $rsp, implicit-def $ssp, implicit killed $r11
; PSEUDO:       BUNDLE implicit-def $eflags, implicit-def $rsp, implicit-def $esp, implicit-def $sp, implicit-def $spl, implicit-def $sph, implicit-def $hsp, implicit-def $ssp, implicit killed $r11, implicit $rsp, implicit $ssp {
; PSEUDO-NEXT:    KCFI_CHECK $r11, 12345678, implicit-def $eflags
; PSEUDO-NEXT:    CALL64pcrel32 &__llvm_retpoline_r11, csr_64, implicit $rsp, implicit $ssp, implicit-def $rsp, implicit-def $ssp, implicit killed $r11
; PSEUDO-NEXT:  }
  call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

; ASM-NOT: __cfi_f4:
define void @f4(ptr noundef %x) #1 {
; ASM-LABEL: f4:
; MIR-LABEL: name: f4
; MIR: body:
; ISEL:   CFI_INDIRECT_THUNK_TCRETURN64 12345678, %[[#]], 0, csr_64, implicit $rsp, implicit $ssp
; FINAL:  CFI_TCRETURNdi64 12345678, &__llvm_retpoline_r11, 0, csr_64, implicit $rsp, implicit $ssp, implicit killed $r11
; PSEUDO:       BUNDLE implicit-def $eflags, implicit killed $r11, implicit $rsp, implicit $ssp {
; PSEUDO-NEXT:    KCFI_CHECK $r11, 12345678, implicit-def $eflags
; PSEUDO-NEXT:    TAILJMPd64 &__llvm_retpoline_r11, csr_64, implicit $rsp, implicit $ssp, implicit $rsp, implicit $ssp, implicit killed $r11
; PSEUDO-NEXT:  }
  tail call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

attributes #0 = { "kcfi-target" }
attributes #1 = { "target-features"="+retpoline-indirect-branches,+retpoline-indirect-calls" }

!llvm.module.flags = !{!0}
!0 = !{i32 4, !"kcfi", i32 1}
