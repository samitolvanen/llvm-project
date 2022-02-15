// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck %s

#if !__has_feature(kcfi)
#error Missing kcfi
#endif

// CHECK-LABEL: define{{.*}} i32 @_Z2f1v(){{.*}} prefix i32 [[#%d,HASH:]]
int f1(void) { return 0; }

// CHECK-LABEL: define{{.*}} i32 @_Z2f2v(){{.*}} prefix i32 [[#%d,HASH2:]]
unsigned int f2(void) { return 1; }

template <typename T> int call(T p) { return p(); }

// CHECK-LABEL: define{{.*}} i32 @_Z7checkedv()
int checked() {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call{{.*}} i32 %[[#]]()
  return ({ &f1; })();
}

// CHECK-LABEL: define{{.*}} i32 @_Z16checked_templatev()
int checked_template() {
  // CHECK: call{{.*}} i32 @_Z4callIPFjvEEiT_(ptr{{.*}} @_Z2f2v)
  return call(f2);
}

// CHECK-LABEL: define{{.*}} i32 @_Z4callIPFjvEEiT_(ptr{{.*}} %p)
// CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH2]])
// CHECK-NEXT: call{{.*}} i32 %[[#]]()

// CHECK-LABEL: define{{.*}} i32 @_Z19unchecked_template1v()
int unchecked_template1() {
  using unchecked_t = int (*)() [[clang::kcfi_unchecked]];
  unchecked_t p = (unchecked_t)f1;
  // CHECK: call{{.*}} i32 @_Z4callIPFivEEiT_(ptr{{.*}} %[[#]])
  return call(p);
}

// CHECK-LABEL: define{{.*}} i32 @_Z4callIPFivEEiT_(ptr{{.*}} %p)
// CHECK-NOT: call void @llvm.kcfi.check
// CHECK: call{{.*}} i32 %[[#]]()

// CHECK-LABEL: define{{.*}} i32 @_Z19unchecked_template2v()
int unchecked_template2() {
  using unchecked_t = int (*)() [[clang::kcfi_unchecked]];
  // CHECK: call{{.*}} i32 @_Z4callIPFivEEiT_(ptr{{.*}} @_Z2f2v)
  return call((unchecked_t)f2);
}
