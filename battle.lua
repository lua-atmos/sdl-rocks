require "ts" -- task prototypes for Ship, Shot, Meteor

-- Task prototype to update the given `rect` position
-- according to its `vel` speed:
--  * Updates rect on every 'step' frame.
--  * Terminates when rect leaves the screen.
function Move_T (rect, vel)
    local function out_of_screen ()
        return (
            rect.x < 0  or
            rect.x > W  or
            rect.y < 0  or
            rect.y > H
        )
    end
    watching(out_of_screen, function ()
        every('step', function (_,ms)
            local dt = ms / 1000
            rect.x = math.floor(rect.x + (vel.x * dt))
            rect.y = math.floor(rect.y + (vel.y * dt))
        end)
    end)
end

-- Declares and spawns the game objects: ships, shots, meteors

-- holds all meteors
local meteors <close> = tasks()

-- holds all l/r shots (max of 3 simultaneous)
local shots_l <close> = tasks(3)
local shots_r <close> = tasks(3)

-- l/r ship positions
local pos = {
    l = PP(10, 50),
    r = PP(90, 50),
}

-- l/r ship key controls
local ctl = {
    l = {mov={l='A',    r='D',     u='W',  d='S'},    shot='Left Shift'},
    r = {mov={l='Left', r='Right', u='Up', d='Down'}, shot='Right Shift'},
}

-- l/r ship X limit (half of the screen)
local lim = {
    l = {x1=0,   x2=W/2},
    r = {x1=W/2, x2=W  },
}

-- holds l/r ships
local ships <close> = tasks(2)
spawn_in(ships, Ship, 'L', pos.l, ctl.l, lim.l, shots_l, "imgs/ship-L.gif")
spawn_in(ships, Ship, 'R', pos.r, ctl.r, lim.r, shots_r, "imgs/ship-R.gif")

-- GAMEPLAY:
--  * runs until one of the two ships `s` is destroyed
--  * spawns new meteors periodically
--  * checks collisions between all objects

local s = watching(ships, function ()
    par(function ()
        -- spawns new meteros periodically
        while true do
            local dt = math.random(1000, 5000)
            await(clock{ms=dt})
            spawn_in(meteors, Meteor)
        end
    end, function ()
        -- check collisions
        every('step', function ()
            -- collect references to all ships, shots, meteors
            local ts = {}
            for _, t in getmetatable(ships).__pairs(ships) do
                ts[#ts+1] = t
            end
            for _, t in getmetatable(shots_l).__pairs(shots_l) do
                ts[#ts+1] = t
            end
            for _, t in getmetatable(shots_r).__pairs(shots_r) do
                ts[#ts+1] = t
            end
            for _, t in getmetatable(meteors).__pairs(meteors) do
                ts[#ts+1] = t
            end

            -- check valid collisions within `ts` and emit 'collided'
            -- (ignore ship 'R'/'r' shot, ship 'L'/'l' shot, 'M'/'M' meteors)
            for i=1, #ts do
                for j=i+1, #ts do
                    local t1 = ts[i]
                    local t2 = ts[j]
                    local no = (
                        (t1.tag=='R' and t2.tag=='r') or
                        (t1.tag=='r' and t2.tag=='R') or
                        (t1.tag=='L' and t2.tag=='l') or
                        (t1.tag=='l' and t2.tag=='L') or
                        (t1.tag=='M' and t2.tag=='M')
                    )
                    if (not no) and rect_vs_rect(t1.rect, t2.rect) then
                        emit_in(t1, 'collided') -- will terminate t1
                        emit_in(t2, 'collided') -- will terminate t2
                    end
                end
            end
        end)
    end)
end)

sdl.play "snds/explosion.wav" -- overrides any active sound
throw('winner', (s.tag=='L' and 'R') or 'L')
