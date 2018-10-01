#!/bin/sh

export CLASSPATH=mygps_types.jar
lcm-logger -s ./log/lcm-log-%F-%T &
lcm-spy
