function RF_insilico = analyzeInSilicoDIRSFTF(RF_insilico, peakPolarity,trange,method)
%created from analyzeInSilicoORSF(RF_insilico, peakPolarity,trange,method)
if nargin < 2
    peakPolarity = -1;
end
if nargin < 3
    trange = [-inf inf];
end
if nargin < 4
    method = 1;
end

%judge if sfList is log scale or linear scale
tolerance = 0.1;
differences = diff(RF_insilico.DIRSFTF.sfList);
if all(abs(differences - mean(differences)) < tolerance)
    sflog = 0;
else
    sflog = 1;
end

tflog = 1;

tidx = find(RF_insilico.DIRSFTF.respDelay>=trange(1) & RF_insilico.DIRSFTF.respDelay<=trange(2));
resp = squeeze(mean(mean(RF_insilico.DIRSFTF.resp(:,:,:,tidx),4),2)); %sum over directions as in Nishimoto 2011
resp = peakPolarity*resp;
resp(resp<0) = 0;
%resp = resp - min(resp(:)); %make all values above 0 for fitting gaussian

switch method
    %     case 0 %simply detect the minimum
    %         [amp, idx] = max(resp(:));
    %         [sfidx, oridx, tidx] = ind2sub(size(RF_insilico.DIRSFTF.resp), idx);
    %
    %         RF_insilico.DIRSFTF.bestSF = RF_insilico.DIRSFTF.sfList(sfidx);
    %         RF_insilico.DIRSFTF.bestOR = 180/pi*RF_insilico.DIRSFTF.oriList(oridx); %deg
    
    case 1 %2D fitting
        sfList = RF_insilico.DIRSFTF.sfList;
        tfList = RF_insilico.DIRSFTF.tfList;
        
        if sflog
            sfaxis = log(double(sfList));
        else
            sfaxis = sfList;
        end
        
        if tflog
            tfaxis = log(double(tfList));
        else
            tfaxis = tfList;
        end
        p = fitGauss2(tfaxis, sfaxis, resp);%need smoothing before this
        
        RF_insilico.DIRSFTF.bestTF = p(1);
        RF_insilico.DIRSFTF.bestSF = p(2);
        
        if sflog
            RF_insilico.DIRSFTF.bestSF = exp(RF_insilico.DIRSFTF.bestSF);
        end
        if tflog
            RF_insilico.DIRSFTF.bestTF = exp(RF_insilico.DIRSFTF.bestTF);
        end
        
        
        
        %     case 2 %successive 1D fitting
        %         if sflog
        %             xx = repmat(log(RF_insilico.DIRSFTF.sfList),[1 size(resp,2)]);
        %             p = fitGauss1(xx, resp); %NG
        %             %p = fitGauss1(log(RF_insilico.DIRSFTF.sfList), mean(resp,2)); %NG
        %             RF_insilico.DIRSFTF.bestSF = exp(p(1));
        %             RF_insilico.DIRSFTF.bestSF = max(min(RF_insilico.DIRSFTF.bestSF, max(RF_insilico.DIRSFTF.sfList)), min(RF_insilico.DIRSFTF.sfList));
        %
        %             [~, bestSFidx] = min(abs(log(RF_insilico.DIRSFTF.sfList) - log(RF_insilico.DIRSFTF.bestSF)));
        %             p2 = fitOritune180(RF_insilico.DIRSFTF.oriList, resp(bestSFidx,:));
        %             RF_insilico.DIRSFTF.bestOR = p2(1);
        %         end
        %     case 3 %peak in SF, then fit in OR
        %          [amp, idx] = max(resp(:));
        %         [sfidx, oridx, tidx] = ind2sub(size(RF_insilico.ORSF.resp), idx);
        %
        %         RF_insilico.ORSF.bestSF = RF_insilico.ORSF.sfList(sfidx);
        %         p2 = fitOritune180(180/pi*RF_insilico.ORSF.oriList, resp(sfidx,:));
        %         RF_insilico.ORSF.bestOR = p2(1);
end

RF_insilico.DIRSFTF.method = method; %11/9/2023