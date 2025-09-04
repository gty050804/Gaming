classdef Hard < handle
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
    end
    
    methods
        function obj = Hard()
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
            % 开始新的一局比赛
            cla(obj.ax);
            hold on;
            
            % 初始化棋盘
            obj.createBoard();
            
            % 初始化棋子位置
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
            
            % 添加重新开始按钮
            if isempty(obj.restartButton) || ~isvalid(obj.restartButton)
                obj.restartButton = uicontrol('Style', 'pushbutton', 'Position', [650, 50, 100, 30], ...
                    'String', '重新开始', 'FontSize', 12, 'Callback', @(src,evt)obj.restartGame());
            end
            
            % 添加下一局按钮（初始隐藏）
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
                    else
                        set(obj.statusText, 'String', sprintf('玩家赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [0 0 1]);
                    end
                    
                    set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                    set(obj.nextRoundButton, 'Visible', 'on');
                    return;
                end
                
                % 标记当前位置为已访问
                obj.board(obj.bluePos(1), obj.bluePos(2)) = 2;
                
                % 移动玩家棋子
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
                    else
                        set(obj.statusText, 'String', sprintf('AI赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [1 0 0]);
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
            
            % 获取所有可能的移动
            possibleMoves = obj.getPossibleMoves(obj.redPos);
            
            % 检查是否有可以吃掉玩家的移动
            for i = 1:size(possibleMoves, 1)
                move = possibleMoves(i, :);
                if move(1) == obj.bluePos(1) && move(2) == obj.bluePos(2)
                    % 吃掉玩家棋子，AI赢得本局
                    obj.board(obj.redPos(1), obj.redPos(2)) = 1;
                    obj.redPos = move;
                    obj.roundOver = true;
                    obj.aiWins = obj.aiWins + 1;
                    obj.drawPieces();
                    
                    if obj.aiWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！AI获胜！', ...
                            'ForegroundColor', [1 0 0]);
                        title('比赛结束！AI获胜！');
                    else
                        set(obj.statusText, 'String', sprintf('AI赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [1 0 0]);
                    end
                    
                    set(obj.scoreText, 'String', sprintf('比分: AI %d - %d 玩家', obj.aiWins, obj.playerWins));
                    set(obj.nextRoundButton, 'Visible', 'on');
                    return;
                end
            end
            
            % 如果没有可以吃掉玩家的移动，随机选择一个移动
            if ~isempty(possibleMoves)
                % % 随机选择一个移动
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

        
                        to_be_selected(i) = count*0.2 + length(choice)*0.8;

                    end

                    if sum(obj.board,"all") < 10

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

                    else

                        [~,idx] = max(to_be_selected);

                    end
                    
                    selectedMove = possibleMoves(choice(idx),:);

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
                    else
                        set(obj.statusText, 'String', sprintf('玩家赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [0 0 1]);
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
                obj.aiWins = obj.aiWins + 1;

                if obj.aiWins >= obj.winsNeeded
                        set(obj.statusText, 'String', '比赛结束！AI获胜！', ...
                            'ForegroundColor', [1 0 0]);
                        title('比赛结束！AI获胜！');
                else
                        set(obj.statusText, 'String', sprintf('AI赢得第%d局！', obj.roundNumber), ...
                            'ForegroundColor', [1 0 0]);
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