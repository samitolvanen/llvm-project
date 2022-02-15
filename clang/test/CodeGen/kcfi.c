// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck --check-prefixes=CHECK,O0 %s
// RUN: %clang_cc1 -O2 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck --check-prefixes=CHECK,O2 %s
#if !__has_feature(kcfi)
#error Missing kcfi?
#endif

// COM: Must emit __kcfi_typeid symbols for address-taken function declarations
// CHECK: module asm ".weak __kcfi_typeid_f4"
// CHECK: module asm ".set __kcfi_typeid_f4, [[#%d,HASH:]]"

typedef int (*fn_t)(void);

// CHECK: define dso_local i32 @f1(){{.*}} #[[#TARGET:]] prefix i32 [[#HASH]]
int f1(void) { return 0; }

// CHECK: define dso_local i32 @f2(){{.*}} #[[#TARGET]] prefix i32 [[#%d,HASH2:]]
unsigned int f2(void) { return 2; }

// CHECK-LABEL: define dso_local i32 @__call(ptr{{.*}} %f)
int __call(fn_t f) __attribute__((__no_sanitize__("kcfi"))) {
  // CHECK-NOT: call i32 %{{.}}(){{.*}} [ "kcfi"
  return f();
}

// CHECK: define dso_local i32 @call(ptr{{.*}} %f){{.*}}
int call(fn_t f) {
  // CHECK: call i32 %{{.}}(){{.*}} [ "kcfi"(i32 [[#HASH]]) ]
  return f();
}

// O0-DAG: define internal i32 @f3() #[[#TARGET]] prefix i32 [[#HASH]]
static int f3(void) { return 1; }

// CHECK-DAG: declare i32 @f4(){{.*}} #[[#F4ATTR:]] prefix i32 [[#HASH]]
extern int f4(void);

// COM: Must not emit prefix data for non-address-taken local functions
// O0: define internal i32 @f5() #[[#LOCAL:]]
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

// CHECK: define dso_local i32 @test2(ptr{{.*}} [[PTR:%.]])
int test2(fn_t p) {
  // O0: call i32 %{{.}}() [ "kcfi"(i32 [[#HASH]]) ]
  // O2: tail call i32 [[PTR]](){{.*}} [ "kcfi"(i32 [[#HASH]]) ]
  int n = p();

  // COM: Must drop the kcfi operand bundle from indirect calls that were
  // COM: converted to direct calls.
  // O0: call i32 %{{.}}() [ "kcfi"(i32 [[#HASH]]) ]
  // O2: tail call i32 @f4()
  // O2-NOT: "kcfi"
  p = &f4;
  n += p();

  // O0: call i32 %{{.}}() [ "kcfi"(i32 [[#HASH]]) ]
  // O2-NOT: call i32 %{{.}}() [ "kcfi"
  p = (fn_t)&f2;
  return n + p();
}

// CHECK-DAG: attributes #[[#TARGET]] = {{{.*}}"kcfi-target"
// CHECK-DAG: attributes #[[#F4ATTR]] = {{{.*}}"kcfi-target"

// O0-DAG: attributes #[[#LOCAL]] = {
// O0-NOT: {{.*}}"kcfi-target"
// O0-SAME: }

// CHECK-DAG: ![[#]] = !{i32 4, !"kcfi", i32 1}
