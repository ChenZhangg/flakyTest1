#!/bin/bash  

(nohup ruby main.rb test.csv > output 2>&1 & )&
