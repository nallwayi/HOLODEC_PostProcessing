function pStats  = processhistmetrics(pStats)

% Rules to remove artifacts from hist files

    fnames = fieldnames(pStats.metrics);       
for cnt = 1:size(pStats.rules,1)
    fncn=str2func(pStats.rules{cnt,2});
    tmp = fncn(pStats.metrics.(pStats.rules{cnt,1}),pStats.rules{cnt,3});
    for cnt2=1:length(fnames)
        pStats.metrics.(fnames{cnt2})(~tmp)=[];
    end
end


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

    
    for cnt=1:length(fnames)
        nthis.(fnames{cnt}) = pStats.metrics.(fnames{cnt})(nind); 
    end
    nthis = sortusingclassificationtree(nthis,pStats.noisetree);
    
    for cnt=1:length(fnames)
        pthis.(fnames{cnt}) = pStats.metrics.(fnames{cnt})(pind); 
    end
    pthis = sortusingclassificationtree(pthis,pStats.particletree);
    
    for cnt2=1:length(fnames)
    pStats.metrics.(fnames{cnt2}) ...
    = cat(1,nthis.(fnames{cnt2})...
    ,pthis.(fnames{cnt2}));
    end
    unsortedTable = struct2table(pStats.metrics);
    pStats.metrics = sortrows(unsortedTable, 'holonum');

end
function this = sortusingclassificationtree(this,tree)
    table = struct2table(this);
    ind = predict(tree,table)== 'Particle_round';

    fnames = fieldnames(this);
    for i=1:length(fnames)
        this.(fnames{i}) = this.(fnames{i})(ind);
    end

end