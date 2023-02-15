function trained = trainAneuron(ds, S_fin, iNeuron, trainIdx,  ridgeParams, ...
    KFolds, lagRange, tavg, useGPU)
%trained = trainAneuron(ds, S_fin, iNeuron, trainIdx,  ridgeParams, ...
%     KFolds, lagRange, tavg, useGPU)

%INPUT
%ds: observed traces
%S_fin:
%iNeuron:
%trainIdx:
%ridgeParams:
%KFolds:
%lagRange: frame numbers used for training [min max] positive<>activity after stim
%tavg: if true, train using avg activity during lagRange
%useGPU:

%output
% trained.ridgeParam_optimal
% trained.rre: [delay x variable]
% trained.r0e: intersect (scalar)
% trained.mse: mean-squared error between fitted and observed

%Fs


%% load neural data
ds_tmp = ds;
ds_tmp.SelectedVariableNames = {'Time', ['observed_' num2str(iNeuron)]};
neuroData = tall(ds_tmp);
observed = gather(neuroData.(['observed_' num2str(iNeuron)]));%slow!!
observed_train = single(observed(trainIdx));

S_fin_train = single(S_fin(trainIdx,:));

thisTimeVec = gather(neuroData.Time);%this is an cell aray with 'sec' suffix
timeVec = single(zeros(length(thisTimeVec),1));
for tt = 1:length(thisTimeVec)
    timeVec(tt) = str2num(thisTimeVec{tt}(1:end-4));
end
timeVec_train = timeVec(trainIdx);
%thisTimeVec = gather(neuroData.Time);%this is an cell aray with 'sec' suffix
%timeVec_train = single(1/Fs*(1:size(observed_train))'); %hack for now
%timeVec_test = single(1/Fs*(1:length(testIdx)));

%% cross val to determine ridgeParameter
if length(ridgeParams) > 1
    mse = zeros(length(ridgeParams),1);
    for rp = 1:length(ridgeParams)
        mse_cvp = ridgeXs_cv(KFolds, timeVec_train, ...
            S_fin_train', observed_train', lagRange, ridgeParams(rp), tavg, useGPU);
        mse(rp) = mean(mse_cvp);
    end
    [~,thisIdx]=min(mse);
else
    thisidx = 1;
end

%% estimate coef with the optimal ridgeparam
ridgeParam_optimal = ridgeParams(thisIdx);
[rre, r0e, fitted] = ridgeXs(timeVec_train, S_fin_train', ...
    observed_train', lagRange, ridgeParam_optimal, tavg, useGPU);

mse = mean((observed_train - fitted').^2);
%       plot(timeVec_train, observed_train, timeVec_train, fitted);

%% validating fitting
% predicted = predictXs(timeVec_test, S_fin_test', r0e, rre,...
%     lagRange, tavg);
% observed_test = observed(testIdx);
% mse_test = mean((observed_test - predicted').^2);
%plot(timeVec_test, observed_test, timeVec_test, predicted)

%output
trained.ridgeParam_optimal = ridgeParam_optimal;
trained.rre = rre;
trained.r0e = r0e;
trained.mse = mse;
% trained.mse_test = mse_test;
