# Overview
Zep Ball is a game inspired by z-ball (retro64), similar to breakout or arkanoid but differs from most in that the paddle moves up and down on the right side of the screen. The game has sound, music, power-ups and a high score table.

# Inspiration screenshot zball.png
Top left Score
Top center logo
Top right lives remaining
Blue and Green tiles normal
Bomb and stickyball tiles bonus tiles
red and white ball
paddle on right side, moves vertically

# Features
Each level has uniquely shaped tiles to hit with the ball.
There are special tiles that give bonuses (bombs, multiball, etc)
When a tile is hit breaks into "3d" space as it disappears
There are great sound effects
The soundtrack rocks.
Paddle imparts physics to ball (spin)
  - Ball contacting stationary paddle: no spin, bounces off at opposite angle
  - Ball contacting moving paddle: bounces off at opposite agle but also spins (causes curve trajectory) based on movement speed of paddle

# Gameplay loop
Ball starts attached to paddle, player releases with click or button press.
Ball bounces off top, left and bottom
Ball bounces off tiles and clears them
Ball bounces off paddle
If ball passes paddle on right a life is lost

# Requirements
Multiplatform (mac, linux, windows)
Single player
Player profiles (saves)
Option to select levels, once a level is cleared unlock the option to try the next level

# Questions
What tech stack fits this project the best, give a few options with recommendations and why.
What are the three most important questions I need to answer in order to build this successfully?

# URGENT
This project is early in the planning stage, do not make any actual implementations!
