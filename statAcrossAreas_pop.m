ebins = 0:8;
rescaleFac = 0.1;
remakeParcellation = 1;
selectPixelTh = 6;
eccTh = 3; %[deg]
spdlim = [0.1 15];
if ~isempty(selectPixelTh)
    suffix = '_selected';
else
    suffix = '';
end

IDs = [1 2 3 8 9];
label{1} = 'V1';
label{2} = 'V2';
label{3} = 'DM';
label{4} = 'V3';
label{5} = 'V4';
label{6} = 'DI';
tgtROIs = 1:5;

label = label(tgtROIs);
lcolor = lines(numel(label));

areaStats_bestSF_pop = cell(numel(label),1);
areaStats_eccentricity_pop = cell(numel(label),1);
areaStats_bestTF_pop = cell(numel(label),1);
areaStats_RF_sigma_pop = cell(numel(label),1);
areaStats_bestSPD_pop = cell(numel(label),1);
for iid = 1:numel(IDs)
    ID = IDs(iid);
    
    
    %% about data
    roiSuffix = '';
    expInfo = getExpInfoNatMov(ID);
    aparam = getAnalysisParam(ID);
    
    dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, aparam.stimSuffix);
    
    encodingSavePrefix = [dataPaths.encodingSavePrefix aparam.regressSuffix];
    load([encodingSavePrefix '_summary'],'summary_adj');
    
    saveName = fullfile('C:\Users\dshi0006\git\encoding\statsAcrossAreas',[num2str(ID) '_eccentricity-sigma-sf' suffix]);
    load(saveName, 'areaMatrix');
    
    %% stats per area
    [areaStats_bestSF, excPerc_bestSF] = getAreaStats(summary_adj, areaMatrix(tgtROIs), 'bestSF', selectPixelTh);
    [areaStats_bestTF,excPerc_bestTF] = getAreaStats(summary_adj, areaMatrix(tgtROIs), 'bestTF', selectPixelTh);
    summary_adj.bestSPD = summary_adj.bestTF./summary_adj.bestSF;
    [areaStats_bestSPD, excPerc_bestSPD] = getAreaStats(summary_adj, areaMatrix(tgtROIs), 'bestSPD', selectPixelTh);
    areaStats_RF_sigma = getAreaStats(summary_adj, areaMatrix(tgtROIs), 'RF_sigma', selectPixelTh);
    
    %% robust linear fitting vs eccentricity
    [bestSF_bin, coef_bestSF_bin, npix_bestSF_bin, mebins, ste_bestSF_bin] = fitByEccentricityBin(ebins, areaStats_bestSF, 'bestSF');
    [bestTF_bin, coef_bestTF_bin, npix_bestTF_bin, mebins, ste_bestTF_bin] = fitByEccentricityBin(ebins, areaStats_bestTF, 'bestTF');
    [bestSPD_bin, coef_bestSPD_bin, npix_bestSPD_bin, mebins, ste_bestSPD_bin] = fitByEccentricityBin(ebins, areaStats_bestSPD, 'bestSPD');
    [RF_sigma_bin, coef_RF_sigma_bin, npix_RF_sigma_bin, mebins, ste_RF_sigma_bin] = fitByEccentricityBin(ebins, areaStats_RF_sigma, 'RF_sigma');
    
    [coef_bestSF] = fitByEccentricity(areaStats_bestSF, 'bestSF');
    [coef_bestTF] = fitByEccentricity(areaStats_bestTF, 'bestTF');
    [coef_bestSPD] = fitByEccentricity(areaStats_bestSPD, 'bestSPD');
    [coef_RF_sigma] = fitByEccentricity(areaStats_RF_sigma, 'RF_sigma');

    mean_bestSF_pop(iid,:,1)= nanmean(bestSF_bin(mebins<eccTh,:),1);
    mean_bestSF_pop(iid,:,2)= nanmean(bestSF_bin(mebins>=eccTh,:),1);
    mean_bestTF_pop(iid,:,1)= nanmean(bestTF_bin(mebins<eccTh,:),1);
    mean_bestTF_pop(iid,:,2)= nanmean(bestTF_bin(mebins>=eccTh,:),1);
    mean_bestSPD_pop(iid,:,1)= nanmean(bestSPD_bin(mebins<eccTh,:),1);
    mean_bestSPD_pop(iid,:,2)= nanmean(bestSPD_bin(mebins>=eccTh,:),1);
    mean_RF_sigma_pop(iid,:,1)= nanmean(RF_sigma_bin(mebins<eccTh,:),1);
    mean_RF_sigma_pop(iid,:,2)= nanmean(RF_sigma_bin(mebins>=eccTh,:),1);

    excPerc_bestSF_pop(iid,:) = excPerc_bestSF;
    excPerc_bestTF_pop(iid,:) = excPerc_bestTF;
    excPerc_bestSPD_pop(iid,:) = excPerc_bestSPD;

    coef_bestSF_bin_pop(iid,:) = coef_bestSF_bin(2,:);
    coef_bestSF_pop(iid,:) = coef_bestSF(2,:);
    coef_RF_sigma_bin_pop(iid,:) = coef_RF_sigma_bin(2,:);
    coef_RF_sigma_pop(iid,:) = coef_RF_sigma(2,:);
    
    coef_bestTF_bin_pop(iid,:) = coef_bestTF_bin(2,:);
    coef_bestTF_pop(iid,:) = coef_bestTF(2,:);
    coef_bestSPD_bin_pop(iid,:) = coef_bestSPD_bin(2,:);
    coef_bestSPD_pop(iid,:) = coef_bestSPD(2,:);
    
    RF_sigma_bin_pop(iid,:,:) = RF_sigma_bin;
    bestSF_bin_pop(iid,:,:) = bestSF_bin;
    bestTF_bin_pop(iid,:,:) = bestTF_bin;
    bestSPD_bin_pop(iid,:,:) = bestSPD_bin;

    npix_RF_sigma_bin_pop(iid,:,:) = npix_RF_sigma_bin;
    npix_bestSF_bin_pop(iid,:,:) = npix_bestSF_bin;
    npix_bestTF_bin_pop(iid,:,:) = npix_bestTF_bin;
    npix_bestSPD_bin_pop(iid,:,:) = npix_bestSPD_bin;

    ste_bestSF_bin_pop(iid,:,:) = ste_bestSF_bin;
    ste_bestTF_bin_pop(iid,:,:) = ste_bestTF_bin;
    ste_bestSPD_bin_pop(iid,:,:) = ste_bestSPD_bin;
    ste_RF_sigma_bin_pop(iid,:,:) = ste_RF_sigma_bin;

    for iroi =1:numel(label)
        areaStats_RF_sigma_pop{iroi} = cat(1, areaStats_RF_sigma_pop{iroi}, areaStats_RF_sigma.RF_sigma{iroi});
        areaStats_bestSF_pop{iroi} = cat(1, areaStats_bestSF_pop{iroi}, areaStats_bestSF.bestSF{iroi});
        areaStats_bestTF_pop{iroi} = cat(1, areaStats_bestTF_pop{iroi}, areaStats_bestTF.bestTF{iroi});
        areaStats_bestSPD_pop{iroi} = cat(1, areaStats_bestSPD_pop{iroi}, areaStats_bestSPD.bestSPD{iroi});
        areaStats_eccentricity_pop{iroi} = cat(1, areaStats_eccentricity_pop{iroi}, areaStats_bestSF.eccentricity{iroi});
    end
