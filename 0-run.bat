@ECHO OFF

call rebar3 as prod release
cd _build\prod\rel\ml_charge
bin\ml_charge-0.1.0.cmd console
cd ..\..\..\..


@REM call rebar3 release
@REM cd _build\default\rel\ml_charge
@REM bin\ml_charge-0.1.0.cmd console
@REM cd ..\..\..\..
