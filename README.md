# 68000AssemblyGame
This is a two-player game made using the 68000 Assembly language. 
This is a demonstration of low-level data manipulation to create a structured program.

The assets, including audio, were sourced through Envato Elements with my subscription. 

The program was written using an emulator for the Motorola 68000 called Easy68K. 
http://www.easy68k.com/

Below is the description of the project found within the main Assembly file.

 Description: Game Name - SPACE JUNKERS
*               In this game you play as one of two character, you are either JERRY JUNKER (Player 1, WASD) or GARY GARBAGE (Player 2,IJKL).
*               The premise of the game is that you are space-garbage collectors that are in a competition to see who can catch the most falling
*               space-garbage. The garbage (In-code referref to as "Messages") is being pulled in by an force beam that increases its pull over time.
*               As such, the speed of the falling garbage will increase more and more over time until the beam reaches full power (In-program, until we hit Terminal Velocity).
*               The game also includes a few voice lines as well.
*               I will continue by describing how this game meets each of the requirements.
*
*               1. "User input control of game entity (i.e. paddle in Pong, aiming a turret, etc)"
*                   This is addressed by allowing the players to catch the garbage as it falls. They control when it is collected/attempted to be collected.
*
*               2. "Bitmap background with entities moving around over it"
*                   This is addressed through the rendering of the messages in the game. As they fall, the redraw the background of their previous location.
*
*               3. "Physics update of game entity, including acceleration (gravity would be good example)"
*                   The speed of the messages is determined by a fixed Acceleration that gradually increases the velocity over time until it hits Terminal Velocity.
*
*               4."Fixed point math"
*                   This requirement is fulfilled when doing the calculations for velocity each frame. The Velocity increases by less than one pixel-unit per frame, but
*                   this change is only noticeable once the Velocity increases past 1 once it is shifted down.
*
*               5. "Collision detection between game entities"
*                   The messages are constantly having their position polled. The program can detect when a message reaches it's lowest point possible and will despawn it.
*                   The program also polls the position of the messages when the messages' corresponding button is pressed to determine whether or not the player has scored and how much.
*
*               6. "A score indicator as a 7-segment LED"
*                   The 7-Segment LED is used as a timer.
*
*               7. "Randomness"
*                   I use a slightly modified version of the Random code provided to us for use. I additionally use the third byte of data from the right of what is returned as my random value.
*                   This does rely on time, so ultimately it does end up following a noticeable pattern, however the very first time is random in that it is entirely dependent on what time you play at.
*

