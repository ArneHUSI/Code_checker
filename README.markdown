# Simple Syntax Check for RKT

## Purpose

The script performs some simple syntax checks on the code in the provided file for compliance with the code conventions.

## How to use

The perl script can be called as

  ``perl check_code_conventions.pl filename.rkt [line_ctr_offset]``

The optional variable `line_ctr_offset` sets an offset to compensate for additional lines added by DrRacket but hidden in the DrRacket editor. 

## What the script does NOT do

* The script cannot find purpose statements that do NOT contain any of the indicator word "Return .\* giben .\*", "Purpose"
* The script cannot find interpretations that are NOT indicated with "Interp:" or "Interpretation"
* The script does not distinguish function templates and actual functions. Error messages for function templates and `main` may be ignored.
