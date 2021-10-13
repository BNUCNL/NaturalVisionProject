function trial = actionHacsMEG(subID,sessID,runID)
% function [subject,task] = actionHacsMRI(subID,sessID,runID)
% Action HACS fMRI experiment stimulus procedure
% Subject do sports vs not-sports activities task
% subID, subjet ID, integer[1-30]
% sessID, session ID, integer [1-4]
% runID, run ID, integer [1-12]
% workdir(or codeDir) -> sitmulus/instruciton/data 

% TO DO: 0. Change Design (12 run x 60 Trial --> 8 run x 90 Trial, Interval
% --> 1s) Done
%        1. DesignMatrix Check
%        2. Add Trigger Done
%        3. Change Distance DONE
%        4. Change Response Key Done

%% Check subject information
% Check subject id
if ~ismember(subID, [1:30, 10086]), error('subID is a integer within [1:30]!'); end
% Check session id
if ~ismember(sessID, 1:4), error('sessID is a integer within [1:4]!');end % just 1 sess
% Check run id
if ~ismember(runID, 1:8), error('runID is a integer within [1:8]!'); end
nRun = 8;
% nTrial = 60;
nTrial = 90;
nClass = 180;
nRepeat = nRun/(nClass/nTrial); % repeat time of classes in one session

%% Data dir
% Make work dir
workDir = pwd;

% Make data dir
dataDir = fullfile(workDir,'data');
if ~exist(dataDir,'dir'), mkdir(dataDir), end

% Make fmri dir
mriDir = fullfile(dataDir,'fmri');
if ~exist(mriDir,'dir'), mkdir(mriDir), end

% Make subject dir
subDir = fullfile(mriDir,sprintf('sub%02d', subID));
if ~exist(subDir,'dir'), mkdir(subDir),end

% Make session dir
sessDir = fullfile(subDir,sprintf('sess%02d', sessID));
if ~exist(sessDir,'dir'), mkdir(sessDir), end

%% For Test checking
if subID ==10086, subID = 1; Test = 1;
else, Test = 0; end

%% Screen setting
Screen('Preference', 'SkipSyncTests', 2);
if runID > 1
    Screen('Preference','VisualDebugLevel',3);
end
Screen('Preference','VisualDebugLevel',4);
Screen('Preference','SuppressAllWarnings',1);
bkgColor = [0.485, 0.456, 0.406] * 255; % ImageNet mean intensity
screenNumber = max(Screen('Screens'));% Set the screen to the secondary monitor
[wptr, rect] = Screen('OpenWindow', screenNumber, bkgColor);
[xCenter, yCenter] = RectCenter(rect);% the centre coordinate of the wptr in pixels
HideCursor;

% Visule angle for stimlus and fixation
videoAngle = 16; fixOuterAngle = 0.2; fixInnerAngle = 0.1;

% Visual angle to pixel
pixelPerMilimeterHor = 1024/419;
pixelPerMilimeterVer = 768/315;
videoPixelHor = round(pixelPerMilimeterHor * (2 * 751 * tan(videoAngle/180*pi/2)));
videoPixelVer = round(pixelPerMilimeterVer * (2 * 751 * tan(videoAngle/180*pi/2)));
fixOuterSize = round(pixelPerMilimeterHor * (2 * 751 * tan(fixOuterAngle/180*pi/2)));
fixInnerSize = round(pixelPerMilimeterHor * (2 * 751 * tan(fixInnerAngle/180*pi/2)));


% define size rect of the video frame
dsRect = [xCenter-videoPixelHor/2, yCenter-videoPixelHor/2,...
    xCenter+videoPixelVer/2, yCenter+videoPixelVer/2];

%% IO setting
ioObj = io64;
status = io64(ioObj);
address = hex2dec('D020');
if status,error('The driver installation process was not successful'); end 
startMark = 1; endMark = 8; % Mark for begin and end of the recording
frameMark = 2; respMark = 4; % Mark for each frame onset and response timing
markDur = 0.005;

