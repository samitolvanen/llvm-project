; RUN: opt < %s -passes=instcombine -S | FileCheck %s

define void @f1() #0 prefix i32 10 {
  ret void
}

declare void @f2() #0 prefix i32 11

define internal void @f3() {
  ret void
}

define void @g(ptr noundef %x) {
  ; CHECK: call void @llvm.kcfi.check(ptr %x, i32 10)
  call void @llvm.kcfi.check(ptr %x, i32 10)

  ; CHECK-NOT: call void @llvm.kcfi.check(ptr nonnull @f1, i32 10)
  ; CHECK: call void @llvm.kcfi.check(ptr nonnull @f1, i32 11)
  call void @llvm.kcfi.check(ptr nonnull @f1, i32 10)
  call void @llvm.kcfi.check(ptr nonnull @f1, i32 11)

  ; CHECK: call void @llvm.kcfi.check(ptr nonnull @f2, i32 10)
  ; CHECK-NOT: call void @llvm.kcfi.check(ptr nonnull @f2, i32 11)
  call void @llvm.kcfi.check(ptr nonnull @f2, i32 10)
  call void @llvm.kcfi.check(ptr nonnull @f2, i32 11)

  ; CHECK: call void @llvm.kcfi.check(ptr nonnull @f3, i32 10)
  call void @llvm.kcfi.check(ptr nonnull @f3, i32 10)
  ret void
}

; CHECK: declare void @llvm.kcfi.check(ptr, i32 immarg)
declare void @llvm.kcfi.check(ptr, i32 immarg)

attributes #0 = { "kcfi" }
