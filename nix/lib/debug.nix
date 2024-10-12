{ lib, r, ... }:
{
  # trace and return itself out
  strace = x: builtins.trace x x;
  straceSeq = x: lib.debug.traceSeq x x;
  straceSeqN = n: x: lib.debug.traceSeqN n x x;
}
