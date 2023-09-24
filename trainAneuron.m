function trained = trainAneuron(ds, S_fin, iNeuron, trainIdx,  ridgeParams, ...
    KFolds, lagRange, tavg, useGPU, imageMean, regressType)
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
%imageMean:
%regressType: 'ridge' (default) or 'lasso'

%output
% trained.ridgeParam_optimal
% trained.rre: [delay x variable]
% trained.r0e: intersect (scalar)
% trained.mse: mean-squared error between fitted and observed

%Fs

% 7/5/23 now compatible with lasso regression w regressType = 'lasso'

sanityCheck = 1;
GPUread = 0; %somehow NG in MASSIVE, but works in local PC

%% load neural data
ds_tmp = ds;
%ds_tmp.SelectedVariableNames = {'Time', ['observed_' num2str(iNeuron)]};
if GPUread
    %READ W GPU
    neuroData = tall(ds_tmp);
    observed = gather(neuroData.(['observed_' num2str(iNeuron)]));%slow!!
else
    %READ WO GPU
    neuroData = ds_tmp.readall;
    observed = neuroData.(['observed_' num2str(iNeuron)]);
end

if nargin==10 && ~isempty(imageMean)
    test = observed\imageMean; %regress out by imageMean
    observed = observed - test*imageMean;
end

if nargin < 11
    regressType = 'ridge';
end

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

%% cross val to determine ridgeParameter
if length(ridgeParams) > 1
    mse = zeros(length(ridgeParams),1);
    mse_cvp = zeros(length(ridgeParams),KFolds);
    expval_cvp = zeros(length(ridgeParams),KFolds);
    for rp = 1:length(ridgeParams)
        if strcmp(regressType, 'ridge')
            [mse_cvp(rp,:),~,~,expval_cvp(rp,:)] = ridgeXs_cv(KFolds, timeVec_train, ...
                S_fin_train', observed_train', lagRange, ridgeParams(rp), tavg, useGPU);
        elseif strcmp(regressType, 'lasso')
            [mse_cvp(rp,:),~,~,expval_cvp(rp,:)] = lassoXs_cv(KFolds, timeVec_train, ...
                S_fin_train', observed_train', lagRange, ridgeParams(rp), tavg, useGPU);
        end
        mse(rp) = mean(mse_cvp(rp,:));
    end
    [~,thisIdx]=min(mse);
else
    thisIdx = 1;
    mse_cvp = [];
    expval_cvp = [];
end

%% estimate coef with the optimal ridgeparam
ridgeParam_optimal = ridgeParams(thisIdx);
if strcmp(regressType, 'ridge')
    [rre, r0e, fitted] = ridgeXs(timeVec_train, S_fin_train', ...
        observed_train', lagRange, ridgeParam_optimal, tavg, useGPU);
elseif strcmp(regressType, 'lasso')
    [rre, r0e, fitted] = lassoXs(timeVec_train, S_fin_train', ...
        observed_train', lagRange, ridgeParam_optimal, tavg, useGPU);
end

mse = mean((observed_train - fitted').^2);
expval = 100*(1 - mse / mean((observed_train - mean(observed_train)).^2));
corr_fitted = corrcoef(observed_train, fitted);
corr = corr_fitted(2,1);

if sanityCheck
    ax(1)=subplot(211);
    yyaxis left; plot(timeVec_train,observed_train);
    yyaxis right; plot(timeVec_train,fitted)
    legend('observed','fitted');
    xlim([0 500])
    ax(2)=subplot(212);
    plot(observed_train,fitted,'.');
    xlabel('observed\_train');ylabel('fitted');
    title(['corr ' num2str(corr_fitted(2,1)) ', expval ' num2str(expval)]);
    axis equal square;
    
    % % correlation over time
    %     idx =round(linspace(1,numel(timeVec_train),10));
    % 
    % tiledlayout('flow');
    % corrval = [];
    % for ii=1:numel(idx)-1
    %     nexttile;
    %     cache=corrcoef(observed_train(idx(ii):idx(ii+1)), fitted(idx(ii):idx(ii+1)));
    % 
    %     corrval(ii) = cache(2,1);
    % 
    %     yyaxis left; plot(timeVec_train(idx(ii):idx(ii+1)), observed_train(idx(ii):idx(ii+1)));
    %     yyaxis right; plot(timeVec_train(idx(ii):idx(ii+1)), fitted(idx(ii):idx(ii+1)));
    % end
    %% validating fitting
    %     testIdx = setxor(1:size(S_fin,1),trainIdx);
    %     timeVec_test = timeVec(testIdx);
    %     S_fin_test = single(S_fin(testIdx,:));
    %     predicted = predictXs(timeVec_test, S_fin_test', r0e, rre,...
    %         lagRange, tavg);
    %     observed_test = single(observed(testIdx));
    %     corr_pred = corrcoef(observed_test, predicted);
    %     mse_pred = mean((observed_test - predicted').^2);
    %     expval_pred = 100*(1 - mse_pred / mean((observed_test - mean(observed_test)).^2));
    %
    %     ax(3)=subplot(223);
    %     yyaxis left; plot(observed_test);
    %     yyaxis right; plot(predicted)
    %     legend('observed','predicted');
    %     ax(4)=subplot(224);
    %     plot(observed_test, predicted,'.');
    %     xlabel('observed\_test');ylabel('predicted');
    %     title(['corr ' num2str(corr_pred(2,1)) ', expval ' num2str(expval_pred)]);
    %     axis equal square;
    %     linkaxes([ax(1) ax(3)]);xlim(ax(1),[0 numel(predicted)]);
    %     linkaxes([ax(2) ax(4)]);
    
end

% observed_test = observed(testIdx);
% mse_test = mean((observed_test - predicted').^2);
%plot(timeVec_test, observed_test, timeVec_test, predicted)

%output
trained.ridgeParam_optimal = ridgeParam_optimal;
trained.rre = rre;
trained.r0e = r0e;
trained.mse = mse;
trained.mse_cvp = mse_cvp;
trained.expval_cvp = expval_cvp;
trained.expval = expval;
trained.corr = corr;
