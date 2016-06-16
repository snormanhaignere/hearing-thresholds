function writeheader(fid,header,formatstring,varargin)

    
x = regexprep(formatstring,'[df]','s');
y = regexprep(x,'\.\d','');
z = regexp(y,'\%[\-\w\.]*','match');

for j = 1:length(z)
    fprintf(fid, z{j}, header{j});
    if optInputs(varargin,'command')
        fprintf(z{j}, header{j});
    end
end

fprintf(fid,'\n');
if optInputs(varargin,'command')
    fprintf('\n');
end


