--[[
GD50
Match-3 Remake

-- PlayState Class --

Author: Colton Ogden
cogden@cs50.harvard.edu

State in which we can actually play, moving around a grid cursor that
can swap two tiles; when two tiles make a legal swap (a swap that results
in a valid match), perform the swap and destroy all matched tiles, adding
their values to the player's point score. The player can continue playing
until they exceed the number of points needed to get to the next level
or until the time runs out, at which point they are brought back to the
main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    self.levelLabelY = -64

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)

end

function PlayState:enter(params)
    -- grab level # from the params we're passed
    self.level = params.level

    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)

    isMatchPossible = self:checkForMatch()

    if isMatchPossible == false then
      self:resetBoard()
      isMatchePossible = self:checkForMatch()
    end

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000

end

function PlayState:update(dt)

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then

        -- clear timers from prior PlayStates
        Timer.clear()

        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then

        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        --converts mouse imput to push resolution
        self.tileHighlightdX, self.tileHighlightdY = push:toGame(love.mouse.getX(), love.mouse.getY())

        --if no mouse imput then return 0 rather than nothing to prevent breaking the code
        self.tileHighlightdX = self.tileHighlightdX == nil and 0 or self.tileHighlightdX
        self.tileHighlightdY = self.tileHighlightdY == nil and 0 or self.tileHighlightdY

        --Converts the push mouse coords into tile coords to highlight tiles
        self.mouseX = math.ceil((self.tileHighlightdX - 240) / 32) - 1
        self.mouseY = math.ceil((self.tileHighlightdY - 15) / 32) - 1

        --Will only highlight if mouse is on the board
        if self.tileHighlightdX >= 240 and self.tileHighlightdX <= 490 and self.tileHighlightdY >= 15 and self.tileHighlightdY <= 250 then
          self.boardHighlightX = self.mouseX
          self.boardHighlightY = self.mouseY
        end

        --get the mouse pressed function to find the button that was pressed
        function love.mousepressed(x, y, button, isTouch)
          self.mouseButton = button
        end

        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') or self.mouseButton == 1 then
            self.mouseButton = nil

            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1

            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                -- swap highlighted tile with current tile
                self:switchTiles(self.highlightedTile, self.board.tiles[y][x])

                -- tween coordinates between the two so they swap
                Timer.tween(0.2, {
                    [self.Tile1] = {x = self.Tile2.x, y = self.Tile2.y},
                    [self.Tile2] = {x = self.Tile1.x, y = self.Tile1.y}
                })

                -- once the swap is finished, we can tween falling blocks as needed
                :finish(function()
                    -- tells function to swap blocks back if no match found
                    self.shouldSwap = true
                    self:calculateMatches()
                end)
            end
        end
    end

    Timer.update(dt)
    Tile:update(dt)
end

function PlayState:switchTiles(tile1, tile2)
    self.Tile1 = tile1
    self.Tile2 = tile2

    local X1 = self.Tile1.gridX
    local Y1 = self.Tile1.gridY

    local X2 = self.Tile2.gridX
    local Y2 = self.Tile2.gridY

    self.Tile1.gridX = X2
    self.Tile1.gridY = Y2
    self.Tile2.gridX = X1
    self.Tile2.gridY = Y1

    self.board.tiles[Y2][X2] = self.Tile1

    self.board.tiles[Y1][X1] = self.Tile2
end


--function that switches 2 tiles back if no match. Uses the switchTiles function, but adds the tweening
function PlayState:switchBack()
    gSounds['error']:play()
    self:switchTiles(self.Tile2, self.Tile1)
    Timer.tween(0.2, {
        [self.Tile1] = {x = self.Tile2.x, y = self.Tile2.y},
        [self.Tile2] = {x = self.Tile1.x, y = self.Tile1.y}
    })
end

function PlayState:checkForMatch()
  for y = 1, 8 do
    for x = 1, 8  do
      if x < 8 then
        --switch right
        self:switchTiles(self.board.tiles[y][x], self.board.tiles[y][x + 1])
        local matches = self.board:calculateMatches()
        if matches then
          --switch back
          self:switchTiles(self.board.tiles[y][x], self.board.tiles[y][x + 1])
          return true
        end
        self:switchTiles(self.board.tiles[y][x], self.board.tiles[y][x + 1])
      end

      if y < 8 then
        --switch down
        self:switchTiles(self.board.tiles[y][x], self.board.tiles[y + 1][x])
        local matches = self.board:calculateMatches()
        if matches then
          --switch back
          self:switchTiles(self.board.tiles[y][x], self.board.tiles[y + 1][x])
          return true
        end
        self:switchTiles(self.board.tiles[y][x], self.board.tiles[y + 1][x])
      end
    end
  end
  return false
end

--[[
Calculates whether any matches were found on the board and tweens the needed
tiles to their new destinations if so. Also removes tiles from the board that
have matched and replaces them with new randomized tiles, deferring most of this
to the Board class.
]]
function PlayState:calculateMatches()
    -- remove highlighted tile
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()

    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        -- if row is cleared, award points for all tiles
        -- otherwise, award based on match number
        if self.board.clearRow == true then
            self.score = self.score + 8 * 50
            self.timer = self.timer + 8
        elseif self.board.clearColumn == true then
            self.score = self.score + 8 * 50
            self.timer = self.timer + 8
        else
            -- add score for each match
            -- add a second to the timer for each match
            for k, match in pairs(matches) do
              for i, tile in pairs(match) do
                  self.score = self.score + 50 * tile.variety
              end
                self.timer = self.timer + #match
            end
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()

        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling

            -- because a match exists, do not swap the tiles back
            self.shouldSwap = false

            self:calculateMatches()

            -- check board to make sure matches exist
        end)

        isMatchPossible = self:checkForMatch()

        if isMatchPossible == false then
          self:resetBoard()
          isMatchePossible = self:checkForMatch()
        end


        -- if no matches, we can continue playing
    else
        --Swaps the tiles back if no match
        if self.shouldSwap == true then
            self:switchBack()
        end

        self.canInput = true
    end
end

--function to reset the board if no match is found
function PlayState:resetBoard()
  gSounds['next-level']:play()
  self.board = Board(VIRTUAL_WIDTH - 272, 16, self.level)
end

function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlightedTile then

        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255, 255, 255, 96)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
        (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217, 87, 99, 255)
    else
        love.graphics.setColor(172, 50, 50, 255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
    self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56, 56, 56, 234)
    -- love.graphics.rectangle('fill', 16, 16, 186, 116, 4)
    love.graphics.rectangle('fill', 16, 16, 186, 146, 4)

    love.graphics.setColor(99, 155, 255, 255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
    -- render Level # label and background rect


  --[[Debug Code
    love.graphics.printf(tostring(self.mouseX), 20, 130, 182, 'center')
    love.graphics.printf(tostring(self.mouseY), 20, 150, 182, 'center')
    love.graphics.printf(tostring(self.tileHighlightdX), 20, 180, 182, 'center')
    love.graphics.printf(tostring(self.tileHighlightdY), 20, 200, 182, 'center')
    ]]
end
