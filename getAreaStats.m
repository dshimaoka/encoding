function [areaStats, excPercent] = getAreaStats(summary_adj, areaMatrix, statName, selectPixelTh)
%[areaStats, excPercent] = getAreaStats(summary_adj, areaMatrix, statName, selectPixelTh)
% %INPUT
% summary_adj
% areaMatrix
% statName = 'bestSF'
% selectPixelTh
% 
% %OUTPUT
% areaStats

for iarea = 1:numel(areaMatrix)
    theseSub = (areaMatrix{iarea}==1);
    theseIdx = find(theseSub);
        
    thisStat_tmp = summary_adj.(statName)(theseSub);
    ngIdx = (isinf(thisStat_tmp(:)));
    theseIdx(ngIdx) = [];
    original=numel(theseIdx);
    
    if ~isempty(selectPixelTh)
        thismedian = nanmedian(thisStat_tmp(~ngIdx));
        thismad = mad(thisStat_tmp(~ngIdx));
        theseIdx = theseIdx(find((thisStat_tmp(~ngIdx) > thismedian - selectPixelTh*thismad)...
            .* (thisStat_tmp(~ngIdx) < thismedian + selectPixelTh*thismad)));
        after = numel(theseIdx);
    end
    areaStats.(statName){iarea} = summary_adj.(statName)(theseIdx);
    areaStats.RF_Cx{iarea} = summary_adj.RF_Cx(theseIdx);
    areaStats.RF_Cy{iarea} = summary_adj.RF_Cy(theseIdx);
    areaStats.eccentricity{iarea} = sqrt( areaStats.RF_Cx{iarea}.^2 + areaStats.RF_Cy{iarea}.^2);
    
    excPercent(iarea) = 100*(original-after)/original;
end


% %% robust linear fitting vs eccentricity
% mebins = ebins(1:end-1)+.5*mean(diff(ebins));
% SF_b = nan(numel(ebins)-1,numel(label));
% sigma_b = nan(numel(ebins)-1,numel(label));
% coef_sigma = nan(2, numel(label));
% coef_SF = nan(2, numel(label));
% for iarea = 1:numel(label)
%     binIdx = discretize(areaStats.eccentricity{iarea}, ebins);
%     for ibin = 1:numel(ebins)-1
%         theseIdx = find(binIdx == ibin);
%         SF_b(ibin,iarea) = median(areaStats.bestSF{iarea}(theseIdx));
%     end
%     try
%         coef_sigma(:,iarea) = robustfit(mebins, sigma_b(:,iarea));
%     catch
%     end
% end
