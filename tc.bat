@echo off

tasm %1.asm /m2
tlink %1.obj /t