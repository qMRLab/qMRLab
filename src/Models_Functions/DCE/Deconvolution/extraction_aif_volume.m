function [aif,scores] = extraction_aif_volume(VOX,ROI)
% [aif,scores] = extraction_aif(SLICE,ROI)
%
% Select voxels for AIF
%
% INPUTS :
% VOX : Slice for selecting voxels (4D : [Height,Width,Slices,Dynamics])
%
% OUTPUTS :
% aif : mean of the selected voxels
% score : score of each selected voxel and the number of warning and the
%         reasons
%
% 20/03/2013 (Thomas Perret : <thomas.perret@grenoble-inp.fr>)
% Last modified : 22/05/2013 (TP)
%  - Add input in 4D
%%% Rapport de la longueur des donnees

wmaxr = 0.5; %%% Rapport de la longueur des donnees
nb_vox_cand = 50;
nb_vox = 5;

scores = cell(nb_vox,9);

[Hvox,Wvox,Sli,Dvox] = size(VOX);
wmax = round(wmaxr * Dvox);

%%% Selection de la ROI
BINSEL = ROI;

%%% Enlever les voxels inf et Nan (pas forcement necessaire) %%%
BINSEL = BINSEL & ~any(isinf(VOX),4) & ~any(isnan(VOX),4);

%%% Enlever les voxel nuls %%%
nnul = all(VOX,4);
BINSEL = BINSEL & nnul;

%%% Enlever les voxels 'bruits' %%%
MOY = mean2(mean2(VOX(repmat(BINSEL,[1 1 1 Dvox]))));
NOISY = mean(VOX,4) < MOY;
BINSEL = BINSEL & ~NOISY;

%%% Calcul de la hauteur des pics %%%
BL = zeros(Hvox,Wvox,Sli);
MINVOX = zeros(Hvox,Wvox,Sli);
BL(BINSEL) = mean(reshape(VOX(cat(4,false(Hvox,Wvox,Sli),repmat(BINSEL,[1 1 1 5]))),[],5),2);
MINVOX(BINSEL) = min(reshape(VOX(repmat(BINSEL,[1 1 1 Dvox])),[],Dvox),[],2);
HP = BL - MINVOX;

%%% Calcul de la largeur des pics %%%
WP = Dvox*ones(Hvox,Wvox,Sli);
for i=findn(BINSEL).'
    if ~isempty(find(VOX(i(1),i(2),i(3),:) <= (MINVOX(i(1),i(2),i(3))+HP(i(1),i(2),i(3))/2),1))
        WP(i(1),i(2),i(3)) = find(VOX(i(1),i(2),i(3),:) <= (MINVOX(i(1),i(2),i(3))+HP(i(1),i(2),i(3))/2),1,'last') - find(VOX(i(1),i(2),i(3),:) <= (MINVOX(i(1),i(2),i(3))+HP(i(1),i(2),i(3))/2),1);
    end
end
WP(WP == 0) = Dvox;

%%% Garder que les voxels non saturés %%%
SVOX = zeros(Hvox,Wvox,Sli);
% ECTVOX = zeros(Hvox,Wvox,Sli);
% for i=findn(BINSEL).'
%     ECTVOX(i(1),i(2),i(3)) = std(VOX(i(1),i(2),i(3),2:6),0,4);
%     SVOX(i(1),i(2),i(3)) = numel(find(VOX(i(1),i(2),i(3),:) <= (MINVOX(i(1),i(2),i(3))+4*ECTVOX(i(1),i(2),i(3))))) > 2;
% end
for v=findn(BINSEL).'
    t1 = find(VOX(v(1),v(2),v(3),:) <= min(VOX(v(1),v(2),v(3),:),[],4)+4*std(VOX(v(1),v(2),v(3),2:6),0,4),1,'first');
    t2 = find(VOX(v(1),v(2),v(3),:) <= min(VOX(v(1),v(2),v(3),:),[],4)+4*std(VOX(v(1),v(2),v(3),2:6),0,4),1,'last');
    SVOX(v(1),v(2),v(3)) = any(diff(VOX(v(1),v(2),v(3),t1:t2),2,4) < 0);
end
BINSEL = BINSEL & ~SVOX;

%%% Garder que les voxels dont la largeur est inférieur à une valeur %%%
BINSEL = BINSEL & WP < wmax & WP > 0;

TMPDATA = VOX;
TMPDATA(~repmat(BINSEL,[1 1 1 Dvox])) = zeros;
TMPDATA = reshape(TMPDATA,[],Dvox);

