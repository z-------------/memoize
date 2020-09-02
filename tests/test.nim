import unittest
import memoize

test "it works":
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
