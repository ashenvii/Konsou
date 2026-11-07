@echo off
rem Runs every gate. Adds Flutter to the path for this run if it is not there.
where flutter >nul 2>nul || set "PATH=C:\src\flutter\bin;%PATH%"
dart run tool\check.dart %*
