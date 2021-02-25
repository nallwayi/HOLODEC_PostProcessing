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



    for cnt=1:length(pStats.holoinfo)
        ind = pStats.metrics.holotimes == pStats.holoinfo(cnt,3);
        if ~isempty(ind)
        	% Sorting the data in a hologram using classification trees
        	threshold = 10;
            if sum(ind)<=threshold
            	tree = pStats.noisetree;
            else
                tree = pStats.particletree;
            end
                pStats.metrics = sortusingclassificationtree(pStats.metrics,tree);     
        end
    end

end
function this = sortusingclassificationtree(this,tree)
    table = struct2table(this);
    ind = predict(tree,table)== 'Particle_round';

    fnames = fieldnames(this);
    for i=1:length(fnames)
        this.(fnames{i}) = this.(fnames{i})(ind);
    end

end