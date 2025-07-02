require "ts" -- task prototypes for Ship, Shot, Meteor

-- Simple "physics" to update task `rect` position based on `vel` speed:
--  * updates rect every 'step' frame
--  * terminates when rect leaves the screen

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

-- Left/Right ship constant parameters

local V = {
    l = {
        tag = 'L',
        pos = PP(10, 50),           -- x,y initial position
        ctl = {                     -- key controls
            move  = { l='A', r='D', u='W', d='S'},
            frame = { l=0, r=1, u=2, d=3 },
            shot  = 'Left Shift',
        },
        lim = { x1=0, x2=W/2 },     -- x limits (half of screen)
        shot = { tag='l', x=1 },    -- shot tag, x direction
    },
    r = {
        tag = 'R',
        pos = PP(90, 50),
        ctl = {
            move = { l='Left', r='Right', u='Up', d='Down' },
            frame = { l=1, r=0, u=2, d=3 },
            shot = 'Right Shift',
        },
        lim = { x1=W/2, x2=W },
        shot = { tag='r', x=-1 },
    },
}

function Battle ()
    -- Declares and spawns the game objects: ships, shots, meteors

    -- holds all meteors
    local meteors <close> = tasks()

    -- holds all l/r shots (max of 3 simultaneous)
    local shots_l <close> = tasks(3)
    local shots_r <close> = tasks(3)

    -- holds l/r ships
    local ships <close> = tasks(2)
    spawn_in(ships, Ship, V.l, shots_l, "imgs/ship-L.gif")
    spawn_in(ships, Ship, V.r, shots_r, "imgs/ship-R.gif")

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
    return (s.tag=='L' and 'R') or 'L'
end

return Battle
