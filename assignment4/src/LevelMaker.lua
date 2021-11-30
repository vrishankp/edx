--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    numChasm = 0
    gKeySpawned = false
    gSpawnFlag = false
    gKeyPickedUp = false

    local flagPosition = 3--width - 2
    local keyColor = math.random(1, 4) --used to get the correct image from the quad
    local lockColor = keyColor + 4 --Locks are 4 quads more than the keys
    local flagpoleColor = keyColor + 2
    local flagColor = 1 + (keyColor - 1) * 3 --ge the correct flag quad
    local lockPosition = math.random(1, width) --random location of locked brick
    while lockPosition == flagPosition do
      lockPosition = math.random(width)
    end


    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x ~= 1 and numChasm <= 2 and x ~= flagPosition and x ~= lockPosition then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end

            numChasm = numChasm + 1
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end
            numChasm = 0
            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil

            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            if x == lockPosition then
              table.insert(objects,
                GameObject{
                  texture = 'keys-and-locks',
                  x = (x - 1) * TILE_SIZE,
                  y = (blockHeight - 1) * TILE_SIZE,
                  width = 16,
                  height = 16,

                  frame = lockColor,
                  collidable = true,
                  hit = false,
                  solid = true,

                  onCollide = function(obj)
                    if not obj.hit then
                      if gKeyPickedUp then
                        gSpawnFlag = true
                        gSounds['powerup-reveal']:play()
                        obj.hit = true
                          table.insert(objects,
                            GameObject{
                              texture = 'only-flags',
                              x = (flagPosition - 0.6) * TILE_SIZE,
                              y = (blockHeight - 0.68) * TILE_SIZE,
                              width = 16,
                              height = 16,

                              frame = 4,
                              collidable = false,
                              hit = false,
                              solid = false,
                            }
                          )
                        table.remove(objects, lock)
                      else
                        gSounds['empty-block']:play()
                      end
                    end
                  end
                }
              )
            end

            if x == flagPosition then
              table.insert(objects,
                GameObject{
                  texture = 'flags',
                  x = (x - 1) * TILE_SIZE,
                  y = (blockHeight - 1) * TILE_SIZE,
                  width = 16,
                  height = 48,

                  frame = flagpoleColor,
                  collidable = true,
                  hit = false,
                  solid = false,

                  onCollide = function(obj)
                    if not obj.hit then
                      if gSpawnFlag then
                        gSounds['powerup-reveal']:play()
                        obj.hit = true
                        table.remove(objects, lock)
                      else

                      end
                    end
                  end
                }
              )
            end


            -- chance to spawn a block
            if math.random(10) == 1 and x ~= flagPosition and x ~= flagPosition + 1 and x ~= flagPosition - 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem/key if we haven't already hit the block
                            if not obj.hit then

                                 gRandom = math.random(5)
                                -- chance to spawn gem, not guaranteed
                                if gRandom == 1 or gRandom == 2 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }

                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true

                            else if gRandom > 2 and gKeySpawned == false then
                                  gKeySpawned = true
                                  local key = GameObject {
                                      texture = 'keys-and-locks',
                                      x = (x - 1) * TILE_SIZE,
                                      y = (blockHeight - 1) * TILE_SIZE - 4,
                                      width = 16,
                                      height = 16,
                                      frame = keyColor,
                                      collidable = true,
                                      consumable = true,
                                      solid = false,

                                      -- gem has its own function to add to the player's score
                                      onConsume = function(player, object)
                                          gSounds['pickup']:play()
                                          gKeyPickedUp = true
                                      end
                                  }

                                  Timer.tween(0.1, {
                                      [key] = {y = (blockHeight - 2) * TILE_SIZE}
                                  })
                                  gSounds['powerup-reveal']:play()

                                  table.insert(objects, key)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    return GameLevel(entities, objects, map)
end
