// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck --check-prefixes=CHECK %s
#if !__has_feature(kcfi)
#error Missing kcfi?
#endif

// CHECK: module asm ".weak __kcfi_typeid_f4"
// CHECK: module asm ".set __kcfi_typeid_f4, [[#]]"

typedef int (*fn_t)(void);

// CHECK: define dso_local i32 @f1() #[[#ATTR:]] prefix i32 [[#%d,HASH:]]
int f1(void) { return 0; }

// CHECK: define dso_local i32 @f2() #[[#ATTR]] prefix i32 [[#%d,HASH2:]]
unsigned int f2(void) { return 2; }

// CHECK-LABEL: define dso_local i32 @__call(ptr{{.*}} %f)
int __call(fn_t f) __attribute__((__no_sanitize__("kcfi"))) {
  // CHECK-NOT: call void @llvm.kcfi_check
  // CHECK: %call = call i32 %[[#]]()
  return f();
}

// CHECK-LABEL: define dso_local i32 @call(ptr{{.*}} %f)
int call(fn_t f) {
  // CHECK: call void @llvm.kcfi.check(ptr %[[#]], i32 [[#HASH]])
  // CHECK: %call = call i32 %[[#]]()
  return f();
}

// CHECK-DAG: define internal i32 @f3() #[[#ATTR]] prefix i32 [[#HASH]]
static int f3(void) { return 1; }

// CHECK-DAG: declare i32 @f4() #[[#DECLATTR:]] prefix i32 [[#HASH]]
extern int f4(void);

// CHECK-DAG: declare void @llvm.kcfi.check(ptr, i32 immarg)

// CHECK: define internal i32 @f5() #[[#LOCALATTR:]]
// CHECK-NOT: prefix i32
// CHECK-SAME: {
static int f5(void) { return 2; }

int test(void) {
  return call(f1) +
         __call((fn_t)f2) +
         call(f3) +
         call(f4) +
         f5();
}

// CHECK: attributes #[[#ATTR]] = {{{.*}}"kcfi"
// CHECK: attributes #[[#DECLATTR]] = {{{.*}}"kcfi"

// CHECK: attributes #[[#LOCALATTR]] = {
// CHECK-NOT: {{.*}}"kcfi"
// CHECK-SAME: }
