#!/bin/bash  

(nohup ruby main.rb repo0.csv > output0 2>&1 & )&
(nohup ruby main.rb repo1.csv > output1 2>&1 & )&
(nohup ruby main.rb repo2.csv > output2 2>&1 & )&
(nohup ruby main.rb repo3.csv > output3 2>&1 & )&
(nohup ruby main.rb repo4.csv > output4 2>&1 & )&
