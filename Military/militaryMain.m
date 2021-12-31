%% Please run exp under the home dir of NaturalVisionProject
clear; close all
workDir = pwd;
addpath(genpath(workDir));

%% Set subject and session info:
% You should manually input subject ID and session ID
subName = 'Zhou Ming';subID = 3; sessID = 1;

%% Run ImageNet fMRI  
% You should mannual change runID for each run
close all;sca
militaryMRI(subID,sessID,1);
