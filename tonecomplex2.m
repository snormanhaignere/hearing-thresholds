function [wav, pf] = tonecomplex2(f, pf, dur, sr, varargin)

% function [wav, pf] = tonecomplex2(f, px, dur, sr, varargin)
% 
% Synthesizes a complex composed of pure tones (i.e. sinusoids).
% 
% -- Required Input Arguments --
% 
% f: frequency of each pure tone
% 
% pf: power of each pure tone in dB (i.e. 20*log10(rms(pure_tone))), should either be the same
% dimension as f, or scalar, in which case all frequencies have equal power
% 
% dur: duration of the complex in seconds
% 
% sr: sampling rate
% 
% -- Outputs --
% 
% wav: audio waveform of the complex
% 
% pf: power of each frequency in the complex (can be different from the input power, see optional arguments)
% 
% -- Optional inputs --
% pcomplex: total power of the complex (default: 10*log10(sum(pf)))
% 
% phases: starting phase of each pure tone in radians, i.e. sin(2*pi*t*f + phase_f) (default: 0)
% 
% tf: transforms the spectrum by inverting and interpolating a system transfer function. Useful for
% creating a complex that will have a fixed spectrum after accounting for the transfer function
% of the sound system used to present it. tf is a structure with a frequency field (tf.f) and a
% power field (tf.px) specifying the power in dB SPL produced by a sinusoid of unit power in matlab.
% 
% -- Example harmonic complex with harmonics 1-10 of a 100 Hz F0 --
% f = 100:100:1000;
% pf = log2(f);
% dur = 1;
% sr = 20000;
% wav = tonecomplex2(f, pf, dur, sr, 'pcomplex', -40);
% fftplot2(wav,sr);
% sound_checkvol(wav,sr);
% 
% Last Modified by Sam NH on 6/1/2015

% check all frequencies below nyquist
if any(f>sr/2)
    error('Frequencies above nyquist');
end

% expand scalar to vector
if length(pf) == 1;
    pf = pf*ones(1,length(f));
end

% phase of each frequency
phases = zeros(size(f));
if optInputs(varargin,'phases')
    phases = varargin{optInputs(varargin,'phases')+1};
end

% optionally normalize total power of the complex
if optInputs(varargin,'pcomplex')
    pcomplex = varargin{optInputs(varargin,'pcomplex')+1};
    pf = pf + pcomplex - 10*log10(sum(10.^(pf/10)));
end

% optionally inverts system response
if optInputs(varargin,'tf')
    tf = varargin{optInputs(varargin,'tf')+1};  
    pf = pf - myinterp1(log2(tf.f), tf.px, log2(f), 'pchip');
end

% create the complex
n = round(dur*sr);
t = linspace(0,dur,n+1)';
t = t(1:end-1);
wav = zeros(n,1);
for i = 1:length(f)
    wav = wav + 10^(pf(i)/20) * sqrt(2) * sin(2*pi*f(i)*t + phases(i));
end