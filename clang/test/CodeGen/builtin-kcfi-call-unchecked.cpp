// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-llvm -fsanitize=kcfi -o - %s | FileCheck %s

#if !__has_builtin(__builtin_kcfi_call_unchecked)
#error "missing __builtin_kcfi_call_unchecked"
#endif

// CHECK: define{{.*}} i32 @_Z1av(){{.*}} prefix i32 [[#%d,HASH1:]]
int a(void) { return 0; }

class A {
public:
  static void a();
};

// CHECK: define{{.*}} void @_ZN1A1aEv(){{.*}} prefix i32 [[#%d,HASH2:]]
void A::a() {}

void h(void) {
  // CHECK: store ptr @_Z1av, ptr %
  // CHECK: %[[#P1:]] = load ptr, ptr %
  // CHECK: call void @llvm.kcfi.check(ptr %[[#P1]], i32 [[#HASH1]])
  // CHECK: call{{.*}} i32 %[[#P1]]()
  ({ a; })();

  // CHECK: store ptr @_Z1av, ptr %
  // CHECK: %[[#P2:]] = load ptr, ptr %
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call{{.*}} i32 %[[#P2]]()
  __builtin_kcfi_call_unchecked(({ a; })());

  // CHECK: store ptr @_ZN1A1aEv, ptr %
  // CHECK: %[[#P3:]] = load ptr, ptr %
  // CHECK: call void @llvm.kcfi.check(ptr %[[#P3]], i32 [[#HASH2]])
  // CHECK: call void %[[#P3]]()
  ({ &A::a; })();

  // CHECK: store ptr @_ZN1A1aEv, ptr %
  // CHECK: %[[#P4:]] = load ptr, ptr %
  // CHECK-NOT: call void @llvm.kcfi.check
  // CHECK: call void %[[#P4]]()
  __builtin_kcfi_call_unchecked(({ &A::a; })());
}
