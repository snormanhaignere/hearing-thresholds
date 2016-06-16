function outputfile = fileplus(inputfile)

% function fileplus = file_addplus(file)
% 
% If input file alrealdy exists, this function returns a file with a plus appended
% to the end of the file, e.g. file+.extension.
% If file+.extension also exists, it returns file++.extension etc..
% Useful for not overwriting files.
% 
% File should only have one '.' and it should indicate the proper extension

% prevents overwriting
while 1
    if exist(inputfile,'file');
        s = regexp(inputfile,'[.]','split');
        if length(s)==1
            inputfile = [inputfile '+']; %#ok<AGROW>
        else
            inputfile = [s{1} '+.' s{2}];
        end        
    else
        outputfile = inputfile;
        break;
    end
end


