thisID = [1:3 8 9];

for idx = 1:5
    useGPU = 1;
    rescaleFac = 0.10;
    dsRate = 1;
    reAnalyze = 0; %1
    ORSFfitOption = 1; %3:peakSF,fitOR
    roiSuffix = '';

    ID = thisID(idx);
    aparam = getAnalysisParam(ID);
     pixPermm = getPixPerMm(rescaleFac);

   
    %% path
    expInfo = getExpInfoNatMov(ID);
    dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, aparam.stimSuffix);
    encodingSavePrefix = [dataPaths.encodingSavePrefix aparam.regressSuffix];
    
    data = load([encodingSavePrefix '_summary.mat']);
    
    if aparam.flipLR
        data.summary_adj.RF_Cx = fliplr(data.summary_adj.RF_Cx);
        data.summary_adj.RF_Cy = fliplr(data.summary_adj.RF_Cy);
        data.summary_adj.RF_sigma = fliplr(data.summary_adj.RF_sigma);
        data.summary_adj.ridgeParam = fliplr(data.summary_adj.ridgeParam);
        data.summary_adj.bestSF = fliplr(data.summary_adj.bestSF);
        data.summary_adj.bestOR = fliplr(data.summary_adj.bestOR);
        data.summary_adj.expVar = fliplr(data.summary_adj.expVar);
        data.summary_adj.correlation = fliplr(data.summary_adj.correlation);
        data.summary_adj.thisROI = fliplr(data.summary_adj.thisROI);
        data.summary_adj.mask = fliplr(data.summary_adj.mask);
        data.summary_adj.vfs = fliplr(data.summary_adj.vfs);
    end
        
    mask{idx} = data.summary_adj.mask;
    vfs{idx} = data.summary_adj.vfs;
    expvar{idx} = data.summary_adj.expVar;
    corr{idx} = data.summary_adj.correlation;
    
    sign{idx} = signBorder;
    cy{idx} = CyBorder;
    mask_vfs{idx} = newmask;
    
end

% for idx= 1:4
%     subplot(1,3,idx);
%     imagesc(imgaussfilt(corr{idx})>.29);colorbar
%     %imagesc(expvar{id}>6);colorbar
%     axis equal tight
% end


%% inter-animal registration
% how to obtain the average VFS across animals? > allen


[optimizer, metric] = imregconfig('monomodal');
% optimizer = registration.optimizer.OnePlusOneEvolutionary();
% optimizer.MaximumIterations = 200;
% optimizer.GrowthFactor = 1+1e-6;
% optimizer.InitialRadius = 1e-4;

for idx = 1:5
    fixed = vfs{2}.*(mask{2}==1); %(expvar{2}>5).*
    moving = vfs{idx}.*(mask{idx}==1).*(corr{idx}>.26);
    tform = imregtform(moving,fixed,'rigid',optimizer,metric, 'displayoptimization',true);
    %cf. imregdemons
    tform_matrix = tform.T;
    
    moving_reg(:,:,idx) = imwarp(moving,tform,"OutputView",imref2d(size(fixed)));
    signBorder_reg(:,:,idx) = imwarp(sign{idx},tform,"OutputView",imref2d(size(fixed)));
    cyBorder_reg(:,:,idx) = imwarp(cy{idx},tform,"OutputView",imref2d(size(fixed)));
    mask_reg(:,:,idx) = imwarp(mask{idx},tform,"OutputView",imref2d(size(fixed)));
end


subplot(121);
imagesc(mask_reg(:,:,2));
axis equal tight off;

subplot(122);
imagesc(mean(moving_reg,3));hold on
cmap = customcolormap(linspace(0,1,3), ...
    [0 0 1; 0 0 0; 1 0 0]);
colormap(cmap);
contourColorMap = lines(5);
for idx = 1:5
    contour(signBorder_reg(:,:,idx),[-0.1 0.1],'linecolor',contourColorMap(idx,:),'linewidth',1);
    %contour(cyBorder_reg(:,:,id), [0 0], ':w','linewidth',2);
    axis equal tight ij off;
end
savePaperFigure(gcf,'alignVFS');