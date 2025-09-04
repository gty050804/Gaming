classdef Master < handle
    properties
        fig
        ax
        board
        redPos
        bluePos
        currentPlayer % 1 for red (AI), 2 for blue (玩家)
        gameOver
        roundOver
        statusText
        scoreText
        restartButton
        nextRoundButton
        
        % 比赛统计
        roundNumber
        aiWins
        playerWins
        totalRounds = 7;
        winsNeeded = 4;

        % AI 能力属性（各属性数值仅与彼此的比例有关，将4个属性都调成100和都调成0.01没有区别。）
        % 体感4个参量分别设置为0.5 0.05 1.2 0.45性能较好。
        depth_weight = 2;     % 远见值：AI对空间的利用效率提高，即在相同的空格中走出更多的步数。
        node_weight = 0.4;     % 后备值：AI的每一步走棋带来更多的后备选择，减少意外发生。
        control_weight = 0.8;  % 攻击值：AI的进攻性增强，尽可能减少玩家的选择。
        defense_weight = 0.35;  % 防御值：AI的反侦察意识增强，减少被玩家封堵的可能。
        kill_weight = 10000;    
        killed_weight = 0.5;    

    end
    
    methods
        function obj = Master()
            % 初始化游戏
            obj.fig = figure('Name', 'HorseRacing Game', 'NumberTitle', 'off', ...
                'Position', [300, 100, 900, 700], 'MenuBar', 'none', ...
                'Color', [0.8 0.8 0.8]);
            
            obj.ax = axes('Parent', obj.fig, 'Position', [0.05 0.2 0.9 0.75]);
            axis equal;
            axis off;
            hold on;
            
            % 初始化比赛统计
            obj.roundNumber = 1;
            obj.aiWins = 0;
            obj.playerWins = 0;
            
            % 开始新的一局
            obj.startNewRound();
        end
        
        function startNewRound(obj)
            
            cla(obj.ax);
            hold on;
       
            obj.createBoard();

            obj.redPos = [1, 1];
            obj.bluePos = [7, 7];
            obj.currentPlayer = 2; % 蓝方(玩家)先行
            obj.gameOver = false;
            obj.roundOver = false;
            
            % 绘制初始棋子
            obj.drawPieces();
            
            % 添加状态文本
            if isempty(obj.statusText) || ~isvalid(obj.statusText)
                obj.statusText = uicontrol('Style', 'text', 'Position', [50, 20, 300, 30], ...
                    'String', sprintf('第%d局 - 玩家回合(蓝方)', obj.roundNumber), ...
                    'FontSize', 14, 'BackgroundColor', [0.8 0.8 0.8], ...
                    'ForegroundColor', [0 0 1]);
            else
                set(obj.statusText, 'String', sprintf('第%d局 - 玩家回合(蓝方)', obj.roundNumber), ...
                    'ForegroundColor', [0 0 1]);
            end
            
            % 添加比分文本
            if isempty(obj.scoreText) || ~isvalid(obj.scoreText)
                obj.scoreText = uicontrol('Style', 'text', 'Position', [400, 20, 200, 30], ...
                    'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins), ...
                    'FontSize', 14, 'BackgroundColor', [0.8 0.8 0.8]);
            else
                set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
            end

            if isempty(obj.restartButton) || ~isvalid(obj.restartButton)
                obj.restartButton = uicontrol('Style', 'pushbutton', 'Position', [650, 50, 100, 30], ...
                    'String', '重新开始', 'FontSize', 12, 'Callback', @(src,evt)obj.restartGame());
            end

            if isempty(obj.nextRoundButton) || ~isvalid(obj.nextRoundButton)
                obj.nextRoundButton = uicontrol('Style', 'pushbutton', 'Position', [650, 20, 100, 30], ...
                    'String', '下一局', 'FontSize', 12, 'Visible', 'off', ...
                    'Callback', @(src,evt)obj.nextRound());
            else
                set(obj.nextRoundButton, 'Visible', 'off');
            end
            
            % 设置棋盘点击回调
            set(obj.fig, 'WindowButtonDownFcn', @(src,evt)obj.boardClick());
        end
        
        function restartGame(obj)
            % 完全重新开始游戏
            obj.roundNumber = 1;
            obj.aiWins = 0;
            obj.playerWins = 0;
            obj.startNewRound();
        end
        
        function nextRound(obj)
            % 开始下一局比赛
            if obj.roundNumber < obj.totalRounds && obj.aiWins < obj.winsNeeded && obj.playerWins < obj.winsNeeded
                obj.roundNumber = obj.roundNumber + 1;
                obj.startNewRound();
            else
                obj.restartGame();
            end
        end
        
        function createBoard(obj)
            % 创建7x7棋盘
            obj.board = zeros(7, 7);
            
            % 绘制棋盘格子
            for i = 1:7
                for j = 1:7
                    if mod(i+j, 2) == 0
                        color = [1, 1, 1]; % 白色
                    else
                        color = [0.9, 0.9, 0.9]; % 浅灰色
                    end
                    
                    rectangle('Position', [j-0.5, 8-i-0.5, 1, 1], ...
                             'FaceColor', color, 'EdgeColor', [0.5 0.5 0.5], ...
                             'LineWidth', 1.5);
                    text(j, 8-i, sprintf('%d,%d', i, j), ...
                         'HorizontalAlignment', 'center', 'FontSize', 8);
                end
            end
            
            % 设置坐标轴范围
            xlim([0.5, 7.5]);
            ylim([0.5, 7.5]);
            title(sprintf('马走日游戏 - 7局4胜制 (第%d局)', obj.roundNumber));
        end
        
        function drawPieces(obj)
            % 绘制棋子
            delete(findobj(obj.ax, 'Tag', 'piece'));
            
            % 绘制红方棋子(AI)
            rectangle('Position', [obj.redPos(2)-0.4, 8-obj.redPos(1)-0.4, 0.8, 0.8], ...
                     'Curvature', [1, 1], 'FaceColor', [1, 0.2, 0.2], ...
                     'EdgeColor', [0.5, 0, 0], 'LineWidth', 2, 'Tag', 'piece');
            text(obj.redPos(2), 8-obj.redPos(1), 'AI', ...
                 'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
                 'Color', [1, 1, 1], 'Tag', 'piece');
            
            % 绘制蓝方棋子(玩家)
            rectangle('Position', [obj.bluePos(2)-0.4, 8-obj.bluePos(1)-0.4, 0.8, 0.8], ...
                     'Curvature', [1, 1], 'FaceColor', [0.2, 0.2, 1], ...
                     'EdgeColor', [0, 0, 0.5], 'LineWidth', 2, 'Tag', 'piece');
            text(obj.bluePos(2), 8-obj.bluePos(1), '玩家', ...
                 'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
                 'Color', [1, 1, 1], 'Tag', 'piece');
            
            % 绘制已走过的位置
            delete(findobj(obj.ax, 'Tag', 'visited'));
            for i = 1:7
                for j = 1:7
                    if obj.board(i, j) == 1 % 红方(AI)走过的位置
                        rectangle('Position', [j-0.5, 8-i-0.5, 1, 1], ...
                                 'FaceColor', [1, 0.7, 0.7], 'Tag', 'visited');
                    elseif obj.board(i, j) == 2 % 蓝方(玩家)走过的位置
                        rectangle('Position', [j-0.5, 8-i-0.5, 1, 1], ...
                                 'FaceColor', [0.7, 0.7, 1], 'Tag', 'visited');
                    end
                end
            end
            
            % 如果是玩家回合，显示可能的移动位置
            % if obj.currentPlayer == 2 && ~obj.gameOver
            %     obj.drawPossibleMoves();
            % end
        end
        
        function drawPossibleMoves(obj)
            % 删除之前的所有可能移动标记
            delete(findobj(obj.ax, 'Tag', 'possibleMove'));
            
            currentPos = obj.bluePos;
            color = [0.8, 0.8, 1];
            
            % 计算所有可能的移动
            moves = obj.getPossibleMoves(currentPos);
            
            % 绘制可能的移动位置
            for i = 1:size(moves, 1)
                pos = moves(i, :);
                rectangle('Position', [pos(2)-0.5, 8-pos(1)-0.5, 1, 1], ...
                         'FaceColor', color, 'EdgeColor', 'none', ...
                         'Tag', 'possibleMove', 'LineWidth', 1);
            end
        end
        
        function moves = getPossibleMoves(obj, pos)
            % 获取所有可能的移动位置
            moves = [];
            
            % 所有可能的"马走日"移动
            offsets = [1, 2; 2, 1; 2, -1; 1, -2; -1, -2; -2, -1; -2, 1; -1, 2;1,1;1,-1;-1,-1;-1,1];
            
            for i = 1:size(offsets, 1)
                newPos = pos + offsets(i, :);
                
                % 检查是否在棋盘范围内
                if newPos(1) >= 1 && newPos(1) <= 7 && newPos(2) >= 1 && newPos(2) <= 7
                    % 检查目标位置是否已被占用
                    if obj.board(newPos(1), newPos(2)) == 0
                        moves = [moves; newPos];
                    end
                end
            end
        end
        
        function boardClick(obj)
            if obj.gameOver || obj.roundOver || obj.currentPlayer == 1 % AI回合或比赛结束时不应答点击
                return;
            end
            
            % 获取点击位置
            cp = get(obj.ax, 'CurrentPoint');
            x = round(cp(1, 1));
            y = round(8 - cp(1, 2));
            
            % 检查是否在棋盘范围内
            if x < 1 || x > 7 || y < 1 || y > 7
                return;
            end
            
            % 玩家移动
            if obj.isValidMove(obj.bluePos, [y, x])
                % 检查是否吃掉AI棋子
                if y == obj.redPos(1) && x == obj.redPos(2)
                    obj.roundOver = true;
                    obj.playerWins = obj.playerWins + 1;
                    obj.drawPieces();
                    
                    if obj.playerWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！玩家获胜！', ...
                            'ForegroundColor', [0 0 1]);
                        title('比赛结束！玩家获胜！');
                        disp('年轻人不讲武德！');
                    else
                        set(obj.statusText, 'String', sprintf('玩家赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [0 0 1]);
                        disp('你下把能赢，我当场把电脑屏幕吃掉。');
                    end
                    
                    set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                    set(obj.nextRoundButton, 'Visible', 'on');
                    return;
                end
                
                % 标记当前位置为已访问
                obj.board(obj.bluePos(1), obj.bluePos(2)) = 2;
                
                
                obj.bluePos = [y, x];
                
                % 检查游戏是否结束
                if obj.isGameOver()
                    obj.roundOver = true;
                    obj.aiWins = obj.aiWins + 1;
                    obj.drawPieces();
                    
                    if obj.aiWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！AI获胜！', ...
                            'ForegroundColor', [1 0 0]);
                        title('比赛结束！AI获胜！');
                        disp("回家吧，好不好，回家吧，你比较适合做****");
                    else
                        set(obj.statusText, 'String', sprintf('AI赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [1 0 0]);
                        disp("菜 就多练~");
                    end
                    
                    set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                    set(obj.nextRoundButton, 'Visible', 'on');
                    return;
                end
                
                % 切换为AI回合
                obj.currentPlayer = 1;
                set(obj.statusText, 'String', sprintf('第%d局 - AI思考中...', obj.roundNumber), ...
                    'ForegroundColor', [1 0 0]);
                
                % 重绘棋子
                obj.drawPieces();
                
                % 短暂延迟后执行AI移动
                pause(1);
                obj.aiMove();
            end
        end
        
        function aiMove(obj)
            % AI移动逻辑
            if obj.roundOver
                return;
            end
    
            possibleMoves = obj.getPossibleMoves(obj.redPos);

            for i = 1:size(possibleMoves, 1)
                move = possibleMoves(i, :);
                if move(1) == obj.bluePos(1) && move(2) == obj.bluePos(2)
                    
                    obj.board(obj.redPos(1), obj.redPos(2)) = 1;
                    obj.redPos = move;
                    obj.roundOver = true;
                    obj.aiWins = obj.aiWins + 1;
                    obj.drawPieces();
                    
                    if obj.aiWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！AI获胜！', ...
                            'ForegroundColor', [1 0 0]);
                        title('比赛结束！AI获胜！');
                        disp("回家吧，好不好，回家吧，你比较适合做****");
                    else
                        set(obj.statusText, 'String', sprintf('AI赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [1 0 0]);
                        disp("菜 就多练~");
                    end
                    
                    set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                    set(obj.nextRoundButton, 'Visible', 'on');
                    return;
                end
            end
            
            
            if ~isempty(possibleMoves)

                if sum(obj.board,"all") < 20

                    choice_list = ones(size(possibleMoves,1),1);

                    for i = 1:size(possibleMoves, 1)
    
                        move = possibleMoves(i, :);
    
                        if (abs(move(1)-obj.bluePos(1))==1 && abs(move(2)-obj.bluePos(2))==1)||(abs(move(1)-obj.bluePos(1))==1 && abs(move(2)-obj.bluePos(2))==2)||(abs(move(1)-obj.bluePos(1))==2 && abs(move(2)-obj.bluePos(2))==1)
    
                            choice_list(i) = 0;  % 无路可走才走这里
    
                        end
                    end
    
                    if sum(choice_list) == 0
    
                        randomIndex = randi(size(possibleMoves, 1));
                        selectedMove = possibleMoves(randomIndex, :);
    
                    else
    
                        choice = find(choice_list);
                        to_be_selected = zeros(1,length(choice));
                        for i = 1:length(choice)
                            
                            count = 0;
                            move = possibleMoves(choice(i), :);
                            potentialmove = obj.getPossibleMoves(move);
    
                            for j = 1:size(potentialmove,1)
    
                                move2 = potentialmove(j,:);
                                potentialmove2 = obj.getPossibleMoves(move2);
                                count = count+size(potentialmove2,1)-1;
    
    
                            end
  
    
                            to_be_selected(i) = count*0.3 + length(choice)*0.7;
    
                        end

                        to_be_selected = normalize(to_be_selected,2,'range');

                        to_be_selected = to_be_selected.^2;

                        to_be_selected = to_be_selected./sum(to_be_selected);

                        to_be_selected_1 = cumsum(to_be_selected);

                        x = rand;

                        

                        idx = find(to_be_selected_1>x);

                        

                        if isempty(idx)
                            [~,idx] = max(to_be_selected);
                        else
                            idx = idx(1);
                        end





    
                        % [v,~] = max(to_be_selected);
                        % 
                        % candidate = find(to_be_selected==v);
                        % 
                        % x = randi(length(candidate));
                        % 
                        % idx = candidate(x);

                        selectedMove = possibleMoves(choice(idx),:);
    
                    end

                else

                    choice_list = ones(size(possibleMoves,1),1);

                    for i = 1:size(possibleMoves, 1)
    
                        move = possibleMoves(i, :);
    
                        if (abs(move(1)-obj.bluePos(1))==1 && abs(move(2)-obj.bluePos(2))==1)||(abs(move(1)-obj.bluePos(1))==1 && abs(move(2)-obj.bluePos(2))==2)||(abs(move(1)-obj.bluePos(1))==2 && abs(move(2)-obj.bluePos(2))==1)
    
                            choice_list(i) = 0;  % 无路可走才走这里
    
                        end
                    end
    
                    if sum(choice_list) == 0
    
                        randomIndex = randi(size(possibleMoves, 1));
                        selectedMove = possibleMoves(randomIndex, :);
    
                    else

                        to_be_selected = possibleMoves(choice_list==1,:);
                        player_pos = obj.bluePos;
                        if size(to_be_selected,1) == 1
                            selectedMove = to_be_selected;
                        else

                            maxdepth_ai = zeros(1,size(to_be_selected,1));
                            maxnode_ai = zeros(1,size(to_be_selected,1));
                            sann_atk = zeros(1,size(to_be_selected,1));
                            yonn_atk = zeros(1,size(to_be_selected,1));
                            go_atk = zeros(1,size(to_be_selected,1));
                            sann_down = zeros(1,size(to_be_selected,1));
                            yonn_down = zeros(1,size(to_be_selected,1));
                            go_down = zeros(1,size(to_be_selected,1));
                            sann_ai_record = cell(1,size(to_be_selected,1));   % 记录ai第2层各节点的第3层节点集合
                            yonn_ai_record = cell(1,size(to_be_selected,1));   
                            go_ai_record = cell(1,size(to_be_selected,1));
                            flag_c = zeros(1,size(to_be_selected,1));
                            flag_d = zeros(1,size(to_be_selected,1));
                            cellai = cell(1,size(to_be_selected,1)+1);
                            cellai{1,end} = obj.redPos;
                            flag1 = 0;
                            for ysqd1 = 1:size(to_be_selected,1)
                                path1 = obj.getPossibleMoves(to_be_selected(ysqd1,:));   % path1代表了第3层的可能位置
                                row_idx = ~ismember(path1,obj.redPos,"rows");
                                path1 = path1(row_idx,:);
                                sann_ai_record{1,ysqd1} = path1;
                                yonn_ai_record{1,ysqd1} = [];
                                go_ai_record{1,ysqd1} = [];
                                cellai{1,ysqd1} = cell(1,size(path1,1)+1);
                                cellai{1,ysqd1}{1,end} = to_be_selected(ysqd1,:);   % cellai第2个嵌套的尾端记录着第2层的坐标位置
                                if ~isempty(path1)
                                    if flag1 == 0
                                        maxdepth_ai(ysqd1) = maxdepth_ai(ysqd1) + 1;
                                        maxnode_ai(ysqd1) = maxnode_ai(ysqd1) + size(path1,1);
                                        flag1 = 1;
                                    end
                                    flag2 = 0;
                                    for ysqd2 = 1:size(path1,1)
                                        path2 = obj.getPossibleMoves(path1(ysqd2,:));    % path2代表了第4层的可能位置
                                        
                                        row_idx1 = ismember(path2,cellai{1,end},"rows");
                                        
                                        row_idx2 = ismember(path2,cellai{1,ysqd1}{1,end},"rows");
                                        row_idx = row_idx1+row_idx2;
                                        path2 = path2(row_idx==0,:);
                                        yonn_ai_record{1,ysqd1} = [yonn_ai_record{1,ysqd1};path2];
                                        cellai{1,ysqd1}{1,ysqd2} = cell(1,size(path2,1)+1);
                                        cellai{1,ysqd1}{1,ysqd2}{1,end} = path1(ysqd2,:);   % cellai第3个嵌套的尾端记录着第3层的坐标位置
                                        if ~isempty(path2)
                                            if flag2 == 0
                                                maxdepth_ai(ysqd1) = maxdepth_ai(ysqd1) + 1;
                                                maxnode_ai(ysqd1) = maxnode_ai(ysqd1) + size(path2,1);
                                                flag2 = 1;
                                            end
                                            flag3 = 0;
                                            for ysqd3 = 1:size(path2,1)
                                                path3 = obj.getPossibleMoves(path2(ysqd3,:));   % path3代表了第5层的可能位置
                                                go_ai_record{1,ysqd1} = [go_ai_record{1,ysqd1};path3];
                                                row_idx1 = ismember(path3,cellai{1,end},"rows");
                                                row_idx2 = ismember(path3,cellai{1,ysqd1}{1,end},"rows");
                                                row_idx3 = ismember(path3,cellai{1,ysqd1}{1,ysqd2}{1,end},"rows");
                                                row_idx = row_idx3 + row_idx2 + row_idx1;
                                                path3 = path3(row_idx==0,:);
                                                cellai{1,ysqd1}{1,ysqd2}{1,ysqd3} = cell(1,size(path3,1)+1);
                                                cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,end} = path2(ysqd3,:);  % cellai第4个嵌套的尾端记录着第4层的坐标位置
                                                if ~isempty(path3)
                                                    if flag3 == 0
                                                        maxdepth_ai(ysqd1) = maxdepth_ai(ysqd1) + 1;
                                                        maxnode_ai(ysqd1) = maxnode_ai(ysqd1) + size(path3,1);
                                                        flag3 = 1;
                                                    end
                                                    flag4 = 0;
                                                    for ysqd4 = 1:size(path3,1)
                                                        path4 = obj.getPossibleMoves(path3(ysqd4,:));   % path4代表了第6层的可能位置
                                                        row_idx1 = ismember(path4,cellai{1,end},"rows");
                                                        row_idx2 = ismember(path4,cellai{1,ysqd1}{1,end},"rows");
                                                        row_idx3 = ismember(path4,cellai{1,ysqd1}{1,ysqd2}{1,end},"rows");
                                                        row_idx4 = ismember(path4,cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,end},"rows");
                                                        row_idx = row_idx4 + row_idx3 + row_idx2 + row_idx1;
                                                        path4 = path4(row_idx==0,:);
                                                        cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4} = cell(1,size(path4,1)+1);
                                                        cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,end} = path3(ysqd4,:);  % cellai第5个嵌套的尾端记录着第5层的坐标位置
                                                        if ~isempty(path4)
                                                            if flag4 == 0
                                                                maxdepth_ai(ysqd1) = maxdepth_ai(ysqd1) + 1;
                                                                maxnode_ai(ysqd1) = maxnode_ai(ysqd1) + size(path4,1);
                                                                flag4 = 1;
                                                            end
                                                            flag5 = 0;
                                                            for ysqd5 = 1:size(path4,1)
                                                                path5 = obj.getPossibleMoves(path4(ysqd5,:));   % path4代表了第6层的可能位置
                                                                row_idx1 = ismember(path5,cellai{1,end},"rows");
                                                                row_idx2 = ismember(path5,cellai{1,ysqd1}{1,end},"rows");
                                                                row_idx3 = ismember(path5,cellai{1,ysqd1}{1,ysqd2}{1,end},"rows");
                                                                row_idx4 = ismember(path5,cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,end},"rows");
                                                                row_idx5 = ismember(path5,cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,end},"rows");
                                                                row_idx = row_idx5 + row_idx4 + row_idx3 + row_idx2 + row_idx1;
                                                                path5 = path5(row_idx==0,:);
                                                                cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,ysqd5} = cell(1,size(path5,1)+1);
                                                                cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,ysqd5}{1,end} = path4(ysqd5,:);  % cellai第5个嵌套的尾端记录着第5层的坐标位置
                                                                if ~isempty(path5)
                                                                    if flag5 == 0
                                                                        maxdepth_ai(ysqd1) = maxdepth_ai(ysqd1) + 1;
                                                                        maxnode_ai(ysqd1) = maxnode_ai(ysqd1) + size(path5,1);
                                                                        flag5 = 1;
                                                                    end
                                                                    flag6 = 0;
                                                                    for ysqd6 = 1:size(path5,1)
                                                                        path6 = obj.getPossibleMoves(path5(ysqd6,:));   % path4代表了第6层的可能位置
                                                                        row_idx1 = ismember(path6,cellai{1,end},"rows");
                                                                        row_idx2 = ismember(path6,cellai{1,ysqd1}{1,end},"rows");
                                                                        row_idx3 = ismember(path6,cellai{1,ysqd1}{1,ysqd2}{1,end},"rows");
                                                                        row_idx4 = ismember(path6,cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,end},"rows");
                                                                        row_idx5 = ismember(path6,cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,end},"rows");
                                                                        row_idx6 = ismember(path6,cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,ysqd5}{1,end},"rows");
                                                                        row_idx = row_idx6 + row_idx5 + row_idx4 + row_idx3 + row_idx2 + row_idx1;
                                                                        path6 = path6(row_idx==0,:);
                                                                        cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,ysqd5}{1,ysqd6} = cell(1,1);
                                                                        cellai{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,ysqd5}{1,ysqd6}{1,1} = path5(ysqd6,:);  % cellai第5个嵌套的尾端记录着第5层的坐标位置
                                                                        if ~isempty(path6)
                                                                            if flag6 == 0
                                                                                maxdepth_ai(ysqd1) = maxdepth_ai(ysqd1) + 1;
                                                                                maxnode_ai(ysqd1) = maxnode_ai(ysqd1) + size(path6,1);
                                                                                flag6 = 1;
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end


                                                        end
                                                    end

                                                end

                                            end
                                            

                                        end
                                    end

                                end

                            end


                            to_be_selected_pl = obj.getPossibleMoves(player_pos);
                            sann_pl_record = cell(1,size(to_be_selected_pl,1));
                            yonn_pl_record = cell(1,size(to_be_selected_pl,1));
                            go_pl_record = cell(1,size(to_be_selected_pl,1));
                            maxdepth_pl = zeros(1,size(to_be_selected_pl,1));
                            maxnode_pl = zeros(1,size(to_be_selected_pl,1));
                            cellpl = cell(1,size(to_be_selected_pl,1)+1);
                            cellpl{1,end} = obj.bluePos;
                            flag1 = 0;

                            for ysqd1 = 1:size(to_be_selected_pl,1)
                                
                                path1 = obj.getPossibleMoves(to_be_selected_pl(ysqd1,:));   % path1代表了第3层的可能位置
                                row_idx = ~ismember(path1,obj.bluePos,"rows");
                                path1 = path1(row_idx,:);
                                sann_pl_record{1,ysqd1} = path1;
                                yonn_pl_record{1,ysqd1} = [];
                                go_pl_record{1,ysqd1} = [];
                                cellpl{1,ysqd1} = cell(1,size(path1,1)+1);
                                cellpl{1,ysqd1}{1,end} = to_be_selected_pl(ysqd1,:);   % cellpl第2个嵌套的尾端记录着第2层的坐标位置
                                if ~isempty(path1)
                                    if flag1 == 0
                                        maxdepth_pl(ysqd1) = maxdepth_pl(ysqd1) + 1;
                                        maxnode_pl(ysqd1) = maxnode_pl(ysqd1) + size(path1,1);
                                        flag1 = 1;
                                    end
                                    flag2 = 0;
                                    for ysqd2 = 1:size(path1,1)
                                        path2 = obj.getPossibleMoves(path1(ysqd2,:));    % path2代表了第4层的可能位置
                                        yonn_pl_record{1,ysqd1} = [yonn_pl_record{1,ysqd1};path2];
                                        row_idx1 = ismember(path2,cellpl{1,end},"rows");
                                        row_idx2 = ismember(path2,cellpl{1,ysqd1}{1,end},"rows");
                                        row_idx = row_idx1+row_idx2;
                                        path2 = path2(row_idx==0,:);
                                        cellpl{1,ysqd1}{1,ysqd2} = cell(1,size(path2,1)+1);
                                        cellpl{1,ysqd1}{1,ysqd2}{1,end} = path1(ysqd2,:);   % cellpl第3个嵌套的尾端记录着第3层的坐标位置
                                        if ~isempty(path2)
                                            if flag2 == 0
                                                maxdepth_pl(ysqd1) = maxdepth_pl(ysqd1) + 1;
                                                maxnode_pl(ysqd1) = maxnode_pl(ysqd1) + size(path2,1);
                                                flag2 = 1;
                                            end
                                            flag3 = 0;
                                            for ysqd3 = 1:size(path2,1)
                                                path3 = obj.getPossibleMoves(path2(ysqd3,:));   % path3代表了第5层的可能位置
                                                go_pl_record{1,ysqd1} = [go_pl_record{1,ysqd1};path3];
                                                row_idx1 = ismember(path3,cellpl{1,end},"rows");
                                                row_idx2 = ismember(path3,cellpl{1,ysqd1}{1,end},"rows");
                                                row_idx3 = ismember(path3,cellpl{1,ysqd1}{1,ysqd2}{1,end},"rows");
                                                row_idx = row_idx3 + row_idx2 + row_idx1;
                                                path3 = path3(row_idx==0,:);
                                                cellpl{1,ysqd1}{1,ysqd2}{1,ysqd3} = cell(1,size(path3,1)+1);
                                                cellpl{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,end} = path2(ysqd3,:);  % cellpl第4个嵌套的尾端记录着第4层的坐标位置
                                                if ~isempty(path3)
                                                    if flag3 == 0
                                                        maxdepth_pl(ysqd1) = maxdepth_pl(ysqd1) + 1;
                                                        maxnode_pl(ysqd1) = maxnode_pl(ysqd1) + size(path3,1);
                                                        flag3 = 1;
                                                    end
                                                    flag4 = 0;
                                                    for ysqd4 = 1:size(path3,1)
                                                        path4 = obj.getPossibleMoves(path3(ysqd4,:));   % path4代表了第6层的可能位置
                                                        row_idx1 = ismember(path4,cellpl{1,end},"rows");
                                                        row_idx2 = ismember(path4,cellpl{1,ysqd1}{1,end},"rows");
                                                        row_idx3 = ismember(path4,cellpl{1,ysqd1}{1,ysqd2}{1,end},"rows");
                                                        row_idx4 = ismember(path4,cellpl{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,end},"rows");
                                                        row_idx = row_idx4 + row_idx3 + row_idx2 + row_idx1;
                                                        path4 = path4(row_idx==0,:);
                                                        cellpl{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4} = cell(1,1);
                                                        cellpl{1,ysqd1}{1,ysqd2}{1,ysqd3}{1,ysqd4}{1,1} = path3(ysqd4,:);  % cellpl第5个嵌套的尾端记录着第5层的坐标位置
                                                        if ~isempty(path4)
                                                            if flag4 == 0
                                                                maxdepth_pl(ysqd1) = maxdepth_pl(ysqd1) + 1;
                                                                maxnode_pl(ysqd1) = maxnode_pl(ysqd1) + size(path4,1);
                                                                flag4 = 1;
                                                            end


                                                        end
                                                    end

                                                end

                                            end
                                            

                                        end
                                    end

                                end

                            end

                            %  攻击性加分（需要调取ai树的3~5层和player树的2~5层）
                            %  这一部分概率进行了强化处理（效果不好可注释）
                            maxdepth_pl_new = zeros(1,length(maxdepth_pl));

                            for j = 1:length(maxdepth_pl)

                                maxdepth_pl_new(j) = sum(maxdepth_pl(maxdepth_pl<=maxdepth_pl(j)));

                            end

                            maxdepth_pl = maxdepth_pl_new;

                            maxdepth_pl = normalize(maxdepth_pl,2,'range');    % 对应各节点的分值

                            maxnode_pl_new = zeros(1,length(maxnode_pl));

                            for j = 1:length(maxnode_pl)

                                maxnode_pl_new(j) = sum(maxnode_pl(maxnode_pl<=maxnode_pl(j)));

                            end

                            maxnode_pl = maxnode_pl_new;

                            maxnode_pl = normalize(maxnode_pl,2,'range');

                            value1 = maxdepth_pl * 0.65 + maxnode_pl * 0.35;

                            value1 = normalize(value1,2,'range');










                            % gain:
                            % sann_atk: sann_ai_record -> to_be_selected_pl
                            % yonn_atk: yonn_ai_record -> sann_pl_record
                            % go_atk:go_ai_record -> yonn_pl_record

                            for k = 1:size(to_be_selected,1)

                                sann = sann_ai_record{1,k};
                                yonn = yonn_ai_record{1,k};
                                go = go_ai_record{1,k};
                                sann = unique(sann,"rows","stable");

                                if ~isempty(sann)
                                % for k1 = 1:size(sann,1)
                                %     pos1 = sann(k1,:);
                                %     coun = 0;
                                %     for k2 = 1:size(to_be_selected_pl,1)
                                %         pos2 = to_be_selected_pl(k2,:);
                                %         if pos1(1)==pos2(1) && pos1(2) == pos2(2)
                                %             sann_atk(k) = sann_atk(k) + value1(k2);
                                %             coun = coun + 1;
                                %         end
                                %         if coun == size(to_be_selected_pl,1)
                                %             sann_atk(k) = sann_atk(k)*10000;
                                %             disp("I FOUND IT!");
                                %         end
                                %     end
                                % end
                                coun = 0;
                                

                                for k1 = 1:size(to_be_selected_pl,1)
                                    pos2 = to_be_selected_pl(k1,:);
                                    for k2 = 1:size(sann,1)
                                        pos1 = sann(k2,:);
                                        if pos1(1)==pos2(1) && pos1(2) == pos2(2)
                                            sann_atk(k) = sann_atk(k) + value1(k1);
                                            coun = coun+1;
                                        end
                                        if coun == size(to_be_selected_pl,1)
                                            if flag_c(k) == 0
                                                disp("你却输得这么彻底~");
                                                disp("AI接下来可以走的格子：")
                                                disp(sann);
                                                disp("而你只能走：");
                                                disp(to_be_selected_pl);
                                            end

                                            flag_c(k) = 1;
                                        end



                                    end

                                end
                                end

                                
                                
                                if ~isempty(yonn)
                                for k1 = size(yonn,1)
                                    pos1 = yonn(k1,:);
                                    for k3 = 1:size(sann_pl_record,2)
                                        thecell = sann_pl_record{1,k3};
                                        for k2 = 1:size(thecell,1)
                                            pos2 = thecell(k2,:);
                                            if pos1(1) == pos2(1) && pos1(2) == pos2(2)
                                                yonn_atk(k) = yonn_atk(k) + value1(k3);
                                            end
                                        end
                                    end
                                end
                                end


                                if ~isempty(go)
                                for k1 = size(go,1)
                                    pos1 = go(k1,:);
                                    for k3 = 1:size(yonn_pl_record,2)
                                        thecell = yonn_pl_record{1,k3};
                                        for k2 = 1:size(thecell,1)
                                            pos2 = thecell(k2,:);
                                            if pos1(1) == pos2(1) && pos1(2) == pos2(2)
                                                go_atk(k) = go_atk(k) + value1(k3);
                                            end
                                        end
                                    end
                                end
                                end
                            end

                            sann_atk = normalize(sann_atk,2 ,'range');
                            sann_atk = sann_atk.^(1.2);
                            sann_atk = normalize(sann_atk,2 ,'range');
                            yonn_atk = normalize(yonn_atk,2,'range');
                            yonn_atk = yonn_atk.^(1.2);
                            yonn_atk = normalize(yonn_atk,2,'range');
                            go_atk = normalize(go_atk,2,'range');
                            go_atk = go_atk.^(1.2);
                            go_atk = normalize(go_atk,2,'range');
                            summary = 0.95 * sann_atk + 0.35 * yonn_atk + 0.1 * go_atk;
                            summary = normalize(summary,2,'range');

                            

                            % loss:
                            for k = 1:size(to_be_selected,1)
                                record = zeros(1,size(to_be_selected_pl,1));
                                sann = sann_ai_record{1,k};
                                yonn = yonn_ai_record{1,k};
                                go = go_ai_record{1,k};
                                sann = unique(sann,"rows","stable");
                                
                                % sann:里面的坐标如果被player第二层的某个节点的子节点全包括了，那就不能要。
                                if ~isempty(sann)
                                    
                                    for k1 = 1:size(sann,1)
                                        
                                        pos1 = sann(k1,:);
                                        for k2 = 1:size(sann_pl_record,2)
                                            pos2_array = sann_pl_record{1,k2};
                                            test = any(all(pos2_array - pos1 == 0,2));
                                            if test 
                                                record(k2) = record(k2) + 1;
                                            end
        
                                        end


                                    end

                                    
                                    if ~isempty(find(record == size(sann,1), 1))
                                        if flag_d(k) == 0
                                            
                                            % disp("哎呀，差点掉进你的陷阱了呢！")
                                            % disp("我如果走到");
                                            % disp(to_be_selected(k,:));
                                            % disp("可能到的地方只有：");
                                            % disp(sann);
                                            % disp("你再走到");
                                            % disp(to_be_selected_pl(record==size(sann,1),:));
                                            % disp("那我不就跑不掉了吗? 你好坏啊");
                                            % disp("而你却能到");
                                            % disp(sann_pl_record{1,record==size(sann,1)});
                                        end
                                        flag_d(k) = 1;
                                    end







                                % for k1 = size(sann,1)
                                %     pos1 = sann(k1,:);
                                %     for k3 = 1:size(sann_pl_record,1)
                                %         thecell = sann_pl_record{1,k3};
                                %         for k2 = 1:size(thecell,1)
                                %             pos2 = thecell(k2,:);
                                %             if pos1(1) == pos2(1) && pos1(2) == pos2(2)
                                %                 sann_down(k) = sann_down(k) + value1(k3);
                                %             end
                                %         end
                                %     end
                                % end
                                end
                                
                                if ~isempty(yonn)
                                for k1 = size(yonn,1)
                                    pos1 = yonn(k1,:);
                                    for k3 = 1:size(yonn_pl_record,2)
                                        thecell = yonn_pl_record{1,k3};
                                        for k2 = 1:size(thecell,1)
                                            pos2 = thecell(k2,:);
                                            if pos1(1) == pos2(1) && pos1(2) == pos2(2)
                                                yonn_down(k) = yonn_down(k) + value1(k3);
                                            end
                                        end
                                    end
                                end
                                end


                                if ~isempty(go)
                                for k1 = size(go,1)
                                    pos1 = go(k1,:);
                                    for k3 = 1:size(go_pl_record,2)
                                        thecell = go_pl_record{1,k3};
                                        for k2 = 1:size(thecell,1)
                                            pos2 = thecell(k2,:);
                                            if pos1(1) == pos2(1) && pos1(2) == pos2(2)
                                                go_down(k) = go_down(k) + value1(k3);
                                            end
                                        end
                                    end
                                end
                                end
                            end

                            sann_down = normalize(sann_down,2 ,'range');
                            sann_down = sann_down.^(1.2);
                            sann_down = normalize(sann_down,2 ,'range');
                            yonn_down = normalize(yonn_down,2,'range');
                            yonn_down = yonn_down.^(1.2);
                            yonn_down = normalize(yonn_down,2,'range');
                            go_down = normalize(go_down,2,'range');
                            go_down = go_down.^(1.2);
                            go_down = normalize(go_down,2,'range');
                            total = 0.6 * sann_down + 0.5 * yonn_down + 0.3 * go_down;
                            total = normalize(total,2,'range');


                            maxdepth_ai = normalize(maxdepth_ai, 2, 'range');
                            maxnode_ai = normalize(maxdepth_ai, 2, 'range');
                            value = maxdepth_ai * obj.depth_weight + maxnode_ai * obj.node_weight + summary * obj.control_weight - total * obj.defense_weight + flag_c * obj.kill_weight - flag_d * obj.killed_weight;   % 四部分分别为：最大深度，子节点数量，限制对手数量，被对手限制数量




                            [~,max_idx] = max(value);
                            selectedMove = to_be_selected(max_idx,:);

                        end



                    end

                end

              
                % 执行移动
                obj.board(obj.redPos(1), obj.redPos(2)) = 1;
                obj.redPos = selectedMove;
                
                % 检查游戏是否结束
                if obj.isGameOver()
                    obj.roundOver = true;
                    obj.playerWins = obj.playerWins + 1;
                    obj.drawPieces();
                    
                    if obj.playerWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！玩家获胜！', ...
                            'ForegroundColor', [0 0 1]);
                        title('比赛结束！玩家获胜！');
                        disp("可恶啊！我一定会回来的！");
                    else
                        set(obj.statusText, 'String', sprintf('玩家赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [0 0 1]);
                        disp("哼~ 侥幸罢了~");
                    end
                    
                    set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                    set(obj.nextRoundButton, 'Visible', 'on');
                    return;
                end
                
                % 切换为玩家回合
                obj.currentPlayer = 2;
                set(obj.statusText, 'String', sprintf('第%d局 - 玩家回合', obj.roundNumber), ...
                    'ForegroundColor', [0 0 1]);
            else
                
                obj.roundOver = true;
                obj.playerWins = obj.playerWins + 1;

                if obj.playerWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！玩家获胜！', ...
                            'ForegroundColor', [1 0 0]);
                        title('比赛结束！玩家获胜！');
                        disp("可恶啊！我一定会回来的！");
                else
                        set(obj.statusText, 'String', sprintf('玩家赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [1 0 0]);
                        disp("哼~ 侥幸罢了~");
                end




                % set(obj.statusText, 'String', sprintf('AI赢得第%d局！', obj.roundNumber), ...
                    % 'ForegroundColor', [0 0 1]);
                set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                set(obj.nextRoundButton, 'Visible', 'on');
            end
            
            % 重绘棋子
            obj.drawPieces();
        end
        
        function valid = isValidMove(obj, from, to)
            
            dx = abs(to(2) - from(2));
            dy = abs(to(1) - from(1));
            
           
            if (dx == 1 && dy == 2) || (dx == 2 && dy == 1) || (dx == 1 && dy == 1)
                
                if obj.board(to(1), to(2)) ~= 0
                    valid = false;
                    return;
                end
                
                valid = true;
            else
                valid = false;
            end
        end
        
        function over = isGameOver(obj)
            % 检查当前玩家是否无法移动
            if obj.currentPlayer == 1 % AI回合
                over = ~obj.hasValidMoves(obj.redPos);
            else % 玩家回合
                over = ~obj.hasValidMoves(obj.bluePos);
            end
        end
        
        function hasMoves = hasValidMoves(obj, pos)
            
            moves = [...
                pos + [1, 2]; pos + [2, 1]; ...
                pos + [2, -1]; pos + [1, -2]; ...
                pos + [-1, -2]; pos + [-2, -1]; ...
                pos + [-2, 1]; pos + [-1, 2]; ...
                pos + [1,1];pos + [1,-1];...
                pos + [-1,1];pos + [-1,-1]
            ];
            
            hasMoves = false;
            for i = 1:size(moves, 1)
                move = moves(i, :);
                if move(1) >= 1 && move(1) <= 7 && move(2) >= 1 && move(2) <= 7
                    if obj.isValidMove(pos, move)
                        hasMoves = true;
                        return;
                    end
                end
            end
        end
    end
end