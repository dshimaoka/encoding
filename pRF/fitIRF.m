function [err,pred] = fitIRF(p,stim, taxis,impulseResp)
% [err,pred] = fitIRF(p,stim, taxis,impulseResp)
%
% Written by G.M. Boynton, University of Washington, Summer 2015

% Calculate impulse response function, I, which is a difference of gammas:
I = gammaPDF(p.n(1),p.k(1),taxis-p.delay(1)) - ...
p.a*gammaPDF(p.n(2),p.k(2),taxis-p.delay(2));

% Convolve with the stimulus
pred = conv(stim,I);
pred = pred(1:length(taxis));  %truncate to origintal length

% Divide by 'dt'
pred = pred*(taxis(2)-taxis(1));
%pred = pred/max(pred);  

err = norm(pred-impulseResp);