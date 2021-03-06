import unittest
import memoize

import ./exported

template repeat(count, body: untyped): untyped =
  for i in 0..<count:
    body

test "result caching":
  const
    N = 10
    NHalved = N shr 1
    NDoubled = N shl 1

  var callCount = 0

  proc fib(n: int): int =
    doAssert(n >= 0)
    if n < 2: n
    else: fib(n - 1) + fib(n - 2)

  proc fibMemoized(n: int): int {.memoize.} =
    callCount.inc
    doAssert(n >= 0)
    if n < 2: n
    else: fibMemoized(n - 1) + fibMemoized(n - 2)
  
  check fibMemoized(N) == fib(N)
  check callCount == N + 1
  discard fibMemoized(N)
  check callCount == N + 1
  check fibMemoized(NHalved) == fib(NHalved)
  check callCount == N + 1
  check fibMemoized(NDoubled) == fib(NDoubled)
  check callCount == N + 1 + N

test "handling of parameter types":
  var callCount = 0

  proc foo(a: int; b: char): string {.memoize.} =
    callCount.inc
    return $b

  repeat 2:
    check foo(0, 'a') == "a"
    check callCount == 1
  repeat 2:
    check foo(0, 'b') == "b"
    check callCount == 2
  repeat 2:
    check foo(1, 'a') == "a"
    check callCount == 3

test "preservation of export flag":
  check someExportedProc(5) == "5"
