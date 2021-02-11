% Function to generate the particle metrics from the hist files  
% Rules for automatic classification and decision tree is applied here
% These rules can be edited
% SYNTAX:  
%          getparticlemetrics(rules)   
%  eg:
%       getparticlemetrics({'pixden','ge',0.79;'dsqoverlz','le',2;...
%           'underthresh','ge',0.04;'asprat','le',1.5})

function pStats = getparticlemetrics(rules)
    tic

%     Loading the appropriate trees
%     load 'particletree.mat' particletree
    load 'particletree.mat' particletree
    load 'noisetree.mat' noisetree
    
    pathtohistmat=pwd;
    histdetails = dir(fullfile(pathtohistmat,'*hist.mat'));



%   Extracting time details for ACE-ENA pmetrics
    holotimes  = length(histdetails);
    holonum    = length(histdetails);
    timestamp  = length(histdetails);
    holosecond = length(histdetails);
       
    for cnt = 1:length(histdetails)
        tmp = histdetails(cnt).name;
        tmp = tmp(end-34:end-9);
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
    pStats.header      = histdetails(1).name(1:end-36);
    pStats.noholograms = noholograms;
    
    %     Saving info about all processed holograms
    holoinfo   = nan(length(histdetails),2);
    holoinfo(:,1) = holotimes;
    holoinfo(:,2) = holosecond;
    pStats.holoinfo = holoinfo;
    
    
%     particledata=load(fullfile(pathtohistmat,histdetails(1).name));
%     pStats.metricnames = particledata.pd.metricnames;   
%     
%     if ~any(strcmp(pStats.metricnames,'pixden'))
%         pStats.metricnames{end+1} = 'pixden';
%     end
%     if ~any(strcmp(pStats.metricnames,'holotimes'))
%         pStats.metricnames{end+1} = 'holotimes';
%     end
%     if ~any(strcmp(pStats.metricnames,'timestamp'))
%         pStats.metricnames{end+1} = 'timestamp';
%     end
%     if ~any(strcmp(pStats.metricnames,'holonum'))
%         pStats.metricnames{end+1} = 'holonum';
%     end
%    
% %    Determining index of predefined rules 
%     
%      if exist('rules','var')
%         ruleVar = [];
%         for cnt = 1:size(size(rules,1))
%             tmp = find((strcmp(rules{cnt,1},pStats.metricnames)) == 1);
%             ruleVar = [ruleVar;tmp]; 
%         end
%      end
%             
%     
% %        Saving the metrics
%     pStats.metricmat = [];
%     for cnt=length(histdetails)-20:length(histdetails)
%         particledata=load(fullfile(pathtohistmat,histdetails(cnt).name));
%         pixden    = 4*particledata.pd.getmetric('area')./...
%             (pi*particledata.pd.getmetric('minsiz').*...
%             particledata.pd.getmetric('majsiz'));
%         metricmat = [particledata.pd.metricmat];
%         metricmat(:,end+1) = pixden;
%         metricmat(:,end+1) = ones(length(pixden),1)*holotimes(cnt);
%         metricmat(:,end+1) = ones(length(pixden),1)*timestamp(cnt);
%         metricmat(:,end+1) = ones(length(pixden),1)*holonum(cnt);
%         
% %         Applying the dynamic rules
% 
%         pStats.metricmat = [pStats.metricmat;metricmat];
%     end
%     
    
         particledata=load(fullfile(pathtohistmat,histdetails(1).name));
         metricnames = [particledata.pd.metricnames;'pixden';'holotimes';...
             'timestamp';'holosecond';'holonum'];
         for i=1:length(metricnames)
            pStats.metrics.(metricnames{i})=[];
         end
         
         
         for cnt=1:length(histdetails)
            particledata=load(fullfile(pathtohistmat,histdetails(cnt).name));
            metrics = particledata.pd.getmetrics;
            
%           Adding pixden rule if it dosent exist
            if ~isfield(metrics,'pixden')
                metrics.pixden = 4*metrics.area./(pi*metrics.minsiz.*metrics.majsiz);
            end
            
%           Rules to remove artifacts from hist files
            ind = 1:length(metrics.pixden);
            for cnt2 = 1:size(rules,1)
                fncn=str2func(rules{cnt2,2});
                tmp = fncn(metrics.(rules{cnt2,1}),rules{cnt2,3}); 
                ind = intersect(ind,find(tmp ==1));
            end
%             ind = find(metrics.pixden >= 0.79 & metrics.dsqoverlz <=2 &...
%                 metrics.underthresh >= 0.04 & metrics.asprat<=1.5) ;
            
%           Adding holonum, holotimes and timestamp

            metrics.holotimes = ones((length(metrics.pixden)),1)*holotimes(cnt);
            metrics.timestamp = ones((length(metrics.pixden)),1)*timestamp(cnt);
            metrics.holonum   = ones((length(metrics.pixden)),1)*holonum(cnt);
            metrics.holosecond   = ones((length(metrics.pixden)),1)*holosecond(cnt);

           
            
            if ~isempty(ind)
                fnames = fieldnames(metrics);
                for cnt2=1:length(fnames)
                    metrics.(fnames{cnt2}) = metrics.(fnames{cnt2})(ind);
                end
                % Sorting the data in a hologram using classification trees
                threshold = 10;
                if length(ind)<=threshold
                    tree = noisetree;
                else
                    tree = particletree;
                end
                metrics = sortusingclassificationtree(metrics,tree);
                
                
%               Saving the predicted particles from each hologram
                for cnt2=1:length(fnames)
                    pStats.metrics.(fnames{cnt2}) ...
                        = cat(1,pStats.metrics.(fnames{cnt2})...
                        ,metrics.(fnames{cnt2}));
                end
            end
            
         end  
      
    toc 
end

function metrics = sortusingclassificationtree(metrics,tree)
    table = struct2table(metrics);
    ind = predict(tree,table)== 'Particle_round';

    fnames = fieldnames(metrics);
    for i=1:length(fnames)
        metrics.(fnames{i}) = metrics.(fnames{i})(ind);
    end

end