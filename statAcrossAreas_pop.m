IDs = [1 2 3 8 9];
% labels = 
areaStats_bestSF_pop = cell(numel(labels),1);
areaStats_eccentricity_pop = cell(numel(labels),1);
for iid = 1:5
    ID = IDs(iid);
    ebins = 0:8;
    rescaleFac = 0.1;
    remakeParcellation = 1;
    selectPixelTh = 3;
    if ~isempty(selectPixelTh)
        suffix = '_selected';
    else
        suffix = '';
    end
    
    %% about data
    roiSuffix = '';
    expInfo = getExpInfoNatMov(ID);
    aparam = getAnalysisParam(ID);
    
    dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, aparam.stimSuffix);
    
    encodingSavePrefix = [dataPaths.encodingSavePrefix aparam.regressSuffix];
    saveName = [num2str(ID) '_eccentricity-sigma-sf' suffix];
    
    load(saveName, 'areaStats_bestSF','areaStats_RF_sigma','coef_bestSF','coef_bestSF_bin',...
        'coef_RF_sigma','coef_RF_sigma_bin','mebins','bestSF_bin','RF_sigma_bin');
    
    
    coef_bestSF_bin_pop(iid,:) = coef_bestSF_bin(2,:);
    coef_bestSF_pop(iid,:) = coef_bestSF(2,:);
    coef_RF_sigma_bin_pop(iid,:) = coef_RF_sigma_bin(2,:);
    coef_RF_sigma_pop(iid,:) = coef_RF_sigma(2,:);
    for iroi =1:numel(labels)
        areaStats_bestSF_pop{iroi} = cat(1, areaStats_bestSF_pop{iroi}, areaStats_bestSF.bestSF{iroi});
        areaStats_eccentricity_pop{iroi} = cat(1, areaStats_eccentricity_pop{iroi}, areaStats_bestSF.eccentricity{iroi});
    end
end

%% onse sample = one pixel
for iarea = 1:numel(label)
    plot(areaStats_eccentricity_pop{iarea}, areaStats_bestSF_pop{iarea},'.','color',lcolor(iarea,:));
    hold on;
    %plot(xaxis, coef_bestSF(1,iarea)+coef_bestSF(2,iarea)*xaxis,'color',lcolor(iarea,:));
end

%% pixel density
for iarea = 1:numel(label)
    x = areaStats_eccentricity_pop{iarea};
    y = areaStats_bestSF_pop{iarea};
    Xedges = 0:.5:10;
    Yedges = 0:.2:2;
    subplot(1,numel(label),iarea);
    histogram2(x, y, Xedges, Yedges, 'DisplayStyle','tile','ShowEmptyBins','on','edgecolor','none');
    title(label(iarea));
    if iarea==1
        xlabel('eccentricity [deg]');
        ylabel('SF [cpd]');
    end
end
screen2png('statsAcrossAreas_pop_density');

%% one sample = one hemisphere
for ic = 1:4
    switch ic 
        case 1
            varName = 'coef_bestSF_bin_pop';
        case 2
            varName = 'coef_bestSF_pop';
        case 3
            varName = 'coef_RF_sigma_bin_pop';
        case 4
            varName = 'coef_RF_sigma_pop';
    end
    individual = eval(varName);
    
    subplot(2,2,ic);
    plot(1:6,individual);
    hold on
    errorbar(1:6, nanmean(individual), nanstd(individual),'linewidth',2,'color','k');
    set(gca,'xtick',1:6,'xticklabel',label);
    axis padded;
    title(replace(varName,'_','-'));
end
legend(num2str(IDs'));