%% Response keys setting
% PsychDefaultSetup(2);% Setup PTB to 'featureLevel' of 2
KbName('UnifyKeyNames'); % For cross-platform compatibility of keynaming
startKey = KbName('s');
escKey = KbName('ESCAPE');

% Left hand for sports and right hand for not-sports
sportsKey1 = KbName('8*'); % Left hand:8*
sportsKey2 = KbName('2@'); % Left hand:2@
notSportsKey1 = KbName('6^'); % Right hand: 6^
notSportsKey2 = KbName('4$'); % Right hand: 4$

%% Make design for this session
% Set design dir
% TO DO
designDir = fullfile(workDir,'stimulus','designMatrix');
designFile = fullfile(sessDir,...
    sprintf('sub%02d_sess%02d_design.mat',subID,sessID));
if ~exist(designFile,'file')
    load(fullfile(designDir,'meg_action.mat'),'action');
    sess = 4*(subID-1)+ sessID;
    % prepare stimulus order and onset info
    sessPar = squeeze(action.paradigmClass(:,sess,:));
    sessStim = squeeze(action.stimulus(:,sess));
    sessClass = cell(nClass, nRepeat);
    classOrder = sessPar(:,2);
    classOrder = reshape(classOrder,[nClass,nRepeat]);
    sessStim = reshape(sessStim,[nClass,nRepeat]);
    for r = 1:nRepeat % random stim order for each 180 classes
        sessStim(:,r) = sessStim(classOrder(:,r), r);
        sessClass(:,r) = action.className(classOrder(:,r));
    end
    sessStim = reshape(sessStim,[nTrial,nRun]);
    sessClass = reshape(sessClass, [nTrial,nRun]);
    sessPar = reshape(sessPar,[nTrial,nRun,3]);
    save(designFile,'sessStim','sessPar','sessClass');
end

% Load session design
load(designFile,'sessStim','sessPar','sessClass');

% Image for this run
runStim = sessStim(:,runID);
runClass = sessClass(:,runID);

% Collect trial info for this run
nStim = length(runStim);
nTrial = nStim;
trial = zeros(nTrial, 7); % [onset, class, dur, key, RT, realTimePresent, realTimeFinish]
trial(:,1:3) = squeeze(sessPar(:,runID,:)); % % [onset, class, dur]

%% Load stimulus and instruction
% Load stimuli
stimDir = fullfile(workDir,'stimulus', 'video');
mvPtr = cell(nStim,1);
for t = 1:nStim
    videoPath = fullfile(stimDir, runClass{t}, runStim{t});
    mvPtr{t} = Screen('OpenMovie', wptr, videoPath);
end

% Load  instruction
imgStart = imread(fullfile(workDir, 'instruction', 'expStart.JPG'));
imgEnd = imread(fullfile(workDir, 'instruction', 'expEnd.JPG'));

%% Show instruction
startTexture = Screen('MakeTexture', wptr, imgStart);
Screen('PreloadTextures',wptr,startTexture);
Screen('DrawTexture', wptr, startTexture);
Screen('DrawingFinished',wptr);
Screen('Flip', wptr);
Screen('Close',startTexture); 

% Wait ready signal from subject
while KbCheck(); end
while true
    [keyIsDown,~,keyCode] = KbCheck();
    if keyIsDown && (keyCode(sportsKey1) || keyCode(sportsKey2)), break;
    end
end
readyDotColor = [255 0 0];
Screen('DrawDots', wptr, [xCenter,yCenter], fixOuterSize, readyDotColor, [], 2);
Screen('DrawingFinished',wptr);
Screen('Flip', wptr);

% Set trigger(S key) to begin the test
while KbCheck(); end
while true
    [keyIsDown,tKey,keyCode] = KbCheck();
    if keyIsDown && keyCode(startKey)
        % Mark begining of exp 
        io64(ioObj,address,startMark);
        while GetSecs - tKey < markDur; end
        io64(ioObj,address,0);
        break;
    elseif keyIsDown && keyCode(escKey), sca; return;
    end
