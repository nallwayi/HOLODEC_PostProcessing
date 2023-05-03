% Function to replace getparticlemetrics.m
% April 19,2023
% Main changes
% 1. Option to read hist files remotely
% 2. CNN/trees and rules are applied to individual hist files
% 3. pStats_v0 is discarded. ParticlesImages are Included in pStats_v1
% 4. Optimized to work on lower RAM workstations

function pStats = processHistfiles(dest,pathtoHistfiles,rules,predictionParams,CPUlimit)

c1 = cputime;
d1 =datetime;

% dest = 'ftp.archive.arm.gov';
% pathtoHistfiles = 'allwayinn1/holodec_data/IOP2_Flight1/recon';
if strcmp(dest,'local')
    histdetails = dir(fullfile(pathtoHistfiles,'*/*hist.mat'));
    if size(histdetails,1) ==0
        histdetails = dir(fullfile(pathtoHistfiles,'*hist.mat'));
    end
    
    
else
    ftpObj = ftp(dest);
    cd(ftpObj,pathtoHistfiles);
    histdetails = dir(ftpObj);
    cd(ftpObj,'~');
    close(ftpObj);
    
end


histdetails = struct2table( histdetails);
ind = ~contains(histdetails.name,'hist.mat');
histdetails(ind,:)= [];
if exist('CPUlimit','var')
    histSegBoundary = divideHologram2Segments(histdetails,CPUlimit);
else
    histSegBoundary = divideHologram2Segments(histdetails,[]);
end






%   Extracting time details for ACE-ENA pmetrics
holoName   = histdetails.name;
holotimes  = length(holoName);
holonum    = length(holoName);
timestamp  = length(holoName);
holosecond = length(holoName);

for cnt = 1:length(holoName)
    %         tmp = histdetails(cnt).name;
    tmp = holoName{cnt}(end-34:end-9);
    yr = str2double(tmp(1:4));
    mt = str2double(tmp(6:7));
    dy = str2double(tmp(9:10));
    hr = str2double(tmp(12:13));
    mn = str2double(tmp(15:16));
    sc = str2double(tmp(18:19)) + 1e-6*str2double(tmp(21:26));
    sd = str2double(tmp(18:19));
    
    holotimes(cnt)  = hr*3600+mn*60+sc;
    holosecond(cnt) = hr*3600+mn*60+sd;
    timestamp(cnt)  = datenum(yr,mt,dy,hr,mn,sc);
    holonum(cnt)    = cnt;
end


%     Determining the number of holograms in each second
noholograms(:,1)  = unique(holosecond);
for cnt = 1:length(noholograms(:,1))
    ind = find(noholograms(cnt,1) == holosecond);
    noholograms(cnt,2) = length(ind);
end


%     Saving the data
pStats.header      = holoName{1}(1:end-36);
pStats.noholograms = noholograms;

if ~exist([pStats.header '_HOPOP_V2.1_results'],'dir')
    mkdir([pStats.header '_HOPOP_V2.1_results'])
end
cd ([pStats.header '_HOPOP_V2.1_results'])

%     Saving info about all processed holograms
pStats.holoinfo = table(holonum,timestamp,holotimes,holosecond);
pStats.rules   = rules;


% particledata=load(fullfile(histdetails.folder{1},histdetails.name{1}));
% pStats.metricnames = [particledata.pd.metricnames;'pixden';'holotimes';...
%     'timestamp';'holosecond';'holonum'];
% 	for i=1:length(metricnames)
%         pStats.metrics.(metricnames{i})=[];
%     end
pStats.metricmat=[];

predictionParams.pred_path = [pwd '/CNNClassif'];

if strcmp(predictionParams.method,'cnn')
    pStats.predictionParams.model = predictionParams.model;
    pStats.predictionParams.pred_path = predictionParams.pred_path;
else
    pStats.predictionParams.noisetree = predictionParams.tree.noisetree;
    pStats.predictionParams.particletree = predictionParams.tree.particletree;
end

delete(gcp('nocreate')) % closing active parallel sessions
if strcmp(dest,'local')
    parpool('local')
else
    parpool('local',8)
end

