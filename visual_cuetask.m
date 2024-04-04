function visual_cuetask( subID )


% notification and results
% email ={ 'naturalzhou@gmail.com', 'zelanolab@gmail.com'};
% % email ={ 'naturalzhou@gmail.com'};

if ~isstring(subID)
    subID = num2str(subID);
end 

% for debug purpose
% winsize = [10, 10, 800, 600];% chicken debug 
winsize = [50, 50, 1600, 1200]; % desktop debug

% full-scrren mode
%  winsize = [];

% Background color: choose a number from 0 (black) to 255 (white)
backgroundColor = 195;


% Text color: choose a number from 0 (black) to 255 (white)
textColor = 0;
textSize = 44;

% minimal inter-trial interval, must be no smaller than response time out, in
% seconds
min_iti = 4;
% maximal inter-trial interval, in seconds
max_iti = 6;
% mean inter-trial interval, in seconds
avg_iti = 5;


% 'yes' | 'no'
hide_cursor = 'no';

% 'yes' | 'no'
email_results = 'no';

% ports for digitial and analog outputs
daq_dport = 0;



pulse_dur = 0.3;
pulse_dur_sniff = 0.5;
inter_pulse_dur = 0.1;
countdown_dur = 1;

rt_timeout = 10;
break_timeout = 300; 



%% Set up stimuli lists and results file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the image files for the experiment, all those files must be in the
% % same directory as this script
% instructions
inst_file = 'instructions.xls';
% cuelist_name = 'test_cue_odor.mat';


savedir = fileparts( mfilename);
if isempty( savedir)
    savedir = pwd;
end

% Find instructions/condNameition
[~,instructions] = xlsread( fullfile( savedir, inst_file));
instructions = instructions(:, 6);

% [~, allcues] = xlsread('all_cues.xls'); 

% load stimulus list 
% cuelist_name = fullfile(subID, ['session', num2str(sessionID)], ['cuelist_sess', num2str(sessionID), '_run', num2str(runID), '.mat']); 
cuelist_name = 'cuelist_visual.mat'; 
cuelist = load( fullfile( savedir, cuelist_name));
cuelist = cuelist.cuelist; % cue odor   

objects = cuelist.objects;  
totalTrials = length( cuelist.cueidx);


%% Set up the output file
resultsFolder = fullfile( savedir, 'results', subID);
% if exist( resultsFolder, 'dir')
%     surfix = GetClockSurfix;
%     resultsFolder = fullfile( savedir, 'results', num2str(subID), ['-', surfix]);
%     mkdir( resultsFolder);
% else
%     mkdir( resultsFolder);
% end
if ~exist( resultsFolder, 'dir')
    mkdir( resultsFolder);
end 

