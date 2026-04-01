@echo off
:: Open an elevated cmd window defaulting to the directory this script was called from
powershell -Command "Start-Process cmd -ArgumentList '/k cd /d \"%cd%\"' -Verb RunAs"