for cnt2=1:length(histSegBoundary)-1
    
    unprcsdMetricsTable=[];
    %     prcsdMetricsTable=[];
    if isfile(['pdMetrics_part' sprintf('%02d',cnt2) '.mat'])
        load(['pdMetrics_part' sprintf('%02d',cnt2) '.mat'],'prcsdMetricsTable')
    else
        
        parfor cnt = histSegBoundary(cnt2)+1:histSegBoundary(cnt2+1)
            
            try
                if strcmp(dest,'local')
                    particledata=load(fullfile(histdetails.folder{cnt},histdetails.name{cnt}));
                else
                    
                    ftpObj = ftp(dest);
                    cd(ftpObj,pathtoHistfiles);
                    mget(ftpObj,histdetails.name{cnt});
                    particledata = load(histdetails.name{cnt});
                    delete(histdetails.name{cnt});
                    cd(ftpObj,'~');
                    close(ftpObj);
                end
                
                metrics = particledata.pd.getmetrics;
                
                % Adding pixden rule if it dosent exist
                if ~isfield(metrics,'pixden')
                    metrics.pixden = 4*metrics.area./(pi*metrics.minsiz.*metrics.majsiz);
                end
                
                %           Adding holonum, holotimes and timestamp
                
                metrics.holonum   = ones((length(metrics.pixden)),1)*holonum(cnt);
                metrics.timestamp = ones((length(metrics.pixden)),1)*timestamp(cnt);
                metrics.holotimes = ones((length(metrics.pixden)),1)*holotimes(cnt);
                metrics.holosecond= ones((length(metrics.pixden)),1)*holosecond(cnt);
                
                
                metrics.prtclIm = particledata.pd.getprtclIm;
                metrics.prtclID = particledata.pd.prtclID;
                
                
                tmp = struct2table(metrics);
                unprcsdMetricsTable = [unprcsdMetricsTable;tmp];
                %             fnames = fieldnames(metrics);
                %             tmp = ApplyRules2HistMetrics(tmp,rules,fnames);
                %
                %             if strcmp(predictionParams.method,'cnn')
                %                 tmp = predictionUsingCNN(tmp,predictionParams);
                %             else
                %                 tmp = predictionUsingDecisionTree(tmp,predictionParams);
                %             end
                %             prcsdMetricsTable = [prcsdMetricsTable;tmp];
            catch
                warning([histdetails.name{cnt}, ' could not be read'])
                
            end
        end
        fnames = fieldnames(unprcsdMetricsTable);
        unprcsdMetricsTable = ApplyRules2HistMetrics(unprcsdMetricsTable,rules,fnames);
        
        if strcmp(predictionParams.method,'cnn')
            prcsdMetricsTable = predictionUsingCNN(unprcsdMetricsTable,predictionParams);
        else
            prcsdMetricsTable = predictionUsingDecisionTree(unprcsdMetricsTable,predictionParams);
        end
        
        
        save(['pdMetrics_part' sprintf('%02d',cnt2)],'prcsdMetricsTable')
    end
    %     pStats.metricname = fieldnames()
    pStats.metricmat = [pStats.metricmat;prcsdMetricsTable(:,1:end-2)];
    

    
    
end


fnames = fieldnames(pStats.metricmat);
for cnt=1:length(fnames)-3
    pStats.metrics.(fnames{cnt}) ...
        = pStats.metricmat{:,cnt};
end   
    pStats.metricmat =[];
    
    c2 = cputime;
    d2 =datetime;

Function = "processHistfiles";
Walltime = d2-d1;
CPUtime  = c2-c1;
pStats.timesstruct = table(Function,Walltime,CPUtime);
end

function histSegBoundary = divideHologram2Segments(histdetails,CPUlimit)

if ~isempty(CPUlimit)
    freelSysMemory= CPUlimit*1e9;
else
    
    try
        [userview,systemview] = memory;
        matlabMemUsage = userview.MemUsedMATLAB;
        freelSysMemory = systemview.PhysicalMemory.Available;
        totalSysMemory = systemview.PhysicalMemory.Total;
    catch
        [r,w] = unix('free | grep Mem');
        stats = str2double(regexp(w, '[0-9]*', 'match'));
        totalSysMemory = stats(1)/1e6*1e9;
        freelSysMemory = (stats(3)+stats(end))/1e6*1e9;
    end
end

% sizeHist = [];

% for cnt=1:length(histdetails.)
%     sizeHist(cnt) = histdetails(cnt).bytes;
% end
sizeHist = histdetails.bytes;

cntr1=1;
histSegBoundary=[0];
for cntr2=1:length(sizeHist)
    
    if sum(sizeHist(cntr1:cntr2)) >= (freelSysMemory-2)
        cntr1 = cntr2 + 1;
        histSegBoundary= [histSegBoundary;cntr2];
    end
end

histSegBoundary(end+1) = length(sizeHist);
end