%% Set up the experiment (don't modify this section)
% settingsFacesResp; % Load all the settings from the file

% Keyboard setup
[kbInd, dev_names] = GetKeyboardIndices;

%% make sure randomly gen erated iti have means of ms 
avg_iti = round( avg_iti*1000);
dyn_iti = round( max_iti - min_iti) * 1000;
meanIti = 0;
while abs( meanIti - avg_iti) > eps
    iti = round( min_iti*1000 + dyn_iti*rand( totalTrials-1, 1));
    meanIti = mean( iti);
end
% convert back to seconds
iti = iti/1000;
iti = [min_iti; iti];

%% Set up screen
PsychDefaultSetup( 2);
Screen( 'Preference', 'SkipSyncTests', 2);
whichScreen = max( Screen( 'Screens'));
[w, rect] =  PsychImaging( 'OpenWindow', whichScreen, backgroundColor, winsize);
slack = Screen( 'GetFlipInterval', w)/2;
W = rect( RectRight); % screen width
H = rect( RectBottom); % screen height
if strcmpi( hide_cursor, 'yes')
    HideCursor;
end
Screen('TextSize', w, textSize);
Screen( w, 'FillRect', backgroundColor);
Screen('Flip', w);

[blk_crs_rect, blk_crs_color] = PT_Cross( rect, 50, 4, [0, 0, 0]);

blk_crs_dur = 2;

%% Initilize daq
% daq = OlfConfigDaq;
% %configure port A as output
% DaqDConfigPort( daq, daq_dport, 0);
% % initialize daq
% DaqDOut( daq, daq_dport, 0);

%%%%% on chicken: olfactometer right, daq left 
%%%%% on ostrich: daq1 olfactometer2
% [daq, err] = TwoDaqsIndex() ;

%% set up Olfactometer

% OlfFlowControl(daq(2),0.3,0.3);
% OlfOpenLines(1,daq(2));

%% Instructions
DrawFormattedText( w, instructions{1}, 'center', 'center', textColor);


%%% show demo choice box 

boxcolor = [0.6, 0.6, 0.6, 0.3]; % half transparent grey
boxsize = [100, 80];
leftboxx = rect(3) / 4 - boxsize(1) / 2 + 150;
rightboxx = 3 * rect(3) / 4 - boxsize(1) / 2 - 150;
boxY = rect(4) / 2 +200;

leftBoxRect = [leftboxx, boxY, leftboxx + boxsize(1), boxY + boxsize(2)];
rightBoxRect = [rightboxx, boxY, rightboxx + boxsize(1), boxY + boxsize(2)];
Screen('FillRect', w, boxcolor, leftBoxRect);
Screen('FillRect', w, boxcolor, rightBoxRect);

DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

Screen('Flip', w);


while true
    [~,kb] = KbWait;
    if kb( KbName( 'space'))==1
        break;
    end
end


%% initializing
% fixation cross
[fixCr, fixCross] = drawCross( w, backgroundColor);
pos_cross = imageCenter( fixCr, W, H);

%% practice 
nPractice = 3; 

KbReleaseWait; 
for n = 1 :  nPractice
    % draw cross
    Screen( 'FillRect', w, blk_crs_color, blk_crs_rect);
    %     DrawFormattedText( w, sprintf(instructions{5}), W/2-160, 4*H/5-30, textColor);
    Screen( 'Flip', w);

    % get ready to accept keyboard response
    PsychHID( 'KbQueueCreate');
    PsychHID( 'KbQueueStart');

    % inter-trial interval 
    WaitSecs( iti(n)-2);

    Screen( 'FillRect', w, [0, 1, 0], blk_crs_rect); % green cross for the last 2s 
    Screen( 'Flip', w);
    WaitSecs( 2);


    % start of current trial
    trl_time( n, 1) = GetSecs;

    % show word cue %%%% todo: remove this and just use auditory cue? 
    DrawFormattedText( w, objects{cuelist.cueidx( n)}, 'center', 'center', textColor);

    Screen( 'Flip', w);
    
    vidx = randi(2, 1); % pick voice 

    % read cue
    word_cue_wavfile = fullfile('cue_picture', [objects{cuelist.cueidx( n)}, '.mp3']  ); 
    [wY, wFREQ] = audioread(word_cue_wavfile);
     play_sound(word_cue_wavfile);

    % single pulse to indicate cue onset 
%     DaqDOut( daq(1), daq_dport, 1);
%     WaitSecs( pulse_dur);
%     DaqDOut( daq(1), daq_dport, 0);

    WaitSecs((length(wY)/wFREQ)+1);
    

    % count down & odor
    cdwav = fullfile('cue_voice', 'three.mp3');
    play_sound(cdwav); 
    DrawFormattedText( w, '3', 'center', 'center', textColor);
    [~, trl_time( n, 4)] = Screen( 'Flip', w);
    WaitSecs( countdown_dur);
    
    cdwav = fullfile('cue_voice', 'two.mp3');
    play_sound(cdwav); 
    DrawFormattedText( w, '2', 'center', 'center', textColor);
    Screen( 'Flip', w);
    
    WaitSecs( countdown_dur);
    
    cdwav = fullfile('cue_voice', 'one.mp3');
    play_sound(cdwav); 
    DrawFormattedText( w, '1', 'center', 'center', textColor);
    Screen( 'Flip', w);
    WaitSecs( countdown_dur);
    
    %%%%  show image

        imagefile = fullfile('pictures', [objects{cuelist.objidx( n)}, '.png']);; 
        [img, ~, alpha] = imread(imagefile); 

        if ~isempty(alpha) && any(alpha(:) ~= 0)
            % Create a new image with a white background
            imgWithWhiteBackground = repmat(255, [size(img, 1), size(img, 2), 3]);
            imgWithWhiteBackground = uint8(imgWithWhiteBackground);

            % Overlay the original image on top of the white background
            imgWithWhiteBackground(:,:,1) = imgWithWhiteBackground(:,:,1) .* uint8(alpha == 0) + img(:,:,1) .* uint8(alpha ~= 0);
            imgWithWhiteBackground(:,:,2) = imgWithWhiteBackground(:,:,2) .* uint8(alpha == 0) + img(:,:,2) .* uint8(alpha ~= 0);
            imgWithWhiteBackground(:,:,3) = imgWithWhiteBackground(:,:,3) .* uint8(alpha == 0) + img(:,:,3) .* uint8(alpha ~= 0);

            % Use the image with white background
            img = imgWithWhiteBackground;
        end

        imgsize = [500 ,500]; 
%         img(:, :, 4) = alpha; 
        imgScaled = imresize(img, imgsize);
        imgTexture = Screen('MakeTexture', w, imgScaled);
        imgSize = size(imgScaled);

        imgRect = [0 0 imgSize(2) imgSize(1)]; % Use scaled image size as rect for drawing
        imgRect = CenterRectOnPoint(imgRect, rect(3)/2, rect(4)/2); % Center

        Screen('DrawTexture', w, imgTexture, [], imgRect);
        Screen('Flip', w);

        WaitSecs(2); 



    %%% button response 
    
        boxcolor = [0.6, 0.6, 0.6, 0.3]; % half transparent grey 
        boxcolorselect = [0.6 ,0.7, 0.8, 0.5]; 
        boxsize = [100, 80];  
        leftboxx = rect(3) / 4 - boxsize(1) / 2 + 150; 
        rightboxx = 3 * rect(3) / 4 - boxsize(1) / 2 - 150;
        boxY = rect(4) / 2 +200;

        leftBoxRect = [leftboxx, boxY, leftboxx + boxsize(1), boxY + boxsize(2)];
        rightBoxRect = [rightboxx, boxY, rightboxx + boxsize(1), boxY + boxsize(2)];
        Screen('FillRect', w, boxcolor, leftBoxRect);
        Screen('FillRect', w, boxcolor, rightBoxRect);
        
        trialtype = cuelist.trialtype(n); %%% todo make a list of counter balanced trial types 
        if trialtype == 1
            DrawFormattedText(w, 'Yes', leftboxx + 20, boxY+50, [0 0 0]);
            DrawFormattedText(w, 'No', rightboxx + 25, boxY+50, [0 0 0]);
        else
            DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
            DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

        end

        DrawFormattedText(w, instructions{5}, 'center', 'center', [0 0 0]); 
        Screen('Flip', w);

        startTime = GetSecs(); % Record the start time
        duration = 5; % Duration in seconds

        while true % main response loop

            [keyIsDown, ~, keyCode] = KbCheck;
            % Check for key presses
            if keyIsDown
                if keyCode(KbName('LeftArrow'))
                    rsp = 1;
                    Screen('FillRect', w, boxcolorselect, leftBoxRect);
                    Screen('FillRect', w, boxcolor, rightBoxRect);

                    if trialtype == 1
                        DrawFormattedText(w, 'Yes', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'No', rightboxx + 25, boxY+50, [0 0 0]);
                    else
                        DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

                    end

                    DrawFormattedText(w, instructions{5}, 'center', 'center', [0 0 0]);
                    Screen('Flip', w);
                    WaitSecs(1);
                    break;

                elseif keyCode(KbName('RightArrow'))
                    rsp = 2;
                    Screen('FillRect', w, boxcolorselect, rightBoxRect);
                    Screen('FillRect', w, boxcolor, leftBoxRect);

                    if trialtype == 1
                        DrawFormattedText(w, 'Yes', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'No', rightboxx + 25, boxY+50, [0 0 0]);
                    else
                        DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

                    end

                    DrawFormattedText(w, instructions{5}, 'center', 'center', [0 0 0]);
                    Screen('Flip', w);
                    WaitSecs(1);
                    break;

                end
            end

            currentTime = GetSecs();
            if currentTime - startTime >= duration
                break; % Exit the loop after 3 seconds
            end
        end 
%         
%         % wait if selection is made before timeout 
%         currentTime = GetSecs();
%         if currentTime - startTime <= duration
%             WaitSecs(duration - (currentTime-startTime));
%         end

        PsychHID( 'KbQueueStop');
        responses{n} = rsp;
   
        PsychPortAudio('close'); % close audio port 


    %%%  automatically start next trial
 
end  
  


%% real experiment

DrawFormattedText( w, instructions{3}, 'center', 'center', textColor);
Screen('Flip',w);

%%% 
KbReleaseWait; 

while true
    [~,kb] = KbWait;
    if kb( KbName( 'space'))==1
        break;
    end
end

%%%% wait for 5 ttl pulses before hitting space to start 
% DaqDOut( daq(1), daq_dport, 1); WaitSecs( pulse_dur); DaqDOut( daq(1), daq_dport, 0); WaitSecs( inter_pulse_dur);
% DaqDOut( daq(1), daq_dport, 1); WaitSecs( pulse_dur); DaqDOut( daq(1), daq_dport, 0); WaitSecs( inter_pulse_dur);
% DaqDOut( daq(1), daq_dport, 1); WaitSecs( pulse_dur); DaqDOut( daq(1), daq_dport, 0); WaitSecs( inter_pulse_dur);



t = GetSecs;
% fid = fopen( fullfile( resultsFolder, [subID, '_session', num2str(sessionID), '_run', num2str(runID), '_results.txt']), 'w+');
% fprintf( fid,...
%     ['trialNum \t trialID \t cueID\t response_time\t response\t ITI\t Trial_StartTime\t Trial_EndTime\t   \n'], t);



% responses keys
responses = cell( totalTrials, 1);
responses_corrected = zeros( totalTrials, 1);
intensity_responses = cell( totalTrials, 1);
% starting time of each trial
trl_start_time = zeros( totalTrials, 1);
% onset of each trial
sti_onset = zeros( totalTrials, 1);
% ending time of each response period
resp_start_time = zeros(totalTrials, 1); 
resp_end_time = zeros( totalTrials, 1);
% response time
resptime = nan( totalTrials, 1);
outMat = cell( totalTrials, 1);
trial_start_clocktime = clock;
trial_start_time = GetSecs;
trial_time = [];
vas_score = zeros( totalTrials, 2);


for n = 1 :  totalTrials
    % draw cross
    Screen( 'FillRect', w, blk_crs_color, blk_crs_rect);
    %     DrawFormattedText( w, sprintf(instructions{5}), W/2-160, 4*H/5-30, textColor);
    Screen( 'Flip', w);

    % get ready to accept keyboard response
    PsychHID( 'KbQueueCreate');
    PsychHID( 'KbQueueStart');

    % inter-trial interval
    itistart = GetSecs();
    while true

        [keyIsDown, ~, keyCode] = KbCheck; % check for correction
        if keyIsDown
            if keyCode(KbName('LeftArrow'))
                rsp = 1;
            elseif keyCode(KbName('RightArrow'))
                rsp = 2;
            end
            rsp_corrected = 1;
            responses{n-1} = rsp; 
            responses_corrected(n-1) = rsp_corrected; 
        end

        currentTime = GetSecs();
        if currentTime > itistart + iti(n) - 2 % make up for ISI
            break;
        end
    end


    Screen( 'FillRect', w, [0, 1, 0], blk_crs_rect); % green cross for the last 2s 
    Screen( 'Flip', w);
    WaitSecs( 2);


    % start of current trial
    trl_time( n, 1) = GetSecs;

    % show word cue %%%% todo: remove this and just use auditory cue? 
    DrawFormattedText( w, objects{cuelist.cueidx( n)}, 'center', 'center', textColor);

    Screen( 'Flip', w);
    
    vidx = randi(2, 1); % pick voice 

    % read cue
    word_cue_wavfile = fullfile('cue_picture', [objects{cuelist.cueidx( n)}, '.mp3']  ); 
    [wY, wFREQ] = audioread(word_cue_wavfile);
     play_sound(word_cue_wavfile);

    % single pulse to indicate cue onset 
%     DaqDOut( daq(1), daq_dport, 1);
%     WaitSecs( pulse_dur);
%     DaqDOut( daq(1), daq_dport, 0);

    WaitSecs((length(wY)/wFREQ)+1);
    

    % count down & odor
    cdwav = fullfile('cue_voice', 'three.mp3');
    play_sound(cdwav); 
    DrawFormattedText( w, '3', 'center', 'center', textColor);
    [~, trl_time( n, 4)] = Screen( 'Flip', w);
    WaitSecs( countdown_dur);
    
    cdwav = fullfile('cue_voice', 'two.mp3');
    play_sound(cdwav); 
    DrawFormattedText( w, '2', 'center', 'center', textColor);
    Screen( 'Flip', w);
    
    WaitSecs( countdown_dur);
    
    cdwav = fullfile('cue_voice', 'one.mp3');
    play_sound(cdwav); 
    DrawFormattedText( w, '1', 'center', 'center', textColor);
    Screen( 'Flip', w);
    WaitSecs( countdown_dur);
    
    %%%%  show image

        imagefile = fullfile('pictures', [objects{cuelist.objidx( n)}, '.png']);; 
        [img, ~, alpha] = imread(imagefile); 

        if ~isempty(alpha) && any(alpha(:) ~= 0)
            % Create a new image with a white background
            imgWithWhiteBackground = repmat(255, [size(img, 1), size(img, 2), 3]);
            imgWithWhiteBackground = uint8(imgWithWhiteBackground);

            % Overlay the original image on top of the white background
            imgWithWhiteBackground(:,:,1) = imgWithWhiteBackground(:,:,1) .* uint8(alpha == 0) + img(:,:,1) .* uint8(alpha ~= 0);
            imgWithWhiteBackground(:,:,2) = imgWithWhiteBackground(:,:,2) .* uint8(alpha == 0) + img(:,:,2) .* uint8(alpha ~= 0);
            imgWithWhiteBackground(:,:,3) = imgWithWhiteBackground(:,:,3) .* uint8(alpha == 0) + img(:,:,3) .* uint8(alpha ~= 0);

            % Use the image with white background
            img = imgWithWhiteBackground;
        end

        imgsize = [500 ,500]; 
%         img(:, :, 4) = alpha; 
        imgScaled = imresize(img, imgsize);
        imgTexture = Screen('MakeTexture', w, imgScaled);
        imgSize = size(imgScaled);

        imgRect = [0 0 imgSize(2) imgSize(1)]; % Use scaled image size as rect for drawing
        imgRect = CenterRectOnPoint(imgRect, rect(3)/2, rect(4)/2); % Center

        Screen('DrawTexture', w, imgTexture, [], imgRect);
        Screen('Flip', w);

        WaitSecs(2); 



    %%% button response 
    
        boxcolor = [0.6, 0.6, 0.6, 0.3]; % half transparent grey 
        boxcolorselect = [0.6 ,0.7, 0.8, 0.5]; 
        boxsize = [100, 80];  
        leftboxx = rect(3) / 4 - boxsize(1) / 2 + 150; 
        rightboxx = 3 * rect(3) / 4 - boxsize(1) / 2 - 150;
        boxY = rect(4) / 2 +200;

        leftBoxRect = [leftboxx, boxY, leftboxx + boxsize(1), boxY + boxsize(2)];
        rightBoxRect = [rightboxx, boxY, rightboxx + boxsize(1), boxY + boxsize(2)];
        Screen('FillRect', w, boxcolor, leftBoxRect);
        Screen('FillRect', w, boxcolor, rightBoxRect);
        
        trialtype = cuelist.trialtype(n); 
        if trialtype == 1
            DrawFormattedText(w, 'Yes', leftboxx + 20, boxY+50, [0 0 0]);
            DrawFormattedText(w, 'No', rightboxx + 25, boxY+50, [0 0 0]);
        else
            DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
            DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

        end

        DrawFormattedText(w, instructions{5}, 'center', 'center', [0 0 0]); 
        Screen('Flip', w);

        startTime = GetSecs(); % Record the start time
        duration = 5; % Duration in seconds
        resp_start_time(n) = startTime;
        rsp = []; 
        while true % main response loop

            [keyIsDown, ~, keyCode] = KbCheck;
            % Check for key presses
            if keyIsDown
                if keyCode(KbName('LeftArrow'))
                    rsp = 1;
                    Screen('FillRect', w, boxcolorselect, leftBoxRect);
                    Screen('FillRect', w, boxcolor, rightBoxRect);

                    if trialtype == 1
                        DrawFormattedText(w, 'Yes', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'No', rightboxx + 25, boxY+50, [0 0 0]);
                    else
                        DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

                    end

                    DrawFormattedText(w, instructions{5}, 'center', 'center', [0 0 0]);
                    Screen('Flip', w);
                    WaitSecs(1);
                    break;

                elseif keyCode(KbName('RightArrow'))
                    rsp = 2;
                    Screen('FillRect', w, boxcolorselect, rightBoxRect);
                    Screen('FillRect', w, boxcolor, leftBoxRect);

                    if trialtype == 1
                        DrawFormattedText(w, 'Yes', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'No', rightboxx + 25, boxY+50, [0 0 0]);
                    else
                        DrawFormattedText(w, 'No', leftboxx + 20, boxY+50, [0 0 0]);
                        DrawFormattedText(w, 'Yes', rightboxx + 20, boxY+50, [0 0 0]);

                    end

                    DrawFormattedText(w, instructions{5}, 'center', 'center', [0 0 0]);
                    Screen('Flip', w);
                    WaitSecs(1);
                    break;

                end
            end

            currentTime = GetSecs();
            if currentTime - startTime >= duration
                break; % Exit the loop after 5 seconds
            end
        end 
%         
%         % wait if selection is made before timeout 
%         currentTime = GetSecs();
%         if currentTime - startTime <= duration
%             WaitSecs(duration - (currentTime-startTime));
%         end

        rsp_corrected = 0; 
        rsp_end_time = GetSecs();

        PsychHID( 'KbQueueStop');
        responses{n} = rsp;
        responses_corrected(n) = rsp_corrected; 
        resp_end_time(n) = rsp_end_time; 
   
        PsychPortAudio('close'); % close audio port 
    % print results to file
%     try
%         fprintf( fid, '%d \t %s \t %d \t %s \t  %d \t %d \t %d \n',...
%             n, cue{n},...
%             resptime(n), responses{n}, intensity_responses{ n}, iti(n), trl_time( n, 1), resp_end_time(n));
%     end
    
    outMat{ n} = {n, cuelist.cueidx(n),...
        resptime(n), responses{n}, intensity_responses{ n}, iti(n), trl_time( n, 1), resp_end_time(n)};
    

    %%%  automatically start next trial
 
end  
  

% fclose( fid);

WaitSecs( 5);


%% diaplay the cross for another 13 seconds while the notification is being sent
Screen( 'FillRect', w, blk_crs_color, blk_crs_rect);
Screen( 'Flip', w);

save( fullfile( resultsFolder, [subID, '_session', num2str(sessionID), '_run', num2str(runID), '_results.mat']), 'outMat');
% SendMail( email, [num2str(subID), ' done.']);
WaitSecs( 5);

DrawFormattedText( w, 'Experiment done, thank you :-)\n\n', 'center', 'center', textColor);
Screen( 'Flip', w);
WaitSecs( 3);
sca;

% Email final results
% if strcmpi( email_results, 'yes')
%     SendMail( email, num2str(subID), resultsFolder);
% end


end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NOTES 

% TODO: 
% make image cuelist 


%% Subfunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pos = imageCenter(image255,W,H)
imageSize = size(image255);
pos = [(W-imageSize(2))/2 (H-imageSize(1))/2 (W+imageSize(2))/2 (H+imageSize(1))/2];
end

% Draw a fixation cross (overlapping horizontal and vertical bar)
function [fixCr,fixCross] = drawCross(screenwindow,bg)
fixCr = ones(250,250)*bg;
fixCr(100:150,123:127)=0;
fixCr(123:127,100:150)=0;
fixCross = Screen('MakeTexture',screenwindow,fixCr);
end

function surfix = GetClockSurfix()
% Function retrieves the current time which can be appended to file or folder
% names to avoid overwriting existing ones
%
surfix = datestr( clock);
if any( strfind( surfix, ':'))
    surfix = strrep( surfix, ':', '-');
end
if any( strfind( surfix, ' '))
    surfix = strrep( surfix, ' ', '-');
end

end


function [allRects, allColors] = PT_Cross( windowRect, w, h, rgb_color)
% windowRect,  [window, windowRect] = PsychImaging( 'OpenWindow', screenNumber, black);
% rgb_color, [1 1 0];
% w, pixels
% h, pixels
% To plot
% Screen( 'FillRect', window, allColors, allRects);
%
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter( windowRect);
% Set the colors to yellow, Green and Blue
allColors = repmat( rgb_color(:), [1, 2]);
% Make our rectangle coordinates
allRects = nan(4, 2);
allRects( :, 1) = CenterRectOnPointd( [0, 0, w, h], xCenter, yCenter);
allRects( :, 2) = CenterRectOnPointd( [0, 0, h, w], xCenter, yCenter);
end



function audio_start_time = play_sound(wavfilename_in)

audiodev = 1; %{'Built-in Output'}
% audiodev = 0; % headphone
[y, freq] = audioread(wavfilename_in);
wavedata = y';
nrchannels = size(wavedata,1); % Number of rows == number of channels.

if nrchannels < 2 % make sure the sound has two channels per demo code
    wavedata = [wavedata ; wavedata];
    nrchannels = 2;
end

InitializePsychSound;
pahandle = PsychPortAudio('Open', audiodev, [], 0, freq, nrchannels);
PsychPortAudio('FillBuffer', pahandle, wavedata);

audio_start_time = PsychPortAudio('Start', pahandle, 1, 0, 1); 
end


function olfactometer(odoridx, intensity)   
% assign air line and adjust flow
if odoridx < 7 % use 1 and 7 as air line
    air = 7;
else
    air = 1;
end
main = odoridx;

if air == 1
    mfc2 = 0.3; %line 1-6
    mfc1 = intensity; % line 7-12
else 
    mfc2 = intensity; 
    mfc1 = 0.3; 
end 


OlfFlowControl(daq(2), mfc1, mfc2);
OlfOpenLines([air, main], daq(2));

WaitSecs(4); 
OlfOpenLines(air, daq(2)); 
end