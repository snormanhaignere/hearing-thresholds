function hearing_thresholds(freq,ear,transfer_function_filename,varargin)

% function hearing_thresholds(freq,ear,transfer_function_filename,varargin)
% 
% Adaptive procedure for measuring hearing thresholds for pure tones. 
% Two-interval alternative forced choice paradigm. A tone is played
% in one of two intervals on each trial and subjects indicate which
% interval had the tone. 3-up, 1-down adaptive procedure used to track
% %80-point of psychometric curve. Step size are initially set to 5 dB.
% After 4-reversals they are reduced to step-sizes of 1 dB, and another
% 6-reversals are measured. 
% 
% 
% -- Required inputs --
% 
% freq: the frequency of the pure tone
% 
% ear: 'L' or 'R'
% 
% transfer_function_filename: path to a mat file specifying the transfer
% function of the appropriate ear for the headphones being used. The mat
% file should have a frequency (f) and power variable (px), which together
% specify the output power of the headphones (in dB SPL) for different
% frequencies given a sinusoidal input with a power in matlab of "0 dB"
% (unreferenced), i.e. 20*log10(rms(sinusoid)) = 0. This is the default
% format used by all McDermott calibration scripts.
% 
% 
% -- Optional inputs --
% 
% Optional arguments are specified in the format 'variable_name', value
% 
% output_directory: directory to save results to
%  
% output_filename: can specify the name of the output file to save results
% to, defaults to ['threshold_' num2str(round(freq)) 'Hz_ear' ear].
% 
% -- Example: threshold measurement for a pure tone of 1 kHz -- 
% freq = 1000;
% ear = 'R';
% transfer_function_filename = 'tf-example-earR.mat';
% hearing_thresholds(freq,ear,transfer_function_filename)

%% Setup

% directory to save results to
output_directory = pwd;
if optInputs(varargin, 'output_directory')
    output_directory = varargin{ optInputs(varargin, 'output_directory') + 1 };
end
output_filename = ['threshold_' num2str(round(freq)) 'Hz_ear' ear];
if optInputs(varargin, 'output_filename')
    output_filename = varargin{ optInputs(varargin, 'output_filename') + 1 };
end

% total duration of each interval
interval_duration = 0.5;

% duration of each tone
tone_duration = 0.25; % stimulus duration

% total number of reversals, and number of reversals with a large step size
nreversals = 16;
nreversals_large_step_size = 4;
large_step_size = 5; % in dB
small_step_size = 1;

% number of correct responses before making the task harder
ncorrect_update = 3;

% misc parameters
sr = 40000; % sampling rate
rampdur = 0.025; % linear ramp for main clip in seconds
spl_max = 100; % max SPL allowed

% directory with this this file

% paths to project, and home directory
% name_of_this_script = mfilename;
% path_to_this_file = which(name_of_this_script);
% scripts_directory = strrep(path_to_this_file, ['/' name_of_this_script '.m'], '');

% key codes
KbName('UnifyKeyNames');
responsecodes = KbName({'1!','2@'}); % other keys the subject might accidentally press

% load transfer function
tf = load(transfer_function_filename);

% create output directory if it doesn't exist
if ~exist(output_directory,'dir');
    mkdir(output_directory);
end

% Output files
datafile = fileplus([output_directory '/' output_filename '.txt']);
fid(1) = fopen(fileplus(datafile),'a');
matfile = strrep(datafile, '.txt', '.mat');

% header & format string for event data
header{1} = {'trial', 'spl', 'rkey', 'acc', 'rev'};
formatstring{1} = '%8d%8d%8d%8d%8d\n';

% initialize variables
n = 1000; % maximum number of trials
lastupdate = 0;
nright = 0;
p.spl = nan(n,1);
p.acc = nan(n,1);
p.rev = zeros(n,1);
p.rkey = nan(n,1);

% starting level based on sones
[sn.px, sn.f] = sone2spl(0.5);
p.spl(1) = round(myinterp1(sn.f, sn.px, freq, 'pchip'));
% p.spl(1) = 80;

%% Screens

run_start_time = GetSecs;

% open audio device
nchannels = 2; % controls number of channels, 2 for stereo, 1 for mono
playbackmode = 1;
latencyclass = 2; % controls how agressive PTB is in ensuring timing precicions
pahandle = MyPsychPortAudio('Open',[],playbackmode,latencyclass,sr,nchannels);

Screen('Preference','SkipSyncTests',1);
% ListenChar(0);
warning('ON'); %#ok<WNON>

