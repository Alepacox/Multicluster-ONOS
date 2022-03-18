#!/bin/bash

service openvswitch-switch start

python utils/topology.py $@
