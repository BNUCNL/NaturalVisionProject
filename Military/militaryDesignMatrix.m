% The script generates design matrix for military dataset
% Organize both stimulus video and stimulus order information into

clc;clear; 
%% Directory setting
stimDir =  'C:\Users\Blink621\Desktop\military\stimulus';
videoDir = fullfile(stimDir, 'video');
designDir = fullfile(stimDir, 'designMatrix');

%% Load class and stimulus info
% read super class info
fid = fopen(fullfile(designDir,'dataset.csv'));
C = textscan(fid, '%s %s','Headerlines', 1, 'Delimiter', ',');
fclose(fid);
className = unique(C{1}); % military class name, 10x1, cell array
stimulus = reshape(C{2}, [30, 10])'; % stimulus name, 30x10 cell array
stimulus = reshape(stimulus, [60, 5]); % Each run contains 60 stimulus, from 10 classes with repetition of 6 times

nClass = 10;
nRun = 100;

%% Load optseq info
optSeqClass = cell(nRun, 1); % In each run, it contains a nEvent x 3 array. [onset, class, dur]
for s = 1:nRun 
    % Read par from optseq
    optSeqSuperClassFile = fullfile(designDir, 'runPar',...
        sprintf('military-session-%03d.par',s));
    fid = fopen(optSeqSuperClassFile);
    optSeq = textscan(fid, '%d %d %d %d %s');
    fclose(fid);
    optSeqClass{s} = cell2mat(optSeq(1:3));
end

%% Pack and save military strcture
military.desp = 'military run-level paradigm';
military.className = className; % military class name, 10x1, cell array
military.stimulus = stimulus; % 60 x 5, cell array
military.paradigmClass = optSeqClass; % 100 x 1, cell array
military.date = datetime; 

% Save military to design dir
save(fullfile(designDir,'military.mat'), 'military');
