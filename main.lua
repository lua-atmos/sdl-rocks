SDL = require "SDL"
IMG = require "SDL.image"
TTF = require "SDL.ttf"

require "atmos"
local sdl = require "atmos.env.sdl"

PP = sdl.pct_to_pos
rect_vs_rect = sdl.rect_vs_rect

function between (min, v, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

assert(TTF.init())
local _ <close> = defer(function ()
    TTF.quit()
    SDL.quit()
end)

W, H = 640, 480
WIN = assert(SDL.createWindow {
	title  = "The Battle of Ships",
	width  = W,
	height = H,
    flags  = { SDL.flags.OpenGL },
})
REN = assert(SDL.createRenderer(WIN,-1))

FNT = assert(TTF.open("tiny.ttf", H/15))

math.randomseed()

spawn(function ()   -- BACKGROUND
    --[[
    ;; Spawns a task to draw the background image on every frame.
    ;; We draw at position (0,0), which is the center of the screen.
    ;; By default, the center of the image is anchored at the given position.
    ;; This task is the first to spawn, which makes the background image to
    ;; always be rendered first.
    ]]
    local sfc = assert(IMG.load("imgs/bg.png"))
    local tex = assert(REN:createTextureFromSurface(sfc))
    every('sdl.draw', function ()
        REN:copy(tex)
    end)
end)

local points = { L=0, R=0 }

spawn(function ()   -- POINTS
    --[[
    ;; Spawns the players points and place them at the bottom of the screen, in
    ;; opposite sides.
    ;; Points are incremented when the ship of the opponent is destroyed.
    ;; Since points must outlive each individual battle, we spawn them here,
    ;; outside the main game loop.
    ]]
    local l = PP(10, 90)
    local r = PP(90, 90)
    every('sdl.draw', function ()
        REN:setDrawColor(0xFFFFFF)
        sdl.write(FNT, tostring(points.L), l)
        sdl.write(FNT, tostring(points.R), r)
    end)
end)

spawn(function ()   -- MAIN-LOOP
    --[[
    ;; Starts the main game loop:
    ;;  - Shows the "tap to start" message.
    ;;  - Runs the next battle with the actual gameplay.
    ;;  - Restarts whenever one of the ships is destroyed.
    ]]
    while true do
        watching(SDL.event.KeyDown, function ()     -- TAP-TO-START
            --[[
            ;; Spawns the blinking message, and awaits any key press.
            ]]
            while true do
                watching(clock{ms=500}, function ()
                    local pt = PP(50, 50)
                    every('sdl.draw', function ()
                        REN:setDrawColor(0xFFFFFF)
                        sdl.write(FNT, "= TAP TO START =", pt)
                    end)
                end)
                await(clock{ms=500})
            end
        end)

        -- Plays the restart sound.
        --pico.output.sound("snds/start.wav")

        --[[
        ;; Broadcasts pause and resume events to the game:
        ;;  - Pauses on key "P" (event :Hide).
        ;;  - Shows the pause image while paused.
        ;;  - Resumes on key "P" (event :Show).
        ]]
        local _ <close> = spawn(function ()
            while true do
                await(SDL.event.KeyDown, 'P')
                emit('Show', false)
                local _ <close> = spawn(function ()
                    local sfc = assert(IMG.load("imgs/pause.png"))
                    local r = totable('w', 'h', sfc:getSize())
                    local tex = assert(REN:createTextureFromSurface(sfc))
                    local pt = PP(50, 50)
                    r.x = math.floor(pt.x - r.w/2)
                    r.y = math.floor(pt.y - r.h/2)
                    every('sdl.draw', function ()
                        REN:copy(tex, nil, r)
                    end)
                end)
                await(SDL.event.KeyDown, 'P')
                emit('Show', true)
            end
        end)

        --[[
        ;; Pauses and resumes the game when receiving key "P".
        ;; The toggle construct receives two events separated by `->`, and
        ;; controls its nested block as follows:
        ;;  - Initially, the block executes and receives broadcasts normally.
        ;;  - When the first event is received, the block is paused by not
        ;;    receiving any broadcasts.
        ;;  - When the second event is received, the block is resumed and
        ;;    receives broadcasts normally.
        ;;  - When the nested block terminates, the outer toggle as a whole
        ;;    also terminates.
        ;;  - The toggle evaluates to the final value of the block.
        ]]
        local _,_,winner = catch('winner', function ()
            toggle('Show', function ()
                --[[
                ;; The "battle block" contains the actual gameplay and holds the
                ;; spaceships and meteors.
                ;; The block returns the winner index (0 or 1), whose points are
                ;; incremented before the next battle.
                ;; Since the block is nested, all dynamic objects are all properly
                ;; released and reallocated after each individual battle.
                ]]
                dofile "battle.lua"     -- includes the battle block
            end)
        end)

        -- Increments the winner points.
        if winner then
            points[winner] = points[winner] + 1
            await(clock{s=1})
        end

        --[[
        ;; Restarts the main loop.
        ;; Due to lexical memory management, only the points are preserved
        ;; between loop iterations.
        ;; All other data, including those dynamically allocated, are
        ;; guaranteed to be reclaimed after this point, no matter how the
        ;; nested code above is structured.
        ]]
    end
end)

sdl.loop(REN)
