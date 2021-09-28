
%  Function to remove shattering effects
%  Initially it only involves chop-pff method but is to be later modified
%  to include throw-away, SV surgery and Particle repair methods 
function metrics = removeshattering(metrics,method)

if nargin<2
    method = 'chopoff';
elseif nargin<1 || nargin>2
    sprintf('Invalid number of inputs')
end


if isequal(method,'chopoff')
    index = metrics.zpos < 0.020 | metrics.zpos > 0.150;
    fnames = fieldnames(metrics);
    
    for i=1:length(fnames)
        metrics.(fnames{i})(index) = [];
    end
end


end
