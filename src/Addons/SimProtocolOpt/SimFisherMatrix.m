function J=SimFisherMatrix(obj,Prot,x,variables,sigma)
% Alexander, D.C., 2008. A general framework for experiment design in diffusion MRI and its application in measuring direct tissue-microstructure features. Magn. Reson. Med. 60, 439?448.
obj.Prot.(obj.MRIinputs{1}).Mat = Prot;
if ~exist('variables','var'), variables=1:5; end
if ~exist('sigma','var'), sigma=0.1; end

J=zeros(max(variables));
if ismethod(obj,'equation_x')
    S_nominal = obj.equation_x(x);
else
    S_nominal = obj.equation(x);
end
% Gaussian Noise
for i=variables
    for j=variables
        Xi = x;
        Xistep = max(1e-10,Xi(i) / 100);
        Xi(i) = Xi(i) + Xistep;
        Xj = x;
        Xjstep = max(1e-10,Xj(j) / 100);
        Xj(j) = Xj(j) + Xjstep;
        if ismethod(obj,'equation_x')
            J(i,j) = sum( 1./sigma.^2 .* (S_nominal - obj.equation_x(Xi))/Xistep .* (S_nominal - obj.equation_x(Xj))/Xjstep);
        else
            J(i,j) = sum( 1./sigma.^2 .* (S_nominal - obj.equation(Xi))/Xistep .* (S_nominal - obj.equation(Xj))/Xjstep);
        end
    end
end
J=J(variables,variables);


% % Rician Noise
% for i=1:variables
%     for j=variables
%         Xi=x;
%         Xi(i)=Xi(i)+Xi(i)/100;
%         Xj=x;
%         Xj(j)=Xj(j)+Xj(j)/100;
%         
%         A = scd_model_GPD_composite(x,Ax);
%         
%         Z=zeros(size(scheme,1),1);
%         for k=1:size(scheme,1)
%             Z(k) = integral(@(a) A(k)^2*besseli(1,A(k)*a/sigma^2)^2*besseli(0,A(k)*a/sigma^2)^-2  *a/sigma^2.*besseli(0,A(k)*a/sigma^2).*exp(-(A(k)^2+a^2)/2*sigma^2)  ,0,inf);
%         end
%         
%         dAi = (scd_model_GPD_composite(x,Ax)-scd_model_GPD_composite(Xi,Ax))/(x(i)/100);
%         dAj = (scd_model_GPD_composite(x,Ax)-scd_model_GPD_composite(Xj,Ax))/(x(j)/100);
%         
%         J(i,j)= sum(1/sigma^4.*(dAi.*dAj).*(Z-A.^2));
%     end
% end
% J=J(variables,variables);
% if J<0, error('bug'); end


end 

