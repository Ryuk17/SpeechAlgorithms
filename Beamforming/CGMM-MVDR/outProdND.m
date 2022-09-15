% given an ND tensor of size DxN1xN2xN3.., compute the outer product of the
% first dimension independently to return DxDxN1xN2xN3...
% 
function output = outProdND(data)

[D,N1,N2,N3] = size(data);
A = reshape(data,D, N1*N2*N3);

% B = permute(bsxfun(@times, A, conj(permute(A,[3 2 1]))), [1 3 2]); % slower
B = bsxfun(@times, permute(A, [1 3 2]), permute(conj(A), [3 1 2]));

output = reshape(B, D,D,N1,N2,N3);

end