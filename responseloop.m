function [rt rkey flipped] = responseloop(starttime,maxrt,responsecodes,varargin)

checkflip = false;
flipped = false;
if optInputs(varargin, 'flipscreen')
    checkflip = true;
    mainwindow = varargin{optInputs(varargin, 'flipscreen')+1};
    fliptime = varargin{optInputs(varargin, 'flipscreen')+2};
end

deviceindex = -3;
if optInputs(varargin, 'deviceindex')
    deviceindex = varargin{optInputs(varargin, 'deviceindex')+1};
end
    
loopdelay = 0.0005;
testcode = 0;
rt = nan;
rkey = nan;
% FlushEvents('keyDown');
while (GetSecs < starttime+maxrt)
    WaitSecs(loopdelay);
    [zz, secs, keyCode] = KbCheck(deviceindex); %#ok<ASGLU>
    if sum(keyCode(responsecodes)) == testcode
        if testcode == 0;
            testcode = 1;
        else
            rt = secs-starttime;
            rkey = responsecodes(logical(keyCode(responsecodes)));
            break;
        end
    end
    if checkflip && ~flipped && (GetSecs>fliptime)
        Screen('Flip',mainwindow);
        flipped = true;
    end
end