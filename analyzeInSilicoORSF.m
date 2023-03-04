function RF_insilico = analyzeInSilicoORSF(RF_insilico, peakPolarity,trange)
if nargin < 2
    peakPolarity = -1;
end
if nargin < 3
    trange = [-inf inf];
end

method = 0;
sflog = 1;

tidx = find(RF_insilico.ORSF.respDelay>=trange(1) & RF_insilico.ORSF.respDelay<=trange(2));
resp = mean(RF_insilico.ORSF.resp(:,:,tidx),3);


resp = peakPolarity*resp;

switch method
    case 0
        %option0: simply detect the minimum
        [amp, idx] = max(resp(:));
        [sfidx, oridx, tidx] = ind2sub(size(RF_insilico.ORSF.resp), idx);
        
        RF_insilico.ORSF.bestSF = RF_insilico.ORSF.sfList(sfidx);
        RF_insilico.ORSF.bestOR = 180/pi*RF_insilico.ORSF.oriList(oridx); %deg
        
    case 1
        %option1: 2D fitting
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
end