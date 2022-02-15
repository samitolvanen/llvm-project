// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck %s

#if !__has_feature(kcfi)
#error Missing kcfi
#endif

// CHECK-LABEL: define dso_local i32 @f1(){{.*}} prefix i32 [[#%d,HASH:]]
int f1(void) { return 0; }

typedef int (*fn_t)(void);
typedef int (*fn_unchecked_t)(void) __attribute__((kcfi_unchecked));

typedef typeof(f1) *fn_typeof_t;
typedef typeof(f1) *__attribute__((kcfi_unchecked)) fn_typeof_unchecked_t;

// CHECK-LABEL: define{{.*}} i32 @checked()
int checked(void) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 %
  return ({ &f1; })();
}
// CHECK-LABEL: define{{.*}} i32 @checked_typedef_cast()
int checked_typedef_cast(void) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 %
  return ({ (fn_t) & f1; })();
}
// CHECK-LABEL: define{{.*}} i32 @checked_outside_typedef_cast()
int checked_outside_typedef_cast(void) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 %
  return ((fn_t)({ &f1; }))();
}
// CHECK-LABEL: define{{.*}} i32 @checked_typeof_typedef_cast()
int checked_typeof_typedef_cast(void) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 %
  return ({ (fn_typeof_t) & f1; })();
}
// CHECK-LABEL: define{{.*}} i32 @checked_var()
int checked_var(void) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 %
  fn_t p = f1;
  return p();
}
// CHECK-LABEL: define{{.*}} i32 @checked_param(ptr
int checked_param(fn_t p) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 %
  return p();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_typedef_cast()
int unchecked_typedef_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  return ({ (fn_unchecked_t) & f1; })();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_outside_typedef_cast()
int unchecked_outside_typedef_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  return ((fn_unchecked_t)({ &f1; }))();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_typeof_typedef_cast()
int unchecked_typeof_typedef_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  return ({ (fn_typeof_unchecked_t) & f1; })();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_compound_var()
int unchecked_compound_var(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  return ({
    fn_unchecked_t p = (fn_unchecked_t)f1;
    p;
  })();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_compound_local_typedef_cast()
int unchecked_compound_local_typedef_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  return ({
    typedef typeof(f1) *__attribute__((kcfi_unchecked)) fn_local_unchecked_t;
    (fn_local_unchecked_t) & f1;
  })();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_var()
int unchecked_var(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  fn_unchecked_t p = (fn_unchecked_t)f1;
  return p();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_var_attr()
int unchecked_var_attr(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  fn_t __attribute__((kcfi_unchecked)) p = (fn_t __attribute__((kcfi_unchecked)))f1;
  return p();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_type_cast()
int unchecked_type_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 @f1
  return ((fn_unchecked_t)f1)();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_var_cast()
int unchecked_var_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 @f1
  return ((fn_t __attribute__((kcfi_unchecked)))f1)();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_cast()
int unchecked_cast(void) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 @f1
  return ((int (*__attribute__((kcfi_unchecked)))(void))f1)();
}
// CHECK-LABEL: define{{.*}} i32 @unchecked_param(ptr
int unchecked_param(fn_t __attribute__((kcfi_unchecked)) p) {
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call i32 %
  return p();
}
