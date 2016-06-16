function PresentTextScreen(t, mainwindow, blankscreen, start_time)

Screen('CopyWindow', blankscreen, mainwindow);
Screen('TextSize', mainwindow, 26);
DrawFormattedText(mainwindow, t, 'center', 'center',[],[],[],[],1.5);

if nargin == 4
    Screen('Flip',mainwindow, start_time);
else
    Screen('Flip',mainwindow);
end