% Program to do classification of the reconstructed holographic data

% Saving each sequence file
% this is for a single file. automate it to take all seq together

% RF=18;
% for k=8:12
%     
% for i=00:59
%     disp(sprintf('Seq%02d%02d',[k i]));
%     location = sprintf('/data/hulk/Nithin/RF%02d/seqdata/seqdata%02d/seq%02d/',[ RF k i]);
%     cd(location);
%     addpath /data/hulk/Nithin/RF18/Script
%     filename = sprintf('/data/hulk/Nithin/RF%02d/particledata/seq/seq%02d%02d.mat',[RF k i]);
%     [nullflag,inputdata] = getparticlemetrics();
%     
%     % [gp,data]     = ghostparticleanalyser(data);
%     if nullflag==0
%         data          = sortusingclassificationtree(inputdata,5000,particletree,noisetree);
%         save(filename, 'data')   
%         combinedfname = sprintf('/data/hulk/Nithin/RF%02d/particledata/sorteddata',RF);
%     
%         if ~exist('sorteddata','var')
%             sorteddata  = data;
%         else
%             fnames = fieldnames(data);
%             for j=1:length(fnames)
%                 sorteddata.(fnames{j}) = cat(1,sorteddata.(fnames{j}),data.(fnames{j}));
%             end
%         end
%     end
%     
% end
% end
% save(combinedfname,'sorteddata','-v7.3')
% % Combibing data to get a single data file
% cd('/homes/CLOUD/nallwayi/Documents/ACEENA/RF02/data/seqdata')
% 
% % Removing ghost particles and 
[particledata,gpindex,numgp,dist2d,label] = findghostparticles(sorteddata);
particledata = removeshattering(particledata,'chopoff');
% save('particledata','particledata','-v7.3')
[area2dvar,volume]=calculatevolume(particledata,label);
pd=calculatediameter(particledata);
output = data2bin(pd,volume);
save('output','output','-v7.3')