end

%% Run experiment
runDur = 318; % duration for a run *Change from 288 to 318
beginDur = 5; % beigining fixation duration  *Change from 12 to 5
endDur = 5; % ending fixation duration  *Change from 12 to 5
fixColor = [0 0 0; 255 255 255]'; % color of fixation 
fixCenter = [xCenter, yCenter; xCenter, yCenter]';
fixSize = [fixOuterSize, fixInnerSize];
tEnd = [trial(2:end, 1);runDur]; % make sequence of tEnd
if Test == 1, beginDur = 1;end  % test part

% Show begining fixation
Screen('DrawDots', wptr, fixCenter, fixSize, fixColor, [], 2);
Screen('DrawingFinished',wptr);
Screen('Flip',wptr);
WaitSecs(beginDur);

% Show stimulus
tStart = GetSecs;
for t = 1:nTrial
    % Start playback engine
    Screen('PlayMovie', mvPtr{t}, 1); % 1 means the normal speed    
    
    % If subject responds in stimulus presenting, we record it
    key = 0; rt = 0;
    while KbCheck(), end % empty the key buffer
    frameIndex = 0; % Calculate the index of present frame
    while true 
        % Draw movie frame
        tex = Screen('GetMovieImage', wptr, mvPtr{t});
        if tex <= 0, break; end    % End of movie. break out of loop.
        
        % Draw stimulus and fixation on the screen
        Screen('DrawTexture', wptr, tex, [], dsRect);
        Screen('DrawDots', wptr, fixCenter, fixSize, fixColor, [], 2);
        Screen('DrawingFinished', wptr);
        Screen('Close', tex);
        tStim = Screen('Flip', wptr);
        
        % Mark onset of each frame
        io64(ioObj,address,frameMark);
        while GetSecs - tStim < markDur, end
        io64(ioObj,address,0);
        
        if frameIndex == 0, trial(t, 6) = tStim - tStart; end % record the real present time
        frameIndex = frameIndex + 1;
        
        % Wait response
        [keyIsDown, tKey, keyCode] = KbCheck();
        if keyIsDown
            
            % Mark the rsponese
            io64(ioObj,address,respMark);
            while GetSecs - tKey < markDur, end
            io64(ioObj,address,0);
            
            if keyCode(escKey),sca; return; 
            elseif keyCode(sportsKey1) || keyCode(sportsKey2)
                key = 1; rt = tKey - tStim;
            elseif keyCode(notSportsKey1) || keyCode(notSportsKey2)
                key = -1; rt = tKey - tStim;
            end
        end
    end
    
    % Close movie
    trial(t, 7) = GetSecs - tStart; % record the real finish time
    Screen('PlayMovie', mvPtr{t}, 0); % 0 means stop playing
    Screen('CloseMovie', mvPtr{t}); % close movie file
        
    % Show fixation
    Screen('DrawDots', wptr, fixCenter, fixSize, fixColor, [], 2);
    Screen('DrawingFinished',wptr);
    Screen('Flip', wptr);
    
    % If subject has ready responded in stimtulus presenting, we'll not
    % record it in fixation period; if not, we record it.
    if rt
        while GetSecs - tStart < tEnd(t)
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown && keyCode(escKey), sca; return; end
        end
    else
        while GetSecs - tStart < tEnd(t)
            [keyIsDown, tKey, keyCode] = KbCheck();
            if keyIsDown
                
                % Mark the rsponese
                io64(ioObj,address,respMark);
                while GetSecs - tKey < markDur, end
                io64(ioObj,address,0);
                
                if keyCode(escKey),sca; return;
                elseif keyCode(sportsKey1) || keyCode(sportsKey2)
                    key = 1; rt = tKey - tStim;
                elseif keyCode(notSportsKey1)|| keyCode(notSportsKey2)
                    key = -1; rt = tKey - tStim;
                end
            end
        end
    end
    trial(t, 4:5) = [key,rt];
end

