%wrapper_encoding.m
%this script loads processed data by makeDataBase.m,
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

if ~ispc
    addpath(genpath('~/git'));
    if exist('/home/dshi0006/.matlab/R2019b/matlabprefs.mat','file')
        delete('/home/dshi0006/.matlab/R2019b/matlabprefs.mat');
        save('/home/dshi0006/.matlab/R2019b/matlabprefs.mat');
    end
    
    %as of 21/3/23:
    %  touch /home/dshi0006/.matlab/R2019b/matlabprefs.mat
    %     ls -l /home/dshi0006/.matlab/R2019b/matlabprefs.mat
    % -rw-r--r-- 1 dshi0006 monashuniversity 335 Mar 13 01:41 /home/dshi0006/.matlab/R2019b/matlabprefs.mat
    %  chmod 444 /home/dshi0006/.matlab/R2019b/matlabprefs.mat
    %  ls -l /home/dshi0006/.matlab/R2019b/matlabprefs.mat
    % -r--r--r-- 1 dshi0006 monashuniversity 0 Mar 21 10:57 /home/dshi0006/.matlab/R2019b/matlabprefs.mat
    % > this mat file is unreadable 
    
    %2nd attempt 21/3/23
    % copied local one
    % 'C:\Users\dshi0006\AppData\Roaming\MathWorks\MATLAB\R2021a\matlabprefs.mat'
    % to MASSIVE, change it to read-only (chmod 444)
    % >> >> >> >> >> >> {^HError using save
    %     Unable to write file /home/dshi0006/.matlab/R2019b/matlabprefs.mat: permission
    %     denied.
    
    addDirPrefs;
end


ID = 3;
doTrain = 1; %train a gabor bank filter or use it for insilico simulation
doRF = 1;
doORSF = 1;

omitSec = 5; %omit initial XX sec for training
rescaleFac = 0.10;%0.25;

expInfo = getExpInfoNatMov(ID);

%% draw slurm ID for parallel computation specifying ROI position    
pen = getPen; 
narrays = 1000;
ngIdx = [  
           6
           7
           8
          12
          16
          17
          19
          20
          21
          25
          27
          28
          29
          31
          33
          35
          37
          39
          41
          43
          45
          47
          49
          51
          53
          55
          57
          58
          61
          63
          65
          67
          69
          71
          73
          75
          77
          79
          81
          82
          85
          87
          89
          91
          93
          95
          97
          98
         101
         103
         105
         107
         109
         111
         113
         115
         117
         119
         121
         123
         125
         127
         129
         131
         133
         135
         137
         139
         141
         143
         145
         146
         149
         151
         153
         155
         157
         158
         159
         161
         163
         164
         167
         169
         171
         174
         177
         178
         183
         184
         186
         188
         189
         190
         193
         195
         197
         199
         201
         203
         204
         207
         209
         211
         212
         213
         216
         218
         220
         221
         224
         226
         228
         229
         231
         233
         235
         237
         238
         240
         241
         244
         246
         248
         251
         253
         255
         256
         258
         260
         262
         264
         266
         268
         270
         272
         274
         276
         278
         280
         282
         283
         286
         287
         289
         291
         293
         295
         296
         297
         298
         301
         303
         305
         306
         308
         311
         313
         315
         317
         319
         321
         323
         325
         327
         329
         330
         333
         335
         337
         339
         341
         343
         345
         347
         349
         351
         352
         355
         356
         358
         361
         363
         365
         367
         369
         370
         373
         375
         376
         379
         381
         383
         384
         387
         389
         391
         392
         395
         397
         399
         401
         403
         405
         407
         409
         411
         413
         415
         417
         418
         420
         421
         422
         424
         426
         428
         430
         432
         434
         435
         438
         440
         442
         444
         446
         448
         450
         452
         454
         456
         458
         459
         462
         464
         466
         468
         470
         472
         474
         476
         478
         480
         482
         484
         486
         488
         490
         492
         494
         496
         498
         500
         502
         504
         506
         508
         510
         512
         514
         516
         518
         520
         522
         524
         526
         528
         529
         531
         532
         533
         536
         538
         540
         541
         544
         546
         548
         550
         552
         554
         557
         559
         561
         562
         565
         567
         569
         570
         573
         575
         579
         581
         583
         584
         587
         589
         593
         595
         599
         601
         604
         605
         607
         610
         611
         614
         616
         620
         621
         623
         626
         628
         630
         632
         634
         638
         640
         642
         643
         644
         647
         649
         651
         652
         655
         657
         659
         661
         663
         665
         667
         668
         671
         673
         675
         676
         678
         681
         683
         685
         686
         689
         691
         693
         694
         697
         699
         700
         703
         705
         707
         709
         711
         713
         715
         717
         719
         721
         723
         725
         727
         729
         731
         733
         735
         737
         739
         741
         743
         745
         747
         749
         751
         753
         755
         757
         759
         761
         763
         765
         768
         770
         773
         774
         776
         778
         779
         782
         784
         786
         788
         790
         792
         794
         795
         796
         797
         799
         802
         804
         808
         810
         814
         816
         820
         824
         826
         829
         830
         832
         834
         836
         837
         840
         842
         845
         846
         849
         850
         853
         855
         857
         858
         861
         863
         865
         866
         869
         871
         873
         874
         875
         876
         877
         878
         879
         880
         881
         882
         883
         885
         892
         897
         899
         902
         904
         906
         907
         910
         912
         914
         915
         916
         918
         921
         923
         926
         928
         930
         931
         934
         936
         938
         939
         942
         944
         946
         947
         949
         951
         953
         956
         957
         960
         962
         964
         965
         968
         970
         972
         973
         976
         978
         980
         981
         984
         986
         988
         989
         992
         994
         996
         997
        1000
        1006
        1007
        1008
        1012
        1016
        1017
        1019
        1020
        1021
        1025
        1027
        1028
        1029
        1031
        1033
        1035
        1037
        1039
        1041
        1043
        1045
        1047
        1049
        1051
        1053
        1055
        1057
        1058
        1061
        1063
        1065
        1067
        1069
        1071
        1073
        1075
        1077
        1079
        1081
        1082
        1085
        1087
        1089
        1091
        1093
        1095
        1097
        1098
        1101
        1103
        1105
        1107
        1109
        1111
        1113
        1115
        1117
        1119
        1121
        1123
        1125
        1127
        1129
        1131
        1133
        1135
        1137
        1139
        1141
        1143
        1145
        1146
        1149
        1151
        1153
        1155
        1157
        1158
        1159
        1161
        1163
        1164
        1167
        1169
        1171
        1174
        1177
        1178
        1183
        1184
        1186
        1188
        1189
        1190
        1193
        1195
        1197
        1199
        1201
        1203
        1204
        1207
        1209
        1211
        1212
        1213
        1216
        1218
        1220
        1221
        1224
        1226
        1228
        1229
        1231
        1233
        1235
        1237
        1238
        1240
        1241
        1244
        1246
        1248
        1251
        1253
        1255
        1256
        1258
        1260
        1262
        1264
        1266
        1268
        1270
        1272
        1274
        1276
        1278
        1280
        1282
        1283
        1286
        1287
        1289
        1291
        1293
        1295
        1296
        1297
        1298
        1301
        1303
        1305
        1306
        1308
        1311
        1313
        1315
        1317
        1319
        1321
        1323
        1325
        1327
        1329
        1330
        1333
        1335
        1337
        1339
        1341
        1343
        1345
        1347
        1349
        1351
        1352
        1355
        1356
        1358
        1361
        1363
        1365
        1367
        1369
        1370
        1373
        1375
        1376
        1379
        1381
        1383
        1384
        1387
        1389
        1391
        1392
        1395
        1397
        1399
        1401
        1403
        1405
        1407
        1409
        1411
        1413
        1415
        1417
        1418
        1420
        1421
        1422
        1424
        1426
        1428
        1430
        1432
        1434
        1435
        1438
        1440
        1442
        1444
        1446
        1448
        1450
        1452
        1454
        1456
        1458
        1459
        1462
        1464
        1466
        1468
        1470
        1472
        1474
        1476
        1478
        1480
        1482
        1484
        1486
        1488
        1490
        1492
        1494
        1496
        1498
        1500
        1502
        1504
        1506
        1508
        1510
        1512
        1514
        1516
        1518
        1520
        1522
        1524
        1526
        1528
        1529
        1531
        1532
        1533
        1536
        1538
        1540
        1541
        1544
        1546
        1548
        1550
        1552
        1554
        1557
        1559
        1561
        1562
        1565
        1567
        1569
        1570
        1573
        1575
        1579
        1581
        1583
        1584
        1587
        1589
        1593
        1595
        1599
        1601
        1604
        1605
        1607
        1610
        1611
        1614
        1616
        1620
        1621
        1623
        1626
        1628
        1630
        1632
        1634
        1638
        1640
        1642
        1643
        1644
        1647
        1649
        1651
        1652
        1655
        1657
        1659
        1661
        1663
        1665
        1667
        1668
        1671
        1673
        1675
        1676
        1678
        1681
        1683
        1685
        1686
        1689
        1691
        1693
        1694
        1697
        1699
        1700
        1703
        1705
        1707
        1709
        1711
        1713
        1715
        1717
        1719
        1721
        1723
        1725
        1727
        1729
        1731
        1733
        1735
        1737
        1739
        1741
        1743
        1745
        1747
        1749
        1751
        1753
        1755
        1757
        1759
        1761
        1763
        1765
        1768
        1770
        1773
        1774
        1776
        1778
        1779
        1782
        1784
        1786
        1788
        1790
        1792
        1794
        1795
        1796
        1797
        1799
        1802
        1804
        1808
        1810
        1814
        1816
        1820
        1824
        1826
        1829
        1830
        1832
        1834
        1836
        1837
        1840
        1842
        1845
        1846
        1849
        1850
        1853
        1855
        1857
        1858
        1861
        1863
        1865
        1866
        1869
        1871
        1873
        1874
        1875
        1876
        1877
        1878
        1879
        1880
        1881
        1882
        1883
        1885
        1892
        1897
        1899
        1902
        1904
        1906
        1907
        1910
        1912
        1914
        1915
        1916
        1918
        1921
        1923
        1926
        1928
        1930
        1931
        1934
        1936
        1938
        1939
        1942
        1944
        1946
        1947
        1949
        1951
        1953
        1956
        1957
        1960
        1962
        1964
        1965
        1968
        1970
        1972
        1973
        1976
        1978
        1980
        1981
        1984
        1986
        1988
        1989
        1992
        1994
        1996
        1997
        2000
        2006
        2007
        2008
        2012
        2016
        2017
        2019
        2020
        2021
        2025
        2027
        2028
        2029
        2031
        2033
        2035
        2037
        2039
        2041
        2043
        2045
        2047
        2049
        2051
        2053
        2055
        2057
        2058
        2061
        2063
        2065
        2067
        2069
        2071
        2073
        2075
        2077
        2079
        2081
        2082
        2085
        2087
        2089
        2091
        2093
        2095
        2097
        2098
        2101
        2103
        2105
        2107
        2109
        2111
        2113
        2115
        2117
        2119
        2121
        2123
        2125
        2127
        2129
        2131
        2133
        2135
        2137
        2139
        2141
        2143
        2145
        2146];

%% path
dataPaths = getDataPaths(expInfo,rescaleFac);
dataPaths.encodingSavePrefix = [dataPaths.encodingSavePrefix '_nxv'];

load( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'dsRate','S_fin',...
    'gaborBankParamIdx');

%% estimation of filter-bank coefficients
trainParam.KFolds = 5; %cross validation
trainParam.ridgeParam = 1e6;%logspace(5,7,3); %[1 1e3 1e5 1e7]; %search the best within these values
trainParam.tavg = 0; %tavg = 0 requires 32GB ram. if 0, use avg within Param.lagFrames to estimate coefficients
trainParam.Fs = dsRate; %hz after downsampling
trainParam.lagFrames = 2:3;%round(0/dsRate):round(5/dsRate);%frame delays to train a neuron
trainParam.useGPU = 1; %for ridgeXs local GPU is not sufficient


%% stimuli
load(dataPaths.imageSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];


%% load neural data
%TODO: copy timetable data to local
disp('Loading tabular text datastore');
ds = tabularTextDatastore(dataPaths.timeTableSaveName);

nTotPix = numel(ds.VariableNames)-1;
if ~isempty(ngIdx)
    maxJID=1;
else
    maxJID = numel(pen:narrays:nTotPix);
end
for JID = 1:maxJID
    if ~isempty(ngIdx)
        roiIdx = ngIdx(pen);
    else
        roiIdx = pen + (JID-1)*narrays;
    end
    
    %TODO: save data locally
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx) '.mat'];
    
    %% in-silico RF estimation
    RF_insilico = struct;
    RF_insilico.noiseRF.nRepeats = 80; %4
    RF_insilico.noiseRF.dwell = 15; %frames
    RF_insilico.noiseRF.screenPix = stimInfo.screenPix/8;%4 %[y x]
    RF_insilico.noiseRF.maxRFsize = 10; %deg in radius
    %<screenPix(1)/screenPix(2) determines the #gabor filters
    
    
    %% in-silico ORSF estimation
    RF_insilico.ORSF.screenPix = stimInfo.screenPix; %[y x]
    nORs = 10;
    oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
    RF_insilico.ORSF.oriList = oriList(1:end-1);
    SFrange_stim = getSFrange_stim(RF_insilico.ORSF.screenPix, stimSz);
    RF_insilico.ORSF.sfList = logspace(log10(SFrange_stim(1)), log10(SFrange_stim(2)), 6); %[cycles/deg];
    RF_insilico.ORSF.nRepeats = 15;
    RF_insilico.ORSF.dwell = 45; %#stimulus frames
    
    
    if doTrain
        %% load gabor bank prediction data
        %TODO load data tolocal
        RF_insilico.Fs_visStim = gaborBankParamIdx.predsRate;
        
        %% estimate the energy-model parameters w cross validation
        nMovies = numel(stimInfo.stimLabels);
        movDur = stimInfo.duration;%[s]
        trainIdx = [];
        for imov = 1:nMovies
            trainIdx = [trainIdx (omitSec*dsRate+1:movDur*dsRate)+(imov-1)*movDur*dsRate];
        end
        
        
        %% fitting!
        tic;
        lagRangeS = [trainParam.lagFrames(1) trainParam.lagFrames(end)]/trainParam.Fs;
        trained = trainAneuron(ds, S_fin, roiIdx, trainIdx, trainParam.ridgeParam,  ...
            trainParam.KFolds, lagRangeS, ...
            trainParam.tavg, trainParam.useGPU);
        t1=toc %6s!
        screen2png([encodingSaveName(1:end-4) '_corr']);
        close;
        
        %clear S_fin
        save(encodingSaveName,'trained','trainParam');
    else
        load(encodingSaveName,'trained','trainParam');
    end
    
    
    %% in-silico simulation to obtain RF
    if doRF
        RF_insilico = getInSilicoRF(gaborBankParamIdx, trained, trainParam, ...
            RF_insilico, stimSz);
        
        analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
        RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);
        showInSilicoRF(RF_insilico, analysisTwin);
        screen2png([encodingSaveName(1:end-4) '_RF']);
        close;        
        save(encodingSaveName,'RF_insilico','-append');
    end
    
    %% in-silico simulation to obtain ORSF
    if doORSF
        RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, ...
            RF_insilico, stimSz, 3);
        showInSilicoORSF(RF_insilico);
        
        trange = [2 trainParam.lagFrames(end)/dsRate];

        RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, trange, 1);
        screen2png([encodingSaveName(1:end-4) '_ORSF']);
        close;        
        save(encodingSaveName,'RF_insilico','-append');
    end

end
