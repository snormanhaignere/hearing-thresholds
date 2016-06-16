function y = ramp(x,dur,sr)

len = size(x,1);

timeforward = (1:len)'/sr;
timereverse = flipdim(timeforward,1);
linramp = ones(size(x,1),1);
linramp(timeforward<dur) = timeforward(timeforward<dur)/dur;
linramp(timereverse<dur) = timereverse(timereverse<dur)/dur;

y = x.*repmat(linramp,1,size(x,2));