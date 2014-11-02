%% SCRIPT test_script.m
%   Multi-task learning training/testing example. This example illustrates
%   how to perform split data into training part and testing part, and how
%   to use training data to build prediction model (via cross validation).
%
%% LICENSE
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%   Copyright (C) 2011 - 2012 Jiayu Zhou and Jieping Ye
%
%% Related functions
%   mtSplitPerc, CrossValidation1Param, Least_Trace

clear; clc;

addpath('../../MALSAR/functions/Lasso/');
addpath('../../MALSAR/utils/');


% load data
load_data = load('../../data/school.mat');

X = load_data.X;
Y = load_data.Y;

% preprocessing data
for t = 1: length(X)
    X{t} = zscore(X{t});                  % normalization
    X{t} = [X{t}(:,1:end-1) ones(size(X{t}, 1), 1)]; % add bias.
end

% split data into training and testing.
training_percent = 0.8;
[X_tr, Y_tr, X_te, Y_te] = mtSplitPerc(X, Y, training_percent);

num_tasks = length(X_tr);
p = size(X_tr{1}, 2);
t_params = zeros(1, num_tasks);

% cross validation fold
cv_fold = 5;
% optimization options
opts = [];
opts.maxIter = 100;
param_range = [0.001 0.01 0.1 1 10 100 1000 10000];

% train a separate weight using lasso per task
% CrossValidation1Param
for t = 1:num_tasks
    fprintf('Processing task %i\n', t);
    % t_X = cell2mat(X_tr(t));
    % t_y = cell2mat(Y_tr(t));
    % [B, FitInfo] = lasso(t_X, t_y, 'Alpha', 1, 'CV', 5, 'Lambda', param_range, ...
    % 'Standardize', false);
    % [B, FitInfo] = lasso(t_X, t_y, 'Alpha', 1, 'CV', 5); % use default settings
    % [~, idx] = min(FitInfo.MSE);

    % Use Lasso in the MALSAR package
    [ best_param, perform_mat ] = CrossValidation1Param...
    ( X_tr(t), Y_tr(t), 'Least_Lasso', opts, param_range, cv_fold, 'eval_MTL_mse', false);
    t_params(1, t) = best_param;
end

% testing for num_repeat times
num_repeat = 50;
Errors = [num_repeat, 4];
for r = 1:num_repeat
    fprintf('Repate %i\n', r);
    % split data into training and testing.
    training_percent = 0.8;
    [X_tr, Y_tr, X_te, Y_te] = mtSplitPerc(X, Y, training_percent);
    W = zeros(p, num_tasks);

    % Training
    for t = 1:num_tasks
        w = Least_Lasso(X_tr(t), Y_tr(t), t_params(1,t), opts);
        W(:,t) = w;
    end

    % Testing
    [mse, rss, tss] = eval_MTL_mse(Y_te, X_te, W);
    Errors(r, 1:3) = [mse, rss, tss];
end

Errors(:,4) = 1 - ( Errors(:, 2) ./ Errors(:, 3) );

