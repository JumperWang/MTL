function [ best_param, perform_mat] = CrossValidation2Param_withR...
    ( X, Y, obj_func_str, obj_func_opts, pr1, pr2, cv_fold, eval_func_str, higher_better)
%% Function CROSSVALIDATION1PARAM
%   Model selection (cross validation) for 2 parameters with graph R
%       multi-task learning functions
%   For usage see test_script.m
%
%% INPUT
%   X:             input data
%   Y:             output data
%   obj_func_str:  1-parameter optimization algorithms
%   pr1-pr2:       the range of the parameters
%   cv_fold:       cross validation fold
%   eval_func_str: evaluation function:
%       signature [performance_measure] = eval_func(Y_test, X_test, W_learnt)
%   higher_better: if the performance is better given
%           higher measurement (e.g., Accuracy, AUC)
%% OUTPUT
%   best_param:  best parameter in the given parameter range
%   perform_mat: the average performance for every parameter in the
%                parameter range.
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
%   You are suggested to first read the Manual.
%   For any problem, please contact with Jiayu Zhou via jiayu.zhou@asu.edu
%
%   Last modified on June 3, 2012.
%



eval_func = str2func(eval_func_str);
obj_func  = obj_func_str;


% compute sample size for each task
task_num = length(X);

% performance vector
% perform_mat = zeros(length(param_range),1);
perform_mat = zeros(length(pr1), length(pr2));

% begin cross validation
fprintf('[')
for cv_idx = 1: cv_fold
    fprintf('.')

    % buid cross validation data splittings for each task.
    cv_Xtr = cell(task_num, 1);
    cv_Ytr = cell(task_num, 1);
    cv_Xte = cell(task_num, 1);
    cv_Yte = cell(task_num, 1);

    for t = 1: task_num
        task_sample_size = length(Y{t});
        te_idx = cv_idx : cv_fold : task_sample_size;
        tr_idx = setdiff(1:task_sample_size, te_idx);

        cv_Xtr{t} = X{t}(tr_idx, :);
        cv_Ytr{t} = Y{t}(tr_idx, :);
        cv_Xte{t} = X{t}(te_idx, :);
        cv_Yte{t} = Y{t}(te_idx, :);
    end

    for p_i1 = 1: length(pr1)
        for p_i2 = 1: length(pr2)
                W = obj_func(cv_Xtr, cv_Ytr, pr1(p_i1), pr2(p_i2), ...
                obj_func_opts);
                perform_mat(p_i1, p_i2) = perform_mat(p_i1, p_i2) + ...
                eval_func(cv_Yte, cv_Xte, W);
            end
        end
    end

perform_mat = perform_mat./cv_fold;
fprintf(']\n')

if( higher_better)
    [~,best_idx] = max(perform_mat(:));
    [b1, b2] = ind2sub(size(perform_mat), best_idx);
else
    [~,best_idx] = min(perform_mat(:));
    [b1, b2] = ind2sub(size(perform_mat), best_idx);
end

best_param = [pr1(b1), pr2(b2)];

end

