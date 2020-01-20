function [ D, L, V ] = fitTensor( S, bMATRIX )

D  = bMATRIX \ -log( S + eps );
D  = [D(1) D(2) D(3); D(2) D(4) D(5); D(3) D(5) D(6)];

% calculate its eigenvalues and eigenvectors
[ V, L ] = eig(D);
L = diag(L);

% return them in "ascending" order (we generally assume the main direction to be oriented along z-axis)
[ ~, idx ] = sort( L, 'descend' );
L = L( idx );
V = V( :, idx );
