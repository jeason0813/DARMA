function [box] = reliability( X, Y )
%RELIABILITY Code to populate the reliability box based on number of raters
% License: https://carma.codeplex.com/license

	x_k = size(X,2);
    x_PCC = corr(X,'type','Pearson');
	x_cAlpha = x_k/(x_k-1)*(var(sum(X'))-sum(var(X)))/var(sum(X'));
    y_k = size(Y,2);
    y_PCC = corr(Y,'type','Pearson');
	y_cAlpha = y_k/(y_k-1)*(var(sum(Y'))-sum(var(Y)))/var(sum(Y'));
    
    if x_k == 1
        box = {'# Raters','1'; ...
            '[01] X Mean',num2str(mean(X),'%.0f'); ...
            '[01] X SD',num2str(std(X),'%.0f'); ...
            '[01] Y Mean',num2str(mean(Y),'%.0f'); ...
            '[01] Y SD',num2str(std(Y),'%.0f')};
    elseif x_k == 2
        box = {'# Raters','2'; ...
            'X Correlation',num2str(x_PCC(1,2),'%.3f'); ...
            'X Cronbach A',num2str(x_cAlpha,'%.3f'); ...
            '[01] X Mean',num2str(mean(X(:,1)),'%.0f'); ...
            '[02] X Mean',num2str(mean(X(:,2)),'%.0f'); ...
            '[01] X SD',num2str(std(X(:,1)),'%.0f'); ...
            '[02] X SD',num2str(std(X(:,2)),'%.0f'); ...
            'Y Correlation',num2str(y_PCC(1,2),'%.3f'); ...
            'Y Cronbach A',num2str(y_cAlpha,'%.3f'); ...
            '[01] Y Mean',num2str(mean(Y(:,1)),'%.0f'); ...
            '[02] Y Mean',num2str(mean(Y(:,2)),'%.0f'); ...
            '[01] Y SD',num2str(std(Y(:,1)),'%.0f'); ...
            '[02] Y SD',num2str(std(Y(:,2)),'%.0f')};
    elseif x_k > 2
        box = {'# Raters',num2str(x_k,'%d')};
        box = [box;{'X Cronbach A',num2str(x_cAlpha,'%.3f')}];
        for i = 1:x_k
            box = [box;{sprintf('[%02d] X Mean',i),num2str(mean(X(:,i)),'%.0f');}];
        end
        for i = 1:x_k
            box = [box;{sprintf('[%02d] X SD',i),num2str(std(X(:,i)),'%.0f');}];
        end
        box = [box;{'Y Cronbach A',num2str(y_cAlpha,'%.3f')}];
        for i = 1:y_k
            box = [box;{sprintf('[%02d] Y Mean',i),num2str(mean(Y(:,i)),'%.0f');}];
        end
        for i = 1:y_k
            box = [box;{sprintf('[%02d] Y SD',i),num2str(std(Y(:,i)),'%.0f');}];
        end
    end
    
end