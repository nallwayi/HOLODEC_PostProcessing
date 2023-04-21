% Function to replace getparticlemetrics.m
% April 19,2023
% Main changes
% 1. Option to read hist files remotely
% 2. CNN/trees and rules are applied to individual hist files
% 3. pStats_v0 is discarded. ParticlesImages are Included in pStats_v1
% 4. Optimized to work on lower RAM workstations

function processHistfiles(dest,pathtoHistfiles,rules,CNN)


% dest = 'ftp.archive.arm.gov';
% pathtoHistfiles = 'allwayinn1/holodec_data/IOP2_Flight1/recon';
if strcmp(dest,'local')
else
    ftpObj = ftp(dest);
    cd(ftpObj,pathtoHistfiles);
    histdetails = dir(ftpObj);
    histSegBoundary = divideHologram2Segments(histdetails);
    cd(ftpObj,'~')
    close(ftpObj)
end

if strcmp(predictionParams.method,'cnn') 
    predictionParams.model = predictionParams.model;
    predictionParams.pred_path = predictionParams.pred_path;
    pStats = predictionUsingCNN(pStats);
    
else   
    predictionParams.noisetree = predictionParams.tree.noisetree;
    predictionParams.particletree = predictionParams.tree.particletree; 
    pStats = predictionUsingDecisionTree(pStats);

end

for cnt2=1:length(histSegBoundary)-1
    
    unprcsdMetricsTable=[];
    prcsdMetricsTable=[];
    parfor cnt = histSegBoundary(cnt2):histSegBoundary(cnt2+1)
        
        try
            if strcmp(dest,'local')
                particledata=load(fullfile(histdetails(cnt).folder,histdetails(cnt).name));
            else
                ftpObj = ftp(dest);
                cd(ftpObj,pathtoHistfiles);
                mget(ftpObj,histdetails(cnt).name);
                particledata = load(histdetails(cnt).name);
                delete(histdetails(cnt).name);
                cd(ftpObj,'~')
                close(ftpObj)
            end
            metrics = particledata.pd.getmetrics;
            metrics.prtclIm = particledata.pd.getprtclIm;
            metrics.prtclID = particledata.pd.prtclID;
            
            
            tmp = struct2table(metrics);
            unprcsdMetricsTable = [unprcsdMetricsTable;tmp];
            fnames = fieldtnames(pStats.metrics)
            tmp = ApplyRules2HistMetrics(tmp,rules,fnames);
            
            if strcmp(predictionParams.method,'cnn') 
                tmp = predictionUsingCNN(tmp,predictionParams);
            else
                tmp = predictionUsingDecisionTree(tmp,predictionParams);
            end
            prcsdMetricsTable = [prcsdMetricsTable;tmp];
        catch
            warning([histdetails(cnt).name ' could not be read'])
            
        end
    end
end






end

function histSegBoundary = divideHologram2Segments(histdetails)

[userview,systemview] = memory;
matlabMemUsage = userview.MemUsedMATLAB;
totalSysMemory = userview.MemAvailableAllArrays;

sizeHist = [];

for cnt=1:length(histdetails)
    sizeHist(cnt) = histdetails(cnt).bytes;
end

cntr1=1;
histSegBoundary=[1];
for cntr2=1:length(histdetails)
    
    if sum(sizeHist(cntr1:cntr2)) >= (totalSysMemory-matlabMemUsage-2)
        cntr1 = cntr2 + 1;
        histSegBoundary= [histSegBoundary;cntr2];
    end
end

histSegBoundary(end+1) = length(histdetails);
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

temp1 = classificationData('prtclIm',metricsTable.prtclIm);
temp1.predict_NN(predictionParams.model,...
    predictionParams.pred_path)
classsification_cnn= readtable(fullfile(metricsTable.predictionParams.pred_path,...
    'dcnn_pred_pipeline.csv'));
ind = (classsification_cnn{:,2} == 0);

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