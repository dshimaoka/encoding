% EstimateIRF.m
%
% This script estimates the temporal impulse response function by fitting
% impulse response functions to a stimulus time-course and comparing the
% result to real data.  

load impulseResp

% Plot the data 
figure(1)
clf
h(1) = plot(taxis,impulseResp,'k-');

% Define the stimulus as a boxcar lasting 200 msec
stim = zeros(size(taxis));
stim(taxis<=200) = 1;

% Initial parameters.  
p.n = [3,5];        % Number of cascades in the first and second Gamma function (needs to be an integer)
p.k = [22,23];      % time constants (msec)
p.delay = [50,50];  % Delays
p.a = .4;           % Amplitude of second (subtracted) Gamma function 



pBest = fit('fitIRF',p,{'k','delay','a'},stim,taxis,impulseResp);

[err,pred] = fitIRF(pBest,stim, taxis,impulseResp);

hold on
h(2) = plot(taxis,pred,'r-');
legend({'Data','Prediction'});
norm(pred-impulseResp)
xlabel('Time (msec)');

