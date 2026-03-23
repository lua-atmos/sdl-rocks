# The "Rocks!" game

A spaceship shooter game for 2 simultaneous players.
Built with [Atmos][atmos] and [atmos-env-sdl][env-sdl].

[atmos]:   https://github.com/lua-atmos/atmos/
[env-sdl]: https://github.com/lua-atmos/env-sdl/

# Install

```
sudo luarocks --lua-version=5.4 install atmos 0.6
sudo luarocks --lua-version=5.4 install atmos-env-sdl 0.1
```

# Run

```
git checkout v0.4
lua5.4 main.lua
```

# Instructions

- Hit the other ship.
- Avoid the rocks!
- Controls:
    - Left Ship: `WASD` to move, `Shift Left` to shoot.
    - Right Ship: Arrow keys to move, `Shift Right` to shoot.
