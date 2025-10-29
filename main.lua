sdl = require "atmos.env.sdl"

SDL = require "SDL"
IMG = require "SDL.image"
TTF = require "SDL.ttf"

-- SKIP TO "START HERE"

PP = sdl.pct_to_pos
rect_vs_rect = sdl.rect_vs_rect

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

-- START HERE

local Battle = require "battle" -- actual battle gameplay

sdl.ren = REN
call(function ()

    -- BACKGROUND
    spawn(function ()
        local sfc = assert(IMG.load("imgs/bg.png"))
        local tex = assert(REN:createTextureFromSurface(sfc))
        every('sdl.draw', function ()
            REN:copy(tex)
        end)
    end)

    -- POINTS
    local points = { L=0, R=0 }
    spawn(function ()
        local l = PP(10, 90)
        local r = PP(90, 90)
        every('sdl.draw', function ()
            REN:setDrawColor(0xFFFFFF)
            sdl.write(FNT, tostring(points.L), l)
            sdl.write(FNT, tostring(points.R), r)
        end)
    end)

    -- MAIN LOOP:
    --  * shows the "press enter to start" message
    --  * runs the next battle
    --  * restarts whenever one of the ships is destroyed

    while true do

        -- Start with 'ENTER':
        --  * spawns a blinking message, and awaits "enter" key
        watching(SDL.event.KeyDown, 'Return', function ()
            while true do
                -- 500ms on
                watching(clock{ms=500}, function ()
                    local pt = PP(50, 50)
                    every('sdl.draw', function ()
                        REN:setDrawColor(0xFFFFFF)
                        sdl.write(FNT, "= PRESS ENTER TO START =", pt)
                    end)
                end)
                -- 500ms off
                await(clock{ms=500})
            end
        end)

        -- plays the restart sound
        sdl.play "snds/start.wav"

        -- spawns the actual battle
        local battle = spawn(Battle)

        -- Pause with 'P':
        --  * awaits 'P' to toggle battle off
        --  * shows a "paused" image
        --  * awaits 'P' to toggle battle on
        local _ <close> = spawn(function ()
            while true do
                await(SDL.event.KeyDown, 'P')
                toggle(battle, false)
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
                toggle(battle, true)
            end
        end)

        -- Battle terminates:
        --  * awaits battle to return winner
        --  * increments winner points
        --  * awaits 1s before next battle
        local winner = await(battle)
        points[winner] = points[winner] + 1
        await(clock{s=1})
    end
end)
