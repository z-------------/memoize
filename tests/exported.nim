import memoize

proc someExportedProc*(n: int): string {.memoize.} =
  $n
