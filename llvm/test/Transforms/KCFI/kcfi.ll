; RUN: opt -S -passes=kcfi %s | FileCheck %s

; CHECK-LABEL: define void @f1(
define void @f1(ptr noundef %x) {
  ; CHECK:      %[[#GEPI:]] = getelementptr inbounds i32, ptr %x, i32 -1
  ; CHECK-NEXT: %[[#LOAD:]] = load i32, ptr %[[#GEPI]], align 4
  ; CHECK-NEXT: %[[#ICMP:]] = icmp ne i32 %[[#LOAD]], 12345678
  ; CHECK-NEXT: br i1 %[[#ICMP]], label %[[#TRAP:]], label %[[#CALL:]], !prof ![[#WEIGHTS:]]
  ; CHECK:      [[#TRAP]]:
  ; CHECK-NEXT: call void @llvm.debugtrap()
  ; CHECK-NEXT: br label %[[#CALL]]
  ; CHECK:      [[#CALL]]:
  ; CHECK-NEXT: call void %x()
  ; CHECK-NOT:  [ "kcfi"(i32 12345678) ]
  call void %x() [ "kcfi"(i32 12345678) ]
  ret void
}

declare dso_local i32 @eh(...)

; CHECK-LABEL: define void @f2(
define void @f2(ptr noundef %x) personality ptr @eh {
  ; CHECK:      call void @llvm.debugtrap()
  ; CHECK-NEXT: br label %[[#INVOKE:]]
  ; CHECK:      [[#INVOKE]]:
  ; CHECK-NEXT: invoke void %x()
  ; CHECK-NOT:  [ "kcfi"(i32 12345678) ]
  invoke void %x() [ "kcfi"(i32 12345678) ] to label %cont unwind label %lpad
lpad:
  %res = landingpad { ptr, i32 } cleanup
  br label %cont
cont:
  ret void
}

!llvm.module.flags = !{!0}
!0 = !{i32 4, !"kcfi", i32 1}
; CHECK: ![[#WEIGHTS]] = !{!"branch_weights", i32 1, i32 1048575}
