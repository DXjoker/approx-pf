m = size(X,1);

CB = eye(m);
B = zeros(m,m,m);

for nd = 1:m

	B(:,:,nd) = (X' * diag(CB(nd,:)) * X);

end

y0 = zeros(m,1);
[mm ii] = max((norm(X',2,'cols')));
y0(ii) = 1;

[ymin val] = sqp(y0, @(y) -minlambda(y, B), {@sumone,@allone}, [], 0, 1);

fprintf(1, 'rho-star: %f\n', sqrt(-val))
