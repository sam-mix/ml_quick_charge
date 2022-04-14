echo off

/data/rebar3/rebar3 as prod release
cd _build/prod/rel/ml_charge
bin/ml_charge-0.1.0.cmd console
cd ../../../..