%%% Trie des voxels, on recalcule la hauteur avant pour enlever les voxels
%%% dont la largeur est trop importante %%%
HP(~BINSEL) = 0;
TMPHP = HP(:);
[~,trie] = sort(TMPHP,'descend');

%%% Calcul du score %%%
[~,MININD] = min(VOX,[],4);
score = zeros(nb_vox_cand,1);
for i=1:nb_vox_cand
    %%% Calcul du temps d'arrivee %%%
    t0 = BAT(TMPDATA(trie(i),:));
    initslop = HP(trie(i))/(MININD(trie(i))-t0);
    score(i) = (HP(trie(i)).*initslop) / (WP(trie(i)).*t0);
end

[~,trie_score] = sort(score,'descend');
aif = mean(TMPDATA(trie(trie_score(1:nb_vox)),:),1);

BINSEL = false(Hvox,Wvox,Sli);
for i=1:nb_vox
    BINSEL(trie(trie_score(i)))=true;
end

[I,J,K] = ind2sub([Hvox Wvox Sli],trie(trie_score(1:nb_vox)));
for v=1:nb_vox
    warn = 0;
    scores(v,1:4) = {score(trie_score(v)) I(v) J(v) K(v)};
    
    %%% Test de la baseline pre-bolus
    ect_basepre = std(TMPDATA(trie(trie_score(v)),2:6),0,2);
    basepre = mean(TMPDATA(trie(trie_score(v)),2:6),2);
    if ect_basepre >= basepre/10
        warn = warn + 1;
        scores{v,5+warn} = 'La baseline pre-bolus du voxel est trop bruitee';
    end
    
    %%% Test de la baseline post-bolus
    ect_basepost = std(TMPDATA(trie(trie_score(v)),end-5:end),0,2);
    basepost = mean(TMPDATA(trie(trie_score(v)),end-5:end),2);
    if ect_basepost >= basepost/10
        warn = warn + 1;
        scores{v,5+warn} = 'La baseline post-bolus du voxel est trop bruitee';
    end
    
    %%% Test du point a t0
    t0 = BAT(TMPDATA(trie(trie_score(v)),:));
    if t0<40
        if TMPDATA(trie(trie_score(v)),t0) >= 11*basepre/10
            warn = warn + 1;
            scores{v,5+warn} = 'La valeur a t0 du voxel est trop importante';
        end
    end
    
    %%% Test de la longueur de la baseline pre-bolus
    if t0 < 8
        warn = warn + 1;
        scores{v,5+warn} = 'La baseline du voxel est trop courte';
    end
    scores{v,5} = warn;
end
end

function t0 = BAT(voxel)
% function t0 = BAT(voxel)
% Compute Bolus Arrival Time
%
% INPUT :
%
% OUTPUTS :
%
% 20/03/2013 (Thomas Perret : <thomas.perret@grenoble-inp.fr>)
% Last modified : 20/03/2013 (TP)

% Parameters of algorithm
window_size = 8;
th = 2.0;

D = numel(voxel);
moy = zeros(1,D-window_size);
ect = zeros(1,D-window_size);
for t = 1:D-window_size
    moy(t) = mean(voxel(t:t+window_size));
    ect(t) = std(voxel(t:t+window_size));
end
Tlog = voxel(window_size+1:D) < (moy - th.*ect);
[~,t0] = max(Tlog);
t0 = t0 + window_size - 1;
[~,ttp] = min(voxel);
if t0 == window_size || t0 > ttp
    t0 = 40;
end
end

function ind=findn(arr)

%FINDN   Find indices of nonzero elements.
%   I = FINDN(X) returns the indices of the vector X that are
%   non-zero. For example, I = FINDN(A>100), returns the indices
%   of A where A is greater than 100. See RELOP.
%  
%   This is the same as find but works for N-D matrices using 
%   ind2sub function
%
%   It does not return the vectors as the third output arguement 
%   as in FIND
%   
%   The returned I has the indices (in actual dimensions)
%
%   x(:,:,1)            x(:,:,2)            x(:,:,3)
%       = [ 1 2 3           =[11 12 13        =[21 22 23
%           4 5 6             14 15 16          24 25 26
%           7 8 9]            17 18 19]         27 28 29]
%
%   I=find(x==25) will return 23
%   but findn(x==25) will return 2,2,3
%   
%   Also see find, ind2sub

%   Loren Shure, Mathworks Inc. improved speed on previous version of findn
%   by Suresh Joel Mar 3, 2003

in=find(arr);
sz=size(arr);
if isempty(in), ind=[]; return; end;
[out{1:ndims(arr)}] = ind2sub(sz,in);
ind = cell2mat(out);
end