end

%% one sample = one hemisphere
% cfig = figure('position',[0 0 1440 800]);
% for imodality = 1:8
%     switch imodality
%         case 1
%             varName = 'coef_RF_sigma_pop';
%         case 2
%             varName = 'coef_bestSF_pop';
%         case 3
%             varName = 'coef_bestTF_pop';
%         case 4
%             varName = 'coef_bestSPD_pop';
%         case 5
%             varName = 'coef_RF_sigma_bin_pop';
%         case 6
%             varName = 'coef_bestSF_bin_pop';
%         case 7
%             varName = 'coef_bestTF_bin_pop';
%         case 8
%             varName = 'coef_bestSPD_bin_pop';
%     end
%     loadedMetric = eval(varName); %hem x area
%     theseValues = squeeze(mean(loadedMetric,1));
%     [p, tbl, stats] = kruskalwallis(loadedMetric);
%     close;    
%     [c,~,~,gnames] = multcompare(stats);
%     close;
%     
%     set(0,'CurrentFigure', cfig);
%     
%     subplot(2,4,imodality);
%     bar(1:numel(tgtROIs), nanmean(loadedMetric),'facecolor',[.5 .5 .5]);hold on
%     %pp=plot(1:numel(tgtROIs),individual', '.');
%     hold on
%     err=errorbar(1:numel(tgtROIs), nanmean(loadedMetric), ...
%         nanste(loadedMetric),'linewidth',1,'color','k');
%     err.Color = [0 0 0];
%     err.LineStyle = 'none';
%     addSignStar(gca, c);
%     set(gca,'xtick',1:numel(tgtROIs),'xticklabel',label,'tickdir','out');
%     axis padded;
%     title(replace(varName,'_','-'));
% end
% %legend(pp,num2str(IDs'));
% savePaperFigure(cfig,'statsAcrossAreas_pop_bin');
% 

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
%     for iarea = 1:numel(label)
%         x = areaStats_eccentricity_pop{iarea};
%         y = varName{iarea};
%         Xedges = 0:.5:10;
%         Yedges = 0:.2:2;
%         subplot(4,numel(label),iarea + numel(label)*(imodality-1));
%         histogram2(x, y, Xedges, Yedges, 'DisplayStyle','tile','ShowEmptyBins','on','edgecolor','none');
%         title(label(iarea));
%         if iarea==1
%             xlabel('eccentricity [deg]');
%             ylabel(num2str(varName(11:end-4)));
%         end
%     end
% end
% screen2png('statsAcrossAreas_pop_density');

%% central v periphery
cfig = figure('position',[0 0 1440 300]);
for imodality = 1:4
    switch imodality
        case 1
            metric = 'RF_sigma';
        case 2
            metric = 'bestSF';
        case 3
            metric = 'bestTF';
        case 4
            metric = 'bestSPD';
    end
    loadedMetric = eval(['mean_' metric '_pop']);
    npixMetric = eval(['npix_' metric '_bin_pop']);
    theseValues = squeeze(nanmean(loadedMetric,1));
    
    [p, tbl, stats] = kruskalwallis(squeeze(loadedMetric(:,:,2)));close;
    [c,~,~,gnames] = multcompare(stats);close;
    
    set(0,'CurrentFigure', cfig) 
    subplot(1,4,imodality);
    bar(1:numel(label), theseValues);hold on
    for jjj=1:2
        err=errorbar(repmat((1:numel(label))+0.3*(jjj-1)-0.15, [1 1]), ...
            nanmean(loadedMetric(:,:,jjj)), ...
            nanste(loadedMetric(:,:,jjj)),'linewidth',1,'color','k');
        err.Color = [0 0 0];
        err.LineStyle = 'none';
    end
    addSignStar(gca, c);
    set(gca,'xticklabel',label,'tickdir','out');
    ylabel(metric);
    if imodality==2
        legend('central','periphery');
    end
end
savePaperFigure(cfig,['statsAcrossAreas_pop_mean_selectPix' num2str(selectPixelTh)]);

% cfig = figure('position',[0 0 1440 300]);
% for imodality = 1:4
%     switch imodality
%         case 1
%             metric = 'RF_sigma';
%         case 2
%             metric = 'bestSF';
%         case 3
%             metric = 'bestTF';
%         case 4
%             metric = 'bestSPD';
%     end
%     
%     loadedMetric = eval(['coef_' metric '_pop']); %hemisphere x area
%     theseValues = squeeze(mean(loadedMetric,1));
%     [p, tbl, stats] = kruskalwallis(loadedMetric);
%     [c,~,~,gnames] = multcompare(stats);
% 
%     set(0,'CurrentFigure', cfig)
%     subplot(1,4,imodality);
%     bar(1:numel(label), theseValues);
% %     err=errorbar(1:numel(label), nanmedian(loadedMetric), ...
% %         nanste(loadedMetric),'linewidth',1,'color','k');
% %     err.Color = [0 0 0];
% %     err.LineStyle = 'none';
%     
%     addSignStar(gca, c);
%     set(gca,'xticklabel',label,'tickdir','out');
%     ylabel(metric);
%     
% end
% screen2png(['statsAcrossAreas_pop_slope_selectPix' num2str(selectPixelTh)], cfig);

%% ecc v metric all animals
figure('position',[0 0 1440 300]);
for imodality = 1:4
    switch imodality
        case 1
            metric = 'RF_sigma';
        case 2
            metric = 'bestSF';
        case 3
            metric = 'bestTF';
        case 4
            metric = 'bestSPD';
    end
    theseValues = eval([metric '_bin_pop']);

    subplot(1,4,imodality); 
    errorbar(repmat(mebins',[1 numel(label)]), squeeze(nanmean(theseValues, 1)), ...
        squeeze(nanste(theseValues)));
    vline(eccTh);
    set(gca,'tickdir','out');
    %plot(mebins', squeeze(nanmedian(theseValues, 1)),'linewidth',2);
    ylabel(metric);
    if imodality==4
        set(gca,'yscale','log','ylim',spdlim);
        legend(label,'location','northwest');
    end
    
%     subplot(2,4,imodality+4);
%     imagesc(mebins,1:numel(tgtROIs), squeeze(nanmedian(theseValues, 1))');
%     set(gca,'yticklabel',label,'tickdir','out');    
end
savePaperFigure(gcf,['statsAcrossAreas_pop_meanHems_selectPix' num2str(selectPixelTh)]);


%% statistical test with limited eccentricity bins
theseBins = 4:6; %mebins>=eccTh
a=bestSPD_bin_pop(:,theseBins,1);%v1
b=bestSPD_bin_pop(:,theseBins,3);%dm
p=signrank(a(:),b(:))

%% percent of excluded pixels
mean([excPerc_bestSPD_pop(:); excPerc_bestSF_pop(:); excPerc_bestTF_pop(:)])





