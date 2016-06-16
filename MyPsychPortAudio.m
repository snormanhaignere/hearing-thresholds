function varargout = MyPsychPortAudio(varargin)

max_spl = 105; % max spl allowed
sine_peak_spl = 105; % spl of a sine tone at peak amplitude

switch varargin{1}
    
    case 'FillBuffer'
        
        wav = varargin{3};
        spl = 10*log10(mean(wav(:).^2)) + sine_peak_spl + 20*log10(sqrt(2));
        if spl > max_spl
            error('SPL too high.');
        end
    
    case 'Volume'
        
        vol = varargin{3};
        if vol > 1
            error('Volume cannot be higher than 1.');
        end
        
end

[varargout{1:nargout}] = PsychPortAudio(varargin{:});