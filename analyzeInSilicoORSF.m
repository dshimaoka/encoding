function RF_insilico = analyzeInSilicoORSF(RF_insilico, peakPolarity,trange,method)
if nargin < 2
    peakPolarity = -1;
end
if nargin < 3
    trange = [-inf inf];
end
if nargin < 4
    method = 0;
end

sflog = 1;

tidx = find(RF_insilico.ORSF.respDelay>=trange(1) & RF_insilico.ORSF.respDelay<=trange(2));
resp = mean(RF_insilico.ORSF.resp(:,:,tidx),3);
resp = peakPolarity*resp;
resp(resp<0) = 0;
%resp = resp - min(resp(:)); %make all values above 0 for fitting gaussian

switch method
    case 0 %simply detect the minimum
        [amp, idx] = max(resp(:));
        [sfidx, oridx, tidx] = ind2sub(size(RF_insilico.ORSF.resp), idx);
        
        RF_insilico.ORSF.bestSF = RF_insilico.ORSF.sfList(sfidx);
        RF_insilico.ORSF.bestOR = 180/pi*RF_insilico.ORSF.oriList(oridx); %deg
        
    case 1 %2D fitting
        if sflog
            p = fitGaussOri180(log(RF_insilico.ORSF.sfList), 180/pi*RF_insilico.ORSF.oriList, resp');
            RF_insilico.ORSF.bestSF = exp(p(1));
            RF_insilico.ORSF.sigmaSF = exp(p(4));
        else
            p = fitGaussOri180(RF_insilico.ORSF.sfList, 180/pi*RF_insilico.ORSF.oriList, resp');
            RF_insilico.ORSF.bestSF = p(1);
            RF_insilico.ORSF.sigmaSF = p(4);
        end
        
        RF_insilico.ORSF.bestOR = p(5);
        RF_insilico.ORSF.sigmaOR = p(8);
        
    case 2 %successive 1D fitting 
        if sflog
            xx = repmat(log(RF_insilico.ORSF.sfList),[1 size(resp,2)]);
            p = fitGauss1(xx, resp); %NG
            %p = fitGauss1(log(RF_insilico.ORSF.sfList), mean(resp,2)); %NG
            RF_insilico.ORSF.bestSF = exp(p(1));
            RF_insilico.ORSF.bestSF = max(min(RF_insilico.ORSF.bestSF, max(RF_insilico.ORSF.sfList)), min(RF_insilico.ORSF.sfList));
            
            [~, bestSFidx] = min(abs(log(RF_insilico.ORSF.sfList) - log(RF_insilico.ORSF.bestSF)));
            p2 = fitOritune180(RF_insilico.ORSF.oriList, resp(bestSFidx,:));
            RF_insilico.ORSF.bestOR = p2(1);            
        end
    case 3 %peak in SF, then fit in OR
         [amp, idx] = max(resp(:));
        [sfidx, oridx, tidx] = ind2sub(size(RF_insilico.ORSF.resp), idx);
        
        RF_insilico.ORSF.bestSF = RF_insilico.ORSF.sfList(sfidx);
        p2 = fitOritune180(180/pi*RF_insilico.ORSF.oriList, resp(sfidx,:));
        RF_insilico.ORSF.bestOR = p2(1);
end