asparam = getAreaStatsParam;

%% parmaeters
IDs = 2;%[1 2 3 8 9];
for iidx = 1:numel(IDs)
    ID = IDs(iidx);
    asparam.ebins = 0:8;
    rescaleFac = 0.1;
    remakeParcellation = 0;
 
    if ~isempty(asparam.selectPixelTh)
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
    saveName = fullfile('C:\Users\dshi0006\git\encoding\statsAcrossAreas',[num2str(ID) '_eccentricity-sigma-sf' suffix]);
    
    load([encodingSavePrefix '_summary'],'summary_adj');
    
    if remakeParcellation
        %% labels for corresponding areas
        lcolor = lines(numel(asparam.label));
        
        
        %% show composite map (under construction)
        %summary_adj.mask = summary_adj.mask .* (summary_adj.correlation>aparam.corrth);
        [fig, signMap, signBorder, CyBorder, mask] = showCompositeMap(summary_adj, aparam.corrth, ...
            aparam.showXrange, aparam.showYrange, rescaleFac);
        figure(fig);line([45 45],[55 55+getPixPerMm(rescaleFac)], 'linewidth',2); %addScaleBar(rescaleFac);
        savePaperFigure(fig,[encodingSavePrefix '_compositeMap']);
        close all;
        
        %% find region coding upper visual field for DM
        figure;
        [~, CyBorder_DM] = ...
            findConnectedPixels(CyBorder,'upper vf for DM');
        close;
        
        %% find connected pixels
        connectedPixels = [];
        for ii = 1:5
            switch ii
                case 1
                    asparam.label_obs{ii} = 'V1';
                case 2
                    asparam.label_obs{ii} = 'V2-DM+';
                case 3
                    asparam.label_obs{ii} = 'DM-';
                case 4
                    asparam.label_obs{ii} = 'V3-DI'; %ID2 has split V3
                case 5
                    asparam.label_obs{ii} = 'V4';
            end
            figure;
            [connectedPixels{ii}, connectedMatrix{ii}] = ...
                findConnectedPixels(signBorder,...
                asparam.label_obs{ii});
            close;
        end
        %% matrix representation of V1,V4
        areaMatrix{1} = imfill(connectedMatrix{1}.*mask==1, 'holes');
        areaMatrix{5} = imfill(connectedMatrix{5}.*mask==1, 'holes');
        
        %% split V2 and DM+
        DMp = ((connectedMatrix{2}==1)+ (CyBorder_DM==1)==2);
        areaMatrix{2} = imfill((((connectedMatrix{2}==1)+(DMp~=1))==2).*mask==1, 'holes');
        
        %% combine DM+ and DM-
        areaMatrix{3} = imfill(((connectedMatrix{3}==1)+(DMp==1)).*mask==1, 'holes');
        
        %% split V3 and DI (9/11/2023)
        DI = ((connectedMatrix{4}==1)+ (CyBorder_DM==1)==2);
        areaMatrix{4} = imfill((((connectedMatrix{4}==1)+(DI~=1))==2).*mask==1, 'holes');
        areaMatrix{6} = imfill((((connectedMatrix{4}==1)+(DI==1))==2).*mask==1, 'holes');
        
        
        %% show results of asparam.labeling
        for iarea = 1:numel(asparam.label)
            contourf(areaMatrix{iarea},[.5 .5], 'facecolor',lcolor(iarea,:));
            hold on;
            [r, c] = find(areaMatrix{iarea} == 1);
            text(mean(c), mean(r), asparam.label{iarea});
        end
        axis ij equal;
        screen2png([num2str(ID) '_roi']);
        save(saveName,'areaMatrix','asparam.label','lcolor');
        
    else
        %copyfile([saveName '_selected.mat'],[saveName '.mat']);
        load(saveName,'areaMatrix','asparam.label','lcolor');
        %     load([encodingSavePrefix '_parcelledArea'],'areaMatrix','asparam.label','lcolor');
    end
    
    %% represent in cortical surface
    ecImage = nan(size(summary_adj.mask));
    sfImage = nan(size(summary_adj.mask));
    tfImage = nan(size(summary_adj.mask));
    spdImage = nan(size(summary_adj.mask));
    sigmaImage = nan(size(summary_adj.mask));
    for iarea = 1:numel(asparam.label)
        theseSub = (areaMatrix{iarea}==1);
        sfImage(theseSub) = summary_adj.bestSFF(theseSub);
        tfImage(theseSub) = summary_adj.bestTF(theseSub);
        spdImage(theseSub) = tfImage(theseSub)./sfImage(theseSub);
        sigmaImage(theseSub) = summary_adj.RF_sigma(theseSub);
        ecImage(theseSub) = sqrt(summary_adj.RF_Cx(theseSub).^2 + summary_adj.RF_Cy(theseSub).^2);
    end
    
    
    %% stats per area
    areaStats_bestSF = getAreaStats(summary_adj, areaMatrix, 'bestSF', asparam.selectPixelTh);
    areaStats_bestTF = getAreaStats(summary_adj, areaMatrix, 'bestTF', asparam.selectPixelTh);
    summary_adj.bestSPD = summary_adj.bestTF./summary_adj.bestSF;
    areaStats_bestSPD = getAreaStats(summary_adj, areaMatrix, 'bestSPD', asparam.selectPixelTh);
    areaStats_RF_sigma = getAreaStats(summary_adj, areaMatrix, 'RF_sigma', asparam.selectPixelTh);
    
    %% robust linear fitting vs eccentricity
    [bestSF_bin, coef_bestSF_bin, npix_bestSF_bin, masparam.ebins, ste_bestSF_bin] = fitByEccentricityBin(asparam.ebins, areaStats_bestSF, 'bestSF');
    [bestTF_bin, coef_bestTF_bin, npix_bestTF_bin, masparam.ebins, ste_bestTF_bin] = fitByEccentricityBin(asparam.ebins, areaStats_bestTF, 'bestTF');
    [bestSPD_bin, coef_bestSPD_bin, npix_bestSPD_bin, masparam.ebins, ste_bestSPD_bin] = fitByEccentricityBin(asparam.ebins, areaStats_bestSPD, 'bestSPD');
    [RF_sigma_bin, coef_RF_sigma_bin, npix_RF_sigma_bin, masparam.ebins, ste_RF_sigma_bin] = fitByEccentricityBin(asparam.ebins, areaStats_RF_sigma, 'RF_sigma');

 
    %% visualization
    figure('position',[0 0 1440 800]);
    colormap(hot);
    subplot(351); imagesc(ecImage);title('eccentricity');caxis(prctile(ecImage(:),[1 99]));axis equal tight;colorbar;hold on;
    set(gca,'xtick',[],'ytick',[]);
    for iarea = 1:numel(asparam.label)
        contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
    end
    subplot(352); imagesc(sigmaImage);title('sigma');caxis(prctile(sigmaImage(:),[1 99]));axis equal tight;colorbar;hold on;
    set(gca,'xtick',[],'ytick',[]);
    for iarea = 1:numel(asparam.label)
        contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
    end
    subplot(353); imagesc(sfImage);title('SF');hold on;caxis(prctile(sfImage(:),[1 99]));axis equal tight;colorbar;
    set(gca,'xtick',[],'ytick',[]);
    for iarea = 1:numel(asparam.label)
        contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
    end
    subplot(354); imagesc(tfImage);title('TF');hold on;caxis(prctile(tfImage(:),[1 99]));axis equal tight;colorbar;
    set(gca,'xtick',[],'ytick',[]);
    for iarea = 1:numel(asparam.label)
        contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
    end
    subplot(355); imagesc(spdImage);title('SPEED');hold on;caxis(prctile(spdImage(:),[1 99]));axis equal tight;colorbar;
    set(gca,'clim',asparam.spdlim); set(gca,'ColorScale','log');
    set(gca,'xtick',[],'ytick',[]);
    for iarea = 1:numel(asparam.label)
        contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
    end
     
    %% scatter plot against eccentricity
    xaxis = 0:8;
    ip = [];
    for iarea = 1:numel(asparam.label)
        ax(1)=subplot(357);
        plot(areaStats_RF_sigma.eccentricity{iarea}, areaStats_RF_sigma.RF_sigma{iarea},'.','color',lcolor(iarea,:));
        hold on;
        %plot(xaxis, coef_RF_sigma(1,iarea)+coef_RF_sigma(2,iarea)*xaxis,'color',lcolor(iarea,:));
        
        ax(2)=subplot(358);
        plot(areaStats_bestSF.eccentricity{iarea}, areaStats_bestSF.bestSF{iarea},'.','color',lcolor(iarea,:));
        hold on;
        
        ax(3)=subplot(359);
        plot(areaStats_bestTF.eccentricity{iarea}, areaStats_bestTF.bestTF{iarea},'.','color',lcolor(iarea,:));
        hold on;
        
        ax(4)=subplot(3,5,10);
        plot(areaStats_bestSPD.eccentricity{iarea}, areaStats_bestSPD.bestSPD{iarea},'.','color',lcolor(iarea,:));
        hold on;
        
    end
    set(ax(1),'ColorOrderIndex',1);yasparam.label('sigma(deg)');xasparam.label('eccentricity(deg)');title('pRF size (deg)');
    set(ax(2),'ColorOrderIndex',1, 'ylim',[0 2.5]);yasparam.label('SF(cpd)');xasparam.label('eccentricity(deg)');title('SF (cpd)');
    set(ax(3),'ColorOrderIndex',1);yasparam.label('TF(Hz)');xasparam.label('eccentricity(deg)');title('TF (Hz)');
    set(ax(4),'ColorOrderIndex',1);yasparam.label('speed(deg/s)');xasparam.label('eccentricity(deg)');title('speed (deg/s)');
    set(ax(4),'ylim',asparam.spdlim,'yscale','log');
    
    %% binned eccentricity
    iq = [];
    for iarea = 1:numel(asparam.label)
        ax(5)=subplot(3,5,12);
        errorbar(masparam.ebins, RF_sigma_bin(:,iarea),ste_RF_sigma_bin(:,iarea),'color',lcolor(iarea,:));
        hold on;
        %plot(masparam.ebins, coef_RF_sigma_bin(1,iarea)+coef_RF_sigma_bin(2,iarea)*masparam.ebins, 'linewidth',2,'color',lcolor(iarea,:));
        
        ax(6)=subplot(3,5,13);
        iq(iarea)=errorbar(masparam.ebins, bestSF_bin(:,iarea),ste_bestSF_bin(:,iarea),'color',lcolor(iarea,:));
        hold on
        %plot(masparam.ebins, coef_bestSF_bin(1,iarea)+coef_bestSF_bin(2,iarea)*masparam.ebins, 'linewidth',2,'color',lcolor(iarea,:));
        
        ax(7)=subplot(3,5,14);
        iq(iarea)=errorbar(masparam.ebins, bestTF_bin(:,iarea),ste_bestTF_bin(:,iarea),'color',lcolor(iarea,:));
        hold on
        %plot(masparam.ebins, coef_bestTF_bin(1,iarea)+coef_bestTF_bin(2,iarea)*masparam.ebins, 'linewidth',2,'color',lcolor(iarea,:));
        
        ax(8)=subplot(3,5,15);
        iq(iarea)=errorbar(masparam.ebins, bestSPD_bin(:,iarea),ste_bestSPD_bin(:,iarea),'color',lcolor(iarea,:));
        hold on
        %plot(masparam.ebins, coef_bestSPD_bin(1,iarea)+coef_bestSPD_bin(2,iarea)*masparam.ebins, 'linewidth',2,'color',lcolor(iarea,:));
    end
    set(ax(5),'ColorOrderIndex',1, 'tickdir','out');
    set(ax(6),'ColorOrderIndex',1, 'tickdir','out','ylim',[0 2.5]);
    set(ax(7),'ColorOrderIndex',1, 'tickdir','out');
    set(ax(8),'ColorOrderIndex',1, 'tickdir','out','ylim',asparam.spdlim,'yscale','log');
    %legend(iq, asparam.label,'location','northwest');
    linkaxes(ax,'x');set(ax,'xlim',asparam.eccLim);%%linkaxes([ax(1) ax(3)],'y');
    % screen2png([encodingSavePrefix '_eccentricity-sigma-sf']);
    %screen2png(saveName);
    savePaperFigure(gcf, saveName);
    
    areaStats.areaStats_bestTF=areaStats_bestTF;
    areaStats.areaStats_bestSPD=areaStats_bestSPD;
    areaStats.areaStats_bestSF=areaStats_bestSF;
    areaStats.areaStats_RF_sigma=areaStats_RF_sigma;
    
    save(saveName, 'areaStats',...
        'areaStats_RF_sigma','coef_bestSF','coef_bestSF_bin',...
        'coef_RF_sigma','coef_RF_sigma_bin','asparam.ebins','masparam.ebins',...
        'bestTF_bin','bestSPD_bin','bestSF_bin','RF_sigma_bin',...
        'coef_bestTF_bin','coef_bestSPD_bin',...
        'npix_bestSF_bin','npix_bestTF_bin','npix_bestSPD_bin','npix_RF_sigma_bin',...
        'areaMatrix','lcolor');
    close all
    
end
