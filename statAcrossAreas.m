
%% parmaeters
ID = 8;
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
aparam.stimSuffix = '_square20'; %TEMP

dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, aparam.stimSuffix);

encodingSavePrefix = [dataPaths.encodingSavePrefix aparam.regressSuffix];


load([encodingSavePrefix '_summary'],'summary_adj');

if remakeParcellation
    %% labels for corresponding areas
    label{1} = 'V1';
    label{2} = 'V2';
    label{3} = 'DM';
    label{4} = 'V3';
    label{5} = 'V4';
    label{6} = 'DI';
    lcolor = lines(numel(label));

    
    %% show composite map (under construction)
    %summary_adj.mask = summary_adj.mask .* (summary_adj.correlation>aparam.corrth);
    [fig, signMap, signBorder, CyBorder, mask] = showCompositeMap(summary_adj, aparam.corrth, ...
        aparam.showXrange, aparam.showYrange, rescaleFac);
    %figure(fig);line([45 45],[55 55+getPixPerMm(rescaleFac)], 'linewidth',2);
    %savePaperFigure(fig,[encodingSavePrefix '_compositeMap']);
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
                label_obs{ii} = 'V1';
            case 2
                label_obs{ii} = 'V2-DM+';
            case 3
                label_obs{ii} = 'DM-';
            case 4
                label_obs{ii} = 'V3-DI'; %ID2 has split V3
            case 5
                label_obs{ii} = 'V4';
        end
        figure;
        [connectedPixels{ii}, connectedMatrix{ii}] = ...
            findConnectedPixels(signBorder,...
            label_obs{ii});
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
    
    
    
    %% show results of labeling
    for iarea = 1:numel(label)
        contourf(areaMatrix{iarea},[.5 .5], 'facecolor',lcolor(iarea,:));
        hold on;
        [r, c] = find(areaMatrix{iarea} == 1);
        text(mean(c), mean(r), label{iarea});
    end
    axis ij equal;
    screen2png([num2str(ID) '_roi']);
else
    load([encodingSavePrefix '_parcelledArea'],'areaMatrix','label','lcolor');
end

%% represent in cortical surface
ecImage = nan(size(summary_adj.mask));
sfImage = nan(size(summary_adj.mask));
sigmaImage = nan(size(summary_adj.mask));
for iarea = 1:numel(label)
    theseSub = (areaMatrix{iarea}==1);
    sfImage(theseSub) = summary_adj.bestSF(theseSub);
    sigmaImage(theseSub) = summary_adj.RF_sigma(theseSub);
    ecImage(theseSub) = sqrt(summary_adj.RF_Cx(theseSub).^2 + summary_adj.RF_Cy(theseSub).^2);
end
figure('position',[0 0 1000 400]);
colormap(gray);
subplot(131); imagesc(ecImage);title('eccentricity');caxis(prctile(ecImage(:),[1 99]));axis equal tight;mcolorbar;hold on;
for iarea = 1:numel(label)
    contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
end
subplot(132); imagesc(sigmaImage);title('sigma');caxis(prctile(sigmaImage(:),[1 99]));axis equal tight;mcolorbar;hold on;
for iarea = 1:numel(label)
    contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
end
subplot(133); imagesc(sfImage);title('SF');hold on;caxis(prctile(sfImage(:),[1 99]));axis equal tight;mcolorbar;
for iarea = 1:numel(label)
    contour(areaMatrix{iarea},[.5 .5], 'linecolor',lcolor(iarea,:),'linewidth',3);
end
screen2png([num2str(ID) '_eccentricity-sigma-sf_pix' suffix]);

areaStats_bestSF = getAreaStats(summary_adj, areaMatrix, 'bestSF', selectPixelTh);
areaStats_RF_sigma = getAreaStats(summary_adj, areaMatrix, 'RF_sigma', selectPixelTh);
 
%% robust linear fitting vs eccentricity
[bestSF_bin, coef_bestSF_bin, mebins] = fitByEccentricityBin(ebins, areaStats_bestSF, 'bestSF');
[RF_sigma_bin, coef_RF_sigma_bin, mebins] = fitByEccentricityBin(ebins, areaStats_RF_sigma, 'RF_sigma');

[coef_bestSF] = fitByEccentricity(areaStats_bestSF, 'bestSF');
[coef_RF_sigma] = fitByEccentricity(areaStats_RF_sigma, 'RF_sigma');

%% scatter plot against eccentricity
figure('position',[0 0 800 500]);
xaxis = 0:8;
ip = [];
for iarea = 1:numel(label)
    ax(1)=subplot(221);
    plot(areaStats_RF_sigma.eccentricity{iarea}, areaStats_RF_sigma.RF_sigma{iarea},'.','color',lcolor(iarea,:));
    hold on;
    plot(xaxis, coef_RF_sigma(1,iarea)+coef_RF_sigma(2,iarea)*xaxis,'color',lcolor(iarea,:));
    
    ax(2)=subplot(222);
    plot(areaStats_bestSF.eccentricity{iarea}, areaStats_bestSF.bestSF{iarea},'.','color',lcolor(iarea,:));
    hold on;
    plot(xaxis, coef_bestSF(1,iarea)+coef_bestSF(2,iarea)*xaxis,'color',lcolor(iarea,:));
end
subplot(221); set(gca,'ColorOrderIndex',1);ylabel('sigma(deg)');xlabel('eccentricity(deg)');title('pRF size (deg)');
subplot(222); set(gca,'ColorOrderIndex',1, 'ylim',[0 2.5]);ylabel('SF(cpd)');xlabel('eccentricity(deg)');title('SF (cpd)');

iq = [];
for iarea = 1:numel(label)
    ax(3)=subplot(223);
    plot(mebins, RF_sigma_bin(:,iarea),'o','color',lcolor(iarea,:));
    hold on;
    plot(mebins, coef_RF_sigma_bin(1,iarea)+coef_RF_sigma_bin(2,iarea)*mebins, 'linewidth',2,'color',lcolor(iarea,:));
    
    ax(4)=subplot(224);
    iq(iarea)=plot(mebins, bestSF_bin(:,iarea),'o','color',lcolor(iarea,:));
    hold on
    plot(mebins, coef_bestSF_bin(1,iarea)+coef_bestSF_bin(2,iarea)*mebins, 'linewidth',2,'color',lcolor(iarea,:));
    
end
subplot(223); set(gca,'ColorOrderIndex',1, 'tickdir','out');
subplot(224); set(gca,'ColorOrderIndex',1, 'tickdir','out','ylim',[0 2.5]);
legend(iq, label);
linkaxes(ax,'x');linkaxes([ax(1) ax(3)],'y');
% screen2png([encodingSavePrefix '_eccentricity-sigma-sf']);
screen2png([num2str(ID) '_eccentricity-sigma-sf' suffix]);