% Wait ending fixation
WaitSecs(endDur);
% Mark ending of exp 
tEnding = GetSecs;
io64(ioObj,address,endMark);
while GetSecs - tEnding < markDur, end
io64(ioObj,address,0);

% Show end instruction
endTexture = Screen('MakeTexture', wptr, imgEnd);
Screen('PreloadTextures',wptr,endTexture);
Screen('DrawTexture', wptr, endTexture);
Screen('DrawingFinished',wptr);
Screen('Flip', wptr);
Screen('Close',endTexture);
WaitSecs(2);

% Show cursor and close all
ShowCursor;
Screen('CloseAll');

%% Save data for this run
clear imgStart imgEnd
resultFile = fullfile(sessDir,...
    sprintf('sub%02d_sess%02d_run%02d.mat',subID,sessID,runID));

% If there is an old file, backup it
if exist(resultFile,'file')
    oldFile = dir(fullfile(sessDir,...
        sprintf('sub%02d_sess%02d_run%02d-*.mat',subID,sessID,runID)));
    
    % The code works only while try time less than ten
    if isempty(oldFile), n = 1;
    else, n = str2double(oldFile(end).name(end-4)) + 1;
    end
    
    % Backup the file from last test 
    newOldFile = fullfile(sessDir,...
        sprintf('sub%02d_sess%02d_run%02d-%d.mat',subID,sessID,runID,n));
    copyfile(resultFile,newOldFile);
end

% Save file
fprintf('Data were saved to: %s\n',resultFile);
save(resultFile);

% Print sucess info
fprintf('action HACS fMRI:sub%d-sess%d-run%d ---- DONE!\n',...
    subID, sessID,runID)
if Test == 1
    fprintf('Testing action HACS fMRI ---- DONE!\n')
end

%% Evaluate the response
load(fullfile(designDir,'sports_or_not.mat'),'sports_label');
% trial, nTial * 7 array;  % [onset, class, dur, key, RT, realTimePresent, realTimeFinish]
% Make target matrix nTrial x nCond
target = zeros(nTrial,2);
sports_label = sports_label(trial(:,2));
target(:,1) = sports_label == 1;
target(:,2) = sports_label == -1;

% Make response matrix nTrial x nCond
response = zeros(nTrial,2);
response(:,1) = trial(:,4) == 1;
response(:,2) = trial(:,4) == -1;

% Summarize the response with figure 
handle = responseEvaluation(target, response,{'Sports', 'Not-sports'});

% Save figure
figureFile = fullfile(sessDir,...
    sprintf('sub%02d_sess%02d_run%02d.jpg',subID,sessID,runID));
saveas(handle, figureFile);

function handle = responseEvaluation(target,response,condName)
% responseEvaluation(target,response,condName)
% target, response,rt,condName

idx = any(response,2);% only keep trial with response
[cVal,cMat,~,cPer] = confusion(target(idx,:)',response(idx,:)');
handle = figure('Units','normalized','Position',[0 0 0.5 0.5]);
% subplot(1,2,1), 
imagesc(cMat);
title(sprintf('RespProp = %.2f, Accuracy = %.2f',sum(idx)/length(target) ,1-cVal));
axis square
set(gca,'Xtick',1:length(cMat), 'XTickLabel',condName,...
    'Ytick',1:length(cMat),'YTickLabel',condName);
colorbar
text(0.75,1,sprintf('%.2f',cPer(1,3)),'FontSize',50,'Color','r');% hit
text(0.75,2,sprintf('%.2f',cPer(1,1)),'FontSize',50,'Color','r');% miss
text(1.75,1,sprintf('%.2f',cPer(1,2)),'FontSize',50,'Color','r');% false alarm
text(1.75,2,sprintf('%.2f',cPer(1,4)),'FontSize',50,'Color','r');% corect reject

% subplot(1,2,2), bar(cPer);
% set(gca,'XTickLabel',condName);
% ylabel('Rate')
% axis square
% legend({'Miss','False alarm','Hit','Correct reject'},...
%    'Orientation','vertical' ,'Location','northeastoutside' )
% legend boxoff