% open screen
screenindex = max(Screen('Screens'));
mainwindow = Screen('OpenWindow',screenindex);%, 127, [0 0 1440 900]);
blankscreen = Screen(mainwindow,'OpenOffScreenWindow', 127);

% instruction screen
t = [...
    'Each trial contains two intervals, one with a tone and one without a tone.\n'...
    'Your task is to indicate the interval with the tone.\n\n',...
    'Press any key to begin'];

PresentTextScreen(t, mainwindow, blankscreen);
FlushEvents('keyDown'); GetChar;

writeheader(fid(1),header{1},formatstring{1},'command');

% loop over trials
for j = 1:n
    
    % interval in which to play the tone, 1 or 2
    tone_interval = (rand > 0.5) + 1;
    
    % create the stimulus
    tone = ramp(tonecomplex2(freq, p.spl(j), tone_duration, sr, 'tf', tf), rampdur, sr);
    
    % ready sound in buffer
    stim_stereo = zeros(2,length(tone));
    stim_stereo(strcmp(ear, {'L','R'}),:) = tone;
    MyPsychPortAudio('Stop',pahandle);
    MyPsychPortAudio('FillBuffer',pahandle,stim_stereo);
    
    % text indicating the interval
    start_time = GetSecs;
    PresentTextScreen('1', mainwindow, blankscreen);
    if tone_interval == 1
        MyPsychPortAudio('Start',pahandle,1, GetSecs+0.15);
    end
    
    % screen 2
    PresentTextScreen('2', mainwindow, blankscreen, start_time + interval_duration);
    if tone_interval == 2
        MyPsychPortAudio('Start',pahandle,1, GetSecs+0.15);
    end
    
    % query subject for response
    PresentTextScreen('?', mainwindow, blankscreen, start_time + interval_duration*2);
        
    % get response
    [~, p.rkey(j)] = responseloop(GetSecs, 100, responsecodes);
    
    % accuracy of response
    p.acc(j) = (p.rkey(j) == KbName('1!') && tone_interval==1) || (p.rkey(j) == KbName('2@') && tone_interval==2);
    if p.acc(j)
        nright = nright + 1;
    end
    
    % feedback
    if p.acc(j)
        PresentTextScreen('Correct', mainwindow, blankscreen);
    else
        PresentTextScreen('Incorrect', mainwindow, blankscreen);
    end
     
    % update level based on response and detect reversals
    if p.acc(j) && nright == ncorrect_update
        
        % detect reversal 
        if lastupdate == 1; % if last update made it easier
            p.rev(j) = 1;
        end
        
        % make harder
        if sum(p.rev) < nreversals_large_step_size;
            spl_change = large_step_size;
        else
            spl_change = small_step_size;
        end
        p.spl(j+1) = p.spl(j) - spl_change;
        
        % record the type of update
        lastupdate = -1;
        
        % reset nright to zero
        nright = 0;
        
    elseif ~p.acc(j)
        
        % detect reversal
        if lastupdate == -1; % if last update made it harder
            p.rev(j) = 1;
        end
        
        % make easier
        if sum(p.rev) < nreversals_large_step_size;
            spl_change = large_step_size;
        else
            spl_change = small_step_size;
        end
        p.spl(j+1) = p.spl(j) + spl_change;
        
        % record the type of update
        lastupdate = 1;
        
        % reset nright to zero
        nright = 0;        
        
    else
        
        % keep difference the same
        p.spl(j+1) = p.spl(j);
        
    end
    
    % write update
    fprintf(         formatstring{1}, j, p.spl(j), p.rkey(j), p.acc(j), p.rev(j) );
    fprintf( fid(1), formatstring{1}, j, p.spl(j), p.rkey(j), p.acc(j), p.rev(j) );
    
    p.spl(j+1) = min(p.spl(j+1), spl_max);
    
    if p.spl(j+1) > spl_max
        break;
    end
    
    if sum(p.rev) == nreversals
        break;
    end
    
    WaitSecs(0.5);
    
end

% calculate threshold
xi = find(p.rev);
p.threshold = mean(p.spl(xi(nreversals_large_step_size+1:end)));
fprintf('Estimated threshold: %.1f dB SPL\n', p.threshold);

run_end_time = GetSecs;
save(fileplus(matfile));

% display runtime
run_end_time - run_start_time
drawnow;

% tell subject they're done
t = 'All Finished. Thanks!';
PresentTextScreen(t, mainwindow, blankscreen);
WaitSecs(2);

% close all files
fclose all;
clear all;
