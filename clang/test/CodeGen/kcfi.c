// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck --check-prefixes=CHECK,O0 %s
// RUN: %clang_cc1 -O2 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck --check-prefixes=CHECK,O2 %s
#if !__has_feature(kcfi)
#error Missing kcfi?
#endif

// CHECK: module asm ".weak __kcfi_typeid_f4"
// CHECK: module asm ".set __kcfi_typeid_f4, [[#%d,HASH:]]"

typedef int (*fn_t)(void);

// CHECK: define dso_local i32 @f1(){{.*}} #[[#ATTR:]] prefix i32 [[#HASH]]
int f1(void) { return 0; }

// CHECK: define dso_local i32 @f2(){{.*}} #[[#ATTR]] prefix i32 [[#%d,HASH2:]]
unsigned int f2(void) { return 2; }

// CHECK-LABEL: define dso_local i32 @__call(ptr{{.*}} %f)
int __call(fn_t f) __attribute__((__no_sanitize__("kcfi"))) {
  // CHECK-NOT: call void @llvm.kcfi_check
  // CHECK: call i32 %{{.}}()
  return f();
}

// CHECK-LABEL: define dso_local i32 @call(ptr{{.*}} %f)
int call(fn_t f) {
  // CHECK: call void @llvm.kcfi.check(ptr [[PTR:%.]], i32 [[#HASH]])
  // CHECK-NEXT: call i32 [[PTR]]()
  return f();
}

// O0-DAG: define internal i32 @f3() #[[#ATTR]] prefix i32 [[#HASH]]
static int f3(void) { return 1; }

// CHECK-DAG: declare i32 @f4(){{.*}} #[[#DECLATTR:]] prefix i32 [[#HASH]]
extern int f4(void);

// CHECK-DAG: declare void @llvm.kcfi.check(ptr, i32 immarg)

// O0: define internal i32 @f5() #[[#LOCALATTR:]]
// O0-NOT: prefix i32
// O0-SAME: {
static int f5(void) { return 2; }

int test(void) {
  return call(f1) +
         __call((fn_t)f2) +
         call(f3) +
         call(f4) +
         f5();
}

// CHECK: define dso_local i32 @test2()
int test2(void) {
  // O0: call void @llvm.kcfi.check(ptr [[F4:%.]], i32 [[#HASH]])
  // O0-NEXT: call i32 [[F4]]()
  // O2-NOT: call void @llvm.kcfi.check
  // O2: call i32 @f4()
  fn_t p = &f4;
  p();

  // O0: call void @llvm.kcfi.check(ptr [[F2:%.]], i32 [[#HASH]])
  // O0-NEXT: call i32 [[F2]]()
  // O2: call void @llvm.kcfi.check(ptr nonnull @f2, i32 [[#HASH]])
  p = (fn_t)&f2;
  p();

  // O0: call void @llvm.kcfi.check(ptr [[NULL:%.]], i32 [[#HASH]])
  // O0-NEXT: call i32 [[NULL]]()
  // O2: call void @llvm.kcfi.check(ptr null, i32 [[#HASH]])
  p = (fn_t)0;
  p();
  return 0;
}

// CHECK: attributes #[[#ATTR]] = {{{.*}}"kcfi"
// CHECK: attributes #[[#DECLATTR]] = {{{.*}}"kcfi"

// O0: attributes #[[#LOCALATTR]] = {
// O0-NOT: {{.*}}"kcfi"
// O0-SAME: }
