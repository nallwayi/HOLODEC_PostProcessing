function pStats  = processhistmetrics(pStats,rules,predictionParams)

if exist('rules','var')
    pStats.rules = rules;
end


% Rules to remove artifacts from hist files
    fnames = fieldnames(pStats.metrics);       
for cnt = 1:size(pStats.rules,1)
    fncn=str2func(pStats.rules{cnt,2});
    tmp = fncn(pStats.metrics.(pStats.rules{cnt,1}),pStats.rules{cnt,3});
    for cnt2=1:length(fnames)
        pStats.metrics.(fnames{cnt2})(~tmp)=[];
    end
%     pStats.metrics(~tmp,:)=[];
% %     for cnt=1:length(tmp)
% %         if ~tmp(cnt)
% %             pStats.metrics(cnt,:)=[];
% %         end
% %     end
end


pStats.predictionParams.method = predictionParams.method;
if strcmp(predictionParams.method,'cnn') 
    pStats.predictionParams.model = predictionParams.model;
    pStats.predictionParams.pred_path = predictionParams.pred_path;
    pStats = predictionUsingCNN(pStats);
    
else   
    pStats.predictionParams.noisetree = predictionParams.tree.noisetree;
    pStats.predictionParams.particletree = predictionParams.tree.particletree; 
    pStats = predictionUsingDecisionTree(pStats);

end


end

function pStats = predictionUsingCNN(pStats)

temp1 = classificationData('prtclIm',pStats.metrics.prtclIm);
temp1.predict_NN(pStats.predictionParams.model,...
    pStats.predictionParams.pred_path)
classsification_cnn= readtable(fullfile(pStats.predictionParams.pred_path,...
    'dcnn_pred_pipeline.csv'));
ind = (classsification_cnn{:,2} == 0);
fnames = fieldnames(pStats.metrics);
for cnt=1:length(fnames)
    pStats.metrics.(fnames{cnt})(ind)=[];
end

end

function pStats = predictionUsingDecisionTree(pStats)

nind=[];
pind=[];
    for cnt=1:length(pStats.holoinfo)
        ind = find(pStats.metrics.holotimes == pStats.holoinfo(cnt,3));
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

    fnames = fieldnames(pStats.metrics);
    
    if ~isempty(nind)
        for cnt=1:length(fnames)
            nthis.(fnames{cnt}) = pStats.metrics.(fnames{cnt})(nind);
        end
        nthis = sortusingclassificationtree...
            (nthis,pStats.predictionParams.noisetree);
    end
    
    if ~isempty(pind)
        for cnt=1:length(fnames)
            pthis.(fnames{cnt}) = pStats.metrics.(fnames{cnt})(pind);            
        end
        pthis = sortusingclassificationtree...
            (pthis,pStats.predictionParams.particletree);
    end
    
    if exist('nthis','var') && exist('pthis','var')
        for cnt2=1:length(fnames)
            pStats.metrics.(fnames{cnt2}) ...
                = cat(1,nthis.(fnames{cnt2})...
                ,pthis.(fnames{cnt2}));
        end
    elseif exist('pthis','var')
        for cnt2=1:length(fnames)
            pStats.metrics.(fnames{cnt2}) ...
                = pthis.(fnames{cnt2});
        end
    else
        for cnt2=1:length(fnames)
            pStats.metrics.(fnames{cnt2}) ...
                = nthis.(fnames{cnt2});
        end
        
    end
    unsortedTable = struct2table(pStats.metrics);
    
    pStats.metrics=[];
    sortedT = sortrows(unsortedTable, 'holonum');
    for cnt2=1:length(fnames)
        pStats.metrics.(fnames{cnt2}) = sortedT.(fnames{cnt2})(:);
    end   
    
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


    table = struct2table(this);
%     table=this;
    ind = predict(tree,table)== 'Particle_round';
%     this = this(ind,:);
    fnames = fieldnames(this);
    for cnt=1:length(fnames)
        this.(fnames{cnt}) = this.(fnames{cnt})(ind);
    end

end