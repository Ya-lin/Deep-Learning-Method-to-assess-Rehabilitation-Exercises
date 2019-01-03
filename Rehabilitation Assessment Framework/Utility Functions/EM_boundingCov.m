function [Priors, Mu, Sigma, Pix] = EM_boundingCov(Data, Priors0, Mu0, Sigma0)
%
% This function learns the parameters of a Gaussian Mixture Model 
% (GMM) using a recursive Expectation-Maximization (EM) algorithm, starting 
% from an initial estimation of the parameters. After each EM step, the
% covariance matrices are bounded to avoid numerical instability.
%
% Inputs -----------------------------------------------------------------
%   o Data:    D x N array representing N datapoints of D dimensions.
%   o Priors0: 1 x K array representing the initial prior probabilities 
%              of the K GMM components.
%   o Mu0:     D x K array representing the initial centers of the K GMM 
%              components.
%   o Sigma0:  D x D x K array representing the initial covariance matrices 
%              of the K GMM components.
% Outputs ----------------------------------------------------------------
%   o Priors:  1 x K array representing the prior probabilities of the K GMM 
%              components.
%   o Mu:      D x K array representing the centers of the K GMM components.
%   o Sigma:   D x D x K array representing the covariance matrices of the 
%              K GMM components.
%
% Copyright (c) 2006 Sylvain Calinon, LASA Lab, EPFL, CH-1015 Lausanne,
%               Switzerland, http://lasa.epfl.ch
%
% This program is free for non-commercial academic use. 
% Please contact the authors if you are interested in using the software 
% for commercial purposes. 
% Please acknowledge the authors in any academic publications that have 
% made use of this code or part of it, by using the following BibTex 
% reference: 
% 
% @inproceedings{Calinon07HRI,
%   author = "S. Calinon and A. Billard",
%   title = "Incremental Learning of Gestures by Imitation in a Humanoid 
%     Robot",
%   booktitle = "Proceedings of the {ACM/IEEE} International Conference on 
%     Human-Robot Interaction ({HRI})",
%   year = "2007",
%   month="March",
%   location="Arlington, VA, USA",
%   pages="255--262"
% }

%% Criterion to stop the EM iterative update
loglik_threshold = 1e-10;
[nbVar, nbData] = size(Data);
nbStates = size(Sigma0,3);
loglik_old = -realmax;
nbStep = 0;

Mu = Mu0;
Sigma = Sigma0;
Priors = Priors0;

%% EM fast matrix computation (see the commented code for a version 
%% involving one-by-one computation, which is easier to understand)
while 1
  %% E-step %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for i=1:nbStates
    %Compute probability p(x|i)
    Pxi(:,i) = gaussPDF(Data, Mu(:,i), Sigma(:,:,i));
  end
  %Compute posterior probability p(i|x)
  Pix_tmp = repmat(Priors,[nbData 1]).*Pxi;
  Pix = Pix_tmp ./ repmat(sum(Pix_tmp,2),[1 nbStates]);
  %Compute cumulated posterior probability
  E = sum(Pix);
  %% M-step %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for i=1:nbStates
    %Update the priors
    Priors(i) = E(i) / nbData;
    %Update the centers
    Mu(:,i) = Data*Pix(:,i) / E(i);
    %Update the covariance matrices
    Data_tmp1 = Data - repmat(Mu(:,i),1,nbData);
    Data_tmp2a = repmat(reshape(Data_tmp1,[nbVar 1 nbData]), [1 nbVar 1]);
    Data_tmp2b = repmat(reshape(Data_tmp1,[1 nbVar nbData]), [nbVar 1 1]);
    Data_tmp2c = repmat(reshape(Pix(:,i),[1 1 nbData]), [nbVar nbVar 1]);
    Sigma(:,:,i) = sum(Data_tmp2a.*Data_tmp2b.*Data_tmp2c, 3) / E(i);
    %% Add a tiny variance to avoid numerical instability
    Sigma(:,:,i) = Sigma(:,:,i) + 1E-5.*diag(ones(nbVar,1));
  end
  %% Stopping criterion %%%%%%%%%%%%%%%%%%%%
  for i=1:nbStates
    %Compute the new probability p(x|i)
    Pxi(:,i) = gaussPDF(Data, Mu(:,i), Sigma(:,:,i));
  end
  %Compute the log likelihood
  F = Pxi*Priors';
  F(find(F<realmin)) = realmin;
  loglik = mean(log(F));
  %Stop the process depending on the increase of the log likelihood 
  if abs((loglik/loglik_old)-1) < loglik_threshold
    break;
  end
  loglik_old = loglik;
  nbStep = nbStep+1;
end

% %% EM slow one-by-one computation (better suited to understand the
% %% algorithm) 
% while 1
%   %% E-step %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   for i=1:nbStates
%     %Compute probability p(x|i)
%     Pxi(:,i) = gaussPDF(Data, Mu(:,i), Sigma(:,:,i));
%   end
%   %Compute posterior probability p(i|x)
%   for j=1:nbData
%     Pix(j,:) = (Priors.*Pxi(j,:))./(sum(Priors.*Pxi(j,:))+realmin);
%   end
%   %Compute cumulated posterior probability
%   E = sum(Pix);
%   %% M-step %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   for i=1:nbStates
%     %Update the priors
%     Priors(i) = E(i) / nbData;
%     %Update the centers
%     Mu(:,i) = Data*Pix(:,i) / E(i);
%     %Update the covariance matrices 
%     covtmp = zeros(nbVar,nbVar);
%     for j=1:nbData
%       covtmp = covtmp + (Data(:,j)-Mu(:,i))*(Data(:,j)-Mu(:,i))'.*Pix(j,i);
%     end
%     Sigma(:,:,i) = covtmp / E(i);
%     %% Add a tiny variance to avoid numerical instability
%     Sigma(:,:,i) = Sigma(:,:,i) + 1E-4.*diag(ones(nbVar,1));
%   end
%   %% Stopping criterion %%%%%%%%%%%%%%%%%%%%
%   for i=1:nbStates
%     %Compute the new probability p(x|i)
%     Pxi(:,i) = gaussPDF(Data, Mu(:,i), Sigma(:,:,i));
%   end
%   %Compute the log likelihood
%   F = Pxi*Priors';
%   F(find(F<realmin)) = realmin;
%   loglik = mean(log(F));
%   %Stop the process depending on the increase of the log likelihood 
%   if abs((loglik/loglik_old)-1) < loglik_threshold
%     break;
%   end
%   loglik_old = loglik;
%   nbStep = nbStep+1;
% end


