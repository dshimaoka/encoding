IDs = [1 2 3 8 9];
label{1} = 'V1';
label{2} = 'V2';
label{3} = 'DM';
label{4} = 'V3';
label{5} = 'V4';
label{6} = 'DI';
lcolor = lines(numel(label));

areaStats_bestSF_pop = cell(numel(label),1);
areaStats_eccentricity_pop = cell(numel(label),1);
areaStats_bestTF_pop = cell(numel(label),1);
areaStats_RF_sigma_pop = cell(numel(label),1);
areaStats_bestSPD_pop = cell(numel(label),1);
for iid = 1:numel(IDs)
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
    saveName = fullfile('statsAcrossAreas',[num2str(ID) '_eccentricity-sigma-sf' suffix]);
    
    load(saveName, 'areaStats_bestSF','areaStats_RF_sigma','coef_bestSF','coef_bestSF_bin',...
        'coef_RF_sigma','coef_RF_sigma_bin','mebins','bestSF_bin','RF_sigma_bin',...
        'coef_bestTF_bin','coef_bestTF','coef_bestSPD_bin','coef_bestSPD');
    
    
    coef_bestSF_bin_pop(iid,:) = coef_bestSF_bin(2,:);
    coef_bestSF_pop(iid,:) = coef_bestSF(2,:);
    coef_RF_sigma_bin_pop(iid,:) = coef_RF_sigma_bin(2,:);
    coef_RF_sigma_pop(iid,:) = coef_RF_sigma(2,:);
    
    coef_bestTF_bin_pop(iid,:) = coef_bestTF_bin(2,:);
    coef_bestTF_pop(iid,:) = coef_bestTF(2,:);
    coef_bestSPD_bin_pop(iid,:) = coef_bestSPD_bin(2,:);
    coef_bestSPD_pop(iid,:) = coef_bestSPD(2,:);
    
    for iroi =1:numel(label)
        areaStats_RF_sigma_pop{iroi} = cat(1, areaStats_RF_sigma_pop{iroi}, areaStats_RF_sigma.RF_sigma{iroi});
        areaStats_bestSF_pop{iroi} = cat(1, areaStats_bestSF_pop{iroi}, areaStats_bestSF.bestSF{iroi});
        areaStats_bestTF_pop{iroi} = cat(1, areaStats_bestTF_pop{iroi}, areaStats_bestTF.bestTF{iroi});
        areaStats_bestSPD_pop{iroi} = cat(1, areaStats_bestSPD_pop{iroi}, areaStats_bestSPD.bestSPD{iroi});
        areaStats_eccentricity_pop{iroi} = cat(1, areaStats_eccentricity_pop{iroi}, areaStats_bestSF.eccentricity{iroi});
    end
end

%% one sample = one hemisphere
figure('position',[0 0 1440 800]);
for imodality = 1:8
    switch imodality
        case 1
            varName = 'coef_RF_sigma_pop';
        case 2
            varName = 'coef_bestSF_pop';
        case 3
            varName = 'coef_bestTF_pop';
        case 4
            varName = 'coef_bestSPD_pop';
        case 5
            varName = 'coef_RF_sigma_bin_pop';
        case 6
            varName = 'coef_bestSF_bin_pop';
        case 7
            varName = 'coef_bestTF_bin_pop';
        case 8
            varName = 'coef_bestSPD_bin_pop';
    end
    individual = eval(varName);
    
    subplot(2,4,imodality);
    bar(1:6, nanmean(individual))
    plot(1:6,individual, '.');
    hold on
    err=errorbar(1:6, nanmean(individual), nanste(individual),'linewidth',1,'color','k');
    err.Color = [0 0 0];
    err.LineStyle = 'none';
    set(gca,'xtick',1:6,'xticklabel',label);
    axis padded;
    title(replace(varName,'_','-'));
end
legend(num2str(IDs'));
screen2png('statsAcrossAreas_pop_bin');


%% onse sample = one pixel
% figure('position',[0 0 1440 800]);
% for imodality = 1:4
%     switch imodality
%         case 1
%             varName = areaStats_RF_sigma_pop;
%         case 2
%             varName = areaStats_bestSF_pop;
%         case 3
%             varName = areaStats_bestTF_pop;
%         case 4
%             varName = areaStats_bestSPD_pop;
%     end
%     
%     subplot(4,1,imodality);
%     for iarea = 1:numel(label)
%         plot(areaStats_eccentricity_pop{iarea}, varName{iarea},'.','color',lcolor(iarea,:));
%         hold on;
%         %plot(xaxis, coef_bestSF(1,iarea)+coef_bestSF(2,iarea)*xaxis,'color',lcolor(iarea,:));
%          if iarea==1
%             xlabel('eccentricity [deg]');
%             ylabel(num2str(varName(11:end-4)));
%         end
%     end
% end

%% pixel density
figure('position',[0 0 1440 800]);
for imodality = 1:4
    switch imodality
        case 1
            varName = areaStats_RF_sigma_pop;
        case 2
            varName = areaStats_bestSF_pop;
        case 3
            varName = areaStats_bestTF_pop;
        case 4
            varName = areaStats_bestSPD_pop;
    end
    
    for iarea = 1:numel(label)
        x = areaStats_eccentricity_pop{iarea};
        y = varName{iarea};
        Xedges = 0:.5:10;
        Yedges = 0:.2:2;
        subplot(4,numel(label),iarea + numel(label)*(imodality-1));
        histogram2(x, y, Xedges, Yedges, 'DisplayStyle','tile','ShowEmptyBins','on','edgecolor','none');
        title(label(iarea));
        if iarea==1
            xlabel('eccentricity [deg]');
            ylabel(num2str(varName(11:end-4)));
        end
    end
end
screen2png('statsAcrossAreas_pop_density');

    
    
    
