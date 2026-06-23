# 0003 - Mutating skills must verify their post-conditions

From PR #1 review (tester major + minor).

## Symptom

The install skill's "Confirm" step verified nothing, and the host-block edit was prose-only. A
silent partial install (missing rules, or zero / duplicate marker blocks from a greedy or
mis-targeted edit) would pass unnoticed and report success.

## Root cause

A tool whose only output is mutated files shipped without post-condition checks, and its riskiest
step (the marker edit) was described rather than scripted.

## Fix

Confirm now checks that every owned rule exists and is non-empty and that exactly one host file
carries the Trellis block. The marker edit is scripted with `awk` and tested for idempotency
(running install twice yields one block) and for coexistence with a Spectra block.

## Learning

A tool whose only output is mutated files must assert its post-conditions; "tell the developer it
worked" is not verification. Feeds `overview/learnings.md`.
