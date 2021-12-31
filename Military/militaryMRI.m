function trial = militaryMRI(subID,sessID,runID)
% function [subject,task] = militaryMRI(subID,sessID,runID)
% Military fMRI experiment stimulus procedure
% Subject do red fixation detection task
% subID, subjet ID, integer[1-10]
% sessID, session ID, integer [1]
% runID, run ID, integer [1-10]
% workdir(or codeDir) -> sitmulus/instruciton/data 

%% Check subject information
% Check subject id
if ~ismember(subID, [1:10, 10086]), error('subID is a integer within [1:30]!'); end
% Check session id
if ~ismember(sessID, [1]), error('sessID is a integer within [1]!');end
% Check run id
if ~ismember(runID, 1:10), error('runID is a integer within [1:12]!'); end
nRun = 10;
nClass = 10;

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
videoAngle = 16;
fixOuterAngle = 0.2;
fixInnerAngle = 0.1;

% Visual angle to pixel
pixelPerMilimeterHor = 1024/390;
pixelPerMilimeterVer = 768/295;
videoPixelHor = round(pixelPerMilimeterHor * (2 * 1000 * tan(videoAngle/180*pi/2)));
videoPixelVer = round(pixelPerMilimeterVer * (2 * 1000 * tan(videoAngle/180*pi/2)));
fixOuterSize = round(pixelPerMilimeterHor * (2 * 1000 * tan(fixOuterAngle/180*pi/2)));
fixInnerSize = round(pixelPerMilimeterHor * (2 * 1000 * tan(fixInnerAngle/180*pi/2)));

% define size rect of the video frame
dsRect = [xCenter-videoPixelHor/2, yCenter-videoPixelHor/2,...
    xCenter+videoPixelVer/2, yCenter+videoPixelVer/2];

%% Response keys setting
% PsychDefaultSetup(2);% Setup PTB to 'featureLevel' of 2
KbName('UnifyKeyNames'); % For cross-platform compatibility of keynaming
startKey = KbName('s');
escKey = KbName('ESCAPE');
cueKey1 = KbName('1!'); % Left hand:1!
cueKey2 = KbName('2@'); % Left hand:2@

%% Make design for this run
% Set design dir
designDir = fullfile(workDir,'stimulus','designMatrix');
designFile = fullfile(sessDir,...
    sprintf('sub%02d_sess%02d_run%02d_design.mat',subID,sessID,runID));
if ~exist(designFile,'file')
    load(fullfile(designDir,'military.mat'), 'military');
    run = 10*(subID-1)+ runID;  
    if mod(run, 5) == 0 
        runActual = 5; % Actual run idx in selecting stimulus
    else
        runActual = mod(run, 5);
    end
    % prepare stimulus order and onset info
    runPar = military.paradigmClass{run};
    runStimOrg = military.stimulus(:, runActual);
    classOrder = runPar(runPar(:,2) ~= 0, 2); % Remove null event
    % generate runStim based on order info
    runStim = cell(size(classOrder,1), 1);
    for c = 1:nClass
        runStim(classOrder == c) = runStimOrg(int64(linspace(c, 50+c, 6)), 1);
    end
    runClass = military.className(classOrder);
    save(designFile,'runStim','runPar','runClass');
end

% Load session design
load(designFile,'runStim','runPar','runClass');

% Collect trial info for this run
nTrial = size(runPar, 1);
trial = zeros(nTrial, 7); % [onset, class, dur, key, RT, realTimePresent, realTimeFinish]
trial(:,1:3) = runPar; % % [onset, class, dur]

%% Load stimulus and instruction
% Load stimuli
stimDir = fullfile(workDir,'stimulus','video');
nStim = length(runStim);
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
    if keyIsDown && (keyCode(cueKey1) || keyCode(cueKey2)), break;
    end
end
readyDotColor = [255 0 0];
Screen('DrawDots', wptr, [xCenter,yCenter], fixOuterSize, readyDotColor, [], 2);
Screen('DrawingFinished',wptr);
Screen('Flip', wptr);

% Wait trigger(S key) to begin the test
while KbCheck(); end
while true
    [keyIsDown,~,keyCode] = KbCheck();
    if keyIsDown && keyCode(startKey), break;
    elseif keyIsDown && keyCode(escKey), sca; return;
    end
end

%% Run experiment
runDur = 288; % duration for a run
beginDur = 12; % beigining fixation duration
endDur = 12; % ending fixation duration
onDur = 1; % duration for respond time
fixColor = [0 0 0; 255 255 255]'; % color of fixation 
fixRespondColor = [0 0 0; 255 0 0]'; % color of fixation in respond status
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
idStim = 1; % Define idx for stimulus
for t = 1:nTrial
    key = 0; rt = 0; % Define key and rt
    if trial(t,2) ~= 0  % Show stimulus with fixation    
        % Start playback engine
        Screen('PlayMovie', mvPtr{idStim}, 1); % 1 means the normal speed    

        frameIndex = 0; % Calculate the index of present frame
        while true 
            % Draw movie frame
            tex = Screen('GetMovieImage', wptr, mvPtr{idStim});
            if tex <= 0, break; end    % End of movie. break out of loop.

            % Draw stimulus and fixation on the screen
            Screen('DrawTexture', wptr, tex, [], dsRect);
            Screen('DrawDots', wptr, fixCenter, fixSize, fixColor, [], 2);
            Screen('DrawingFinished', wptr);
            Screen('Close', tex);
            tStim = Screen('Flip', wptr);
            if frameIndex == 0, trial(t, 6) = tStim - tStart; end % record the real present time
            frameIndex = frameIndex + 1;
        end
        % Close movie
        trial(t, 7) = GetSecs - tStart; % record the real finish time
        Screen('PlayMovie', mvPtr{idStim}, 0); % 0 means stop playing
        Screen('CloseMovie', mvPtr{idStim}); % close movie file
        idStim = idStim + 1; 
    else % show only red fixation
        Screen('DrawDots', wptr, fixCenter, fixSize, fixRespondColor, [], 2);
        Screen('DrawingFinished',wptr);
        tStim = Screen('Flip', wptr);
        
        % Record response time
        while KbCheck(), end % empty the key buffer
        while GetSecs - tStim < onDur
            [keyIsDown, tKey, keyCode] = KbCheck();
            if keyIsDown
                if keyCode(escKey),sca; return;
                elseif keyCode(cueKey1) || keyCode(cueKey2)
                    key = 1; rt = tKey - tStim; break;
                end
            end
        end
    end
    
    % Show fixation
    Screen('DrawDots', wptr, fixCenter, fixSize, fixColor, [], 2);
    Screen('DrawingFinished',wptr);
    Screen('Flip', wptr);
    
    % Wait until trial ends
    while GetSecs - tStart < tEnd(t)
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyIsDown && keyCode(escKey), sca; return; end
    end
    trial(t, 4:5) = [key,rt];
end

% Wait ending fixation
WaitSecs(endDur);

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

% Print sucess and response rate info
fprintf('Military fMRI:sub%d-sess%d-run%d ---- DONE!\n Responding Rate: %2f\n',...
    subID, sessID, runID, sum(trial(:, 4))/sum(runPar(:, 2)==0))
if Test == 1
    fprintf('Testing Military fMRI ---- DONE!\n')
end



