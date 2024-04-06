function [mse, rre_cvp, r0e_cvp, expval] = lassoXs_cv(KFolds, timeVec, stim_is, observed, ...
    lagRange, ridgeParam, tavg, useGPU, verbose)
% [mse, rre_cvp, r0e_cvp] = ridgeXs_cv(KFolds, timeVec, stim_is, observed, ...
%     lagRange, ridgeParam, tavg)
% 
% INPUT
% KFolds:
% timeVec
% stim_is: [variables x time]
% observed: [1 x time]
% lagRange
% ridgeParam
% tavg: whether to use temporal averaging for regression
%
% OUTPUT
% mse: mean squared error between observed and predicted
% rre_cvp: [nLags x nVar x KFolds]
% r0e_cvp
% expvar: explained variance by the model, averaged across kfolds

if nargin < 9
    verbose = 0;
end

if nargin < 8
    useGPU = 0;
end

if nargin < 7
    tavg = 0;
end


if size(stim_is,1) > size(stim_is,2)
    stim_is = stim_is';
end
if size(observed,1) > size(observed,2)
    observed = observed';
end
    
%cvp = cvpartition(length(timeVec),'KFold',KFolds); <cannot use because
%samples are randomly sampled in time
nSamples = length(timeVec);
Sub = [round(linspace(0,nSamples,KFolds+1)) nSamples];
cvp.test = cell(KFolds,1);
cvp.training = cell(KFolds,1);
for fold=1:KFolds
    theseSub = logical(zeros(nSamples,1));
    theseSub(Sub(fold)+1:Sub(fold+1)) = 1;
    cvp.test{fold} = theseSub;
    cvp.training{fold} = logical(1 - cvp.test{fold});
end

nVar = size(stim_is, 1);
fs = 1/median(diff(timeVec));
%lagRange = [min(lagFrames)/Fs max(lagFrames)/Fs];%lag range provided as rr
lags = round(lagRange(1)*fs):round(lagRange(2)*fs);
nLags = length(lags);

if tavg
    rre_cvp = zeros(1, nVar, KFolds);
else
    rre_cvp = zeros(nLags, nVar, KFolds);
end
r0e_cvp = zeros(KFolds,1);
for fold = 1:KFolds
    if verbose
        disp(['lassoXs_cv: ' num2str(fold) '/' num2str(KFolds) 'folds']);
    end
    
    %training
    [rre_cvp(:,:,fold), r0e_cvp(fold)] = ...
        lassoXs(timeVec(cvp.training{fold}), stim_is(:,cvp.training{fold}),...
        observed(cvp.training{fold}), lagRange, ridgeParam, tavg, useGPU);
    
    %validation
    [predicted] = predictXs(timeVec(cvp.test{fold}), stim_is(:,cvp.test{fold}), ...
        r0e_cvp(fold), rre_cvp(:,:,fold), lagRange, tavg);
    mse(fold) = mean((observed(cvp.test{fold}) - predicted).^2);
    expval(fold) = 100*(1 - mse(fold) / mean((observed(cvp.test{fold})- mean(observed(cvp.test{fold}))).^2));

%     subplot(211);
%     plot(timeVec(cvp.training{fold}),observed(cvp.training{fold}),...
%         timeVec(cvp.training{fold}),fitted);
%     title('trained');
%     subplot(212);
%     plot(timeVec(cvp.test{fold}),observed(cvp.test{fold}),...
%         timeVec(cvp.test{fold}),predicted);
%     title('tested');
    
end
% [~, thisFold] = min(mse);
% rre(:,:,iNeuron) = rre_cvp(:,:,thisFold);
% r0e(iNeuron) = r0e_cvp(thisFold);