function this = ApplyRules2HistMetrics(this,rules,fnames)

% Rules to remove artifacts from hist files

%     fnames = fieldnames(pStats.metrics);
for cnt = 1:size(rules,1)
    fncn=str2func(rules{cnt,2});
    tmp = fncn(this.(rules{cnt,1}),rules{cnt,3});
    %     for cnt2=1:length(fnames)
    %         this.(fnames{cnt2})(~tmp)=[];
    %     end
    this(~tmp,:)=[];
    % %     for cnt=1:length(tmp)
    % %         if ~tmp(cnt)
    % %             pStats.metrics(cnt,:)=[];
    % %         end
    % %     end
end

end


function metricsTable = predictionUsingCNN(metricsTable,predictionParams)

temp1 = classificationData('prtclIm',metricsTable.prtclIm,'prtclID',metricsTable.prtclID);
if ~exist(predictionParams.pred_path,'dir')
    mkdir(predictionParams.pred_path)
end
temp1.predict_NN(predictionParams.model,...
    predictionParams.pred_path);
classsification_cnn= readtable(fullfile(predictionParams.pred_path,...
    'dcnn_pred_pipeline.csv'));

tmp = classsification_cnn{:,5};
isParticle=[];
for cnt=1:length(tmp)
    isParticle(cnt) = str2double(extractAfter(tmp{cnt},','));
end
ind = (isParticle == 0);

metricsTable(ind,:) = [];

end

function metricsTable = predictionUsingDecisionTree(metricsTable)

nind=[];
pind=[];
for cnt=1:length(unique(metricsTable.metrics.holotimes))
    ind = find(metricsTable.metrics.holotimes == metricsTable.holoinfo(cnt,3));
    if ~isempty(ind)
        % Sorting the data in a hologram using classification trees
        threshold = 10;
        if numel(ind)<=threshold
            nind = [nind; ind];
        else
            pind = [pind; ind];
        end
    end
end

%     fnames = fieldnames(metricsTable.metrics);

if ~isempty(nind)
    %         for cnt=1:length(fnames)
    %             nthis.(fnames{cnt}) = metricsTable.metrics.(fnames{cnt})(nind);
    %         end
    nthis = metricsTable(nind,:);
    nthis = sortusingclassificationtree...
        (nthis,predictionParams.tree.noisetree);
end

if ~isempty(pind)
    %         for cnt=1:length(fnames)
    %             pthis.(fnames{cnt}) = metricsTable.metrics.(fnames{cnt})(pind);
    %         end
    pthis = metricsTable(pind,:);
    pthis = sortusingclassificationtree...
        (pthis,predictionParams.tree.particletree);
end

if exist('nthis','var') && exist('pthis','var')
    for cnt2=1:length(fnames)
        %             metricsTable.metrics.(fnames{cnt2}) ...
        %                 = cat(1,nthis.(fnames{cnt2})...
        %                 ,pthis.(fnames{cnt2}));
        metricsTable = [nthis;pthis];
        
    end
elseif exist('pthis','var')
    for cnt2=1:length(fnames)
        %             metricsTable.metrics.(fnames{cnt2}) ...
        %                 = pthis.(fnames{cnt2});
        metricsTable = [pthis];
    end
else
    for cnt2=1:length(fnames)
        %             metricsTable.metrics.(fnames{cnt2}) ...
        %                 = nthis.(fnames{cnt2});
        metricsTable = [nthis];
    end
    
end
%     unsortedTable = struct2table(metricsTable.metrics);

%     metricsTable.metrics=[];
metricsTable = sortrows(metricsTable, 'holonum');
%     for cnt2=1:length(fnames)
%         metricsTable.metrics.(fnames{cnt2}) = sortedT.(fnames{cnt2})(:);
%     end

%     nthis	= pStats.metrics(nind,:);
%     nthis = sortusingclassificationtree(nthis,pStats.noisetree);
%     pthis	= pStats.metrics(pind,:);
%     pthis = sortusingclassificationtree(pthis,pStats.noisetree);
%
%     unsortedMetrics = [nthis;pthis];
%     sortedMetrics = sortrows(unsortedMetrics, 'holonum');
%     pStats.metrics = sortedMetrics;

end
function this = sortusingclassificationtree(this,tree)


%     table = struct2table(this);
table=this;
ind = predict(tree,table)== 'Particle_round';
this = this(ind,:);
%     fnames = fieldnames(this);
%     for cnt=1:length(fnames)
%         this.(fnames{cnt}) = this.(fnames{cnt})(ind);
%     end

end