function [px_one_sided, f] = fftplot2(wav,sr,varargin)

fontsize = 12;
fontweight = 'Demi';

% column vector
if size(wav,2) ~= 1;
    wav = transpose(wav);
end
if size(wav,2) ~= 1
    error('fftplot2 expects a single row or column vector');
end

% fft size
nfft = length(wav);
if optInputs(varargin, 'nfft')
    nfft = round(varargin{optInputs(varargin, 'nfft')+1});
end

% input matrix if length(wav) > nfft
if length(wav) > nfft % divide the input into a matrix of non-overlapping vectors 
    n_full_columns = floor(length(wav)/nfft);
    wav_matrix = reshape(wav(1:nfft*n_full_columns), nfft, n_full_columns);
    n_remaining_samples = rem(length(wav),nfft);
    if n_remaining_samples ~= 0 % zero pad if necessary
        last_column = [wav((1:n_remaining_samples) + nfft*n_full_columns); zeros(nfft-n_remaining_samples,1)];
        wav_matrix = [wav_matrix, last_column];
    end
    n_nonzero_samples = n_full_columns*nfft + n_remaining_samples;
elseif length(wav) < nfft % zero pad
    wav_matrix = [wav; zeros(nfft-length(wav),1)];
    n_nonzero_samples = length(wav);
else
    wav_matrix = wav;
    n_nonzero_samples = length(wav);
end

% fft normalized appropriately to satisfy parseval's theorem
% summed across multiple columns if present
px = sum(abs(fft(wav_matrix)).^2 / nfft, 2);

% normalized by the number of samples
% this gives the magnitude spectrum in power per frequency bin per sample
% which is the spectrum level if nfft == sr
px_per_sample = px / n_nonzero_samples;

% maximum positive frequency in samples, the nyquist if nfft is even
% if nfft is 4, frequencies of the dft are 2*pi*[0, 1, 2, 3]/4
% in which case the third sample is the nyquist
% if nfft is 5, then the frequencies of the dft are 2*pi*[0, 1, 2, 3, 4]/5
% in this case, third sample is the maximum positive frequency but not the nyquist
max_pos_freq = ceil((nfft+1)/2); 

% remove negative frequencies while preserving total power
if mod(nfft,2)==0 % if nyquist present
    px_one_sided = [px_per_sample(1); 2*px_per_sample(2:max_pos_freq-1); px_per_sample(max_pos_freq)];
else
    px_one_sided = [px_per_sample(1); 2*px_per_sample(2:max_pos_freq)];
end

% frequency vector in Hz
f = sr*(0:max_pos_freq-1)/nfft;

% add transfer function if specified
if optInputs(varargin,'tf');
    tf = varargin{optInputs(varargin, 'tf')+1};
    gain = myinterp1(log2(tf.f), tf.px, log2(f(2:end)), 'cubic')';
    px_one_sided(2:end) = px_one_sided(2:end) .* 10.^(gain/10);
end

if optInputs(varargin, 'noplot')
    return;
end

% plot spectrum level
% bin_width_in_Hz = sr/nfft;
semilogx(f(:),10*log10(px_one_sided), 'k','LineWidth',1);
% set(gca,'XTick',logspace(1,4,4),'FontWeight',fontweight,'FontSize',fontsize);
% xlim([20 10000]);
if optInputs(varargin, 'tf')
    ylim([20 80]);
end
% ylim(max(10*log10(px)) + [-70 10]);