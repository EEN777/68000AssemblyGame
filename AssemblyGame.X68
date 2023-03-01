*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Title      : Interactive Assembly Project
* Written by : Ian Smith
* Date       : 10/06/2022
* Description: Game Name - SPACE JUNKERS
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
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INCLUDE 'BMPSubroutine.x68'
    INCLUDE 'Random.x68'
    ORG    $2000

*************************************BEGIN-EQUATES*************************************
*Audio Numbers
*   The audio codes are used to reference WAV files that are loaded into memory. Easy68K plays the file according to it's identifying number.
*   The code is put into the right-most byte of the d1 register to be read.
LEVEL_AUDIO_CODE    EQU 1
MENU_MUSIC_CODE     EQU 2
VICTORY_MUSIC_CODE  EQU 3
NO_POINT_CODE       EQU 4
POINT_CODE          EQU 5
TITLE_CODE          EQU 6
INTRO_CODE          EQU 7
JERRY_WIN_CODE      EQU 8
GARY_WIN_CODE       EQU 9

*Audio Codes to move into d2
*   These audio codes are placed into d2 and read in order to determine how the audio player should treat the clip when played.
PLAY_ONCE       EQU 0
PLAY_LOOPED     EQU 1
STOP_PLAYING    EQU 2
STOP_ALL        EQU 3

*7-Segment LED
*   These are the hard coded values to be bassed into the registers in order to draw each segment of the 7-Segment LED.
*   There are two sets, one for the tens place and one for the ones place.
A_TENS_LEFT_X      EQU 300
A_TENS_RIGHT_X     EQU 310
A_TENS_UPPER_Y     EQU 150
A_TENS_LOWER_Y     EQU 155

B_TENS_LEFT_X      EQU 310
B_TENS_RIGHT_X     EQU 315
B_TENS_UPPER_Y     EQU 150
B_TENS_LOWER_Y     EQU 170

C_TENS_LEFT_X      EQU 310
C_TENS_RIGHT_X     EQU 315
C_TENS_UPPER_Y     EQU 165
C_TENS_LOWER_Y     EQU 185

D_TENS_LEFT_X      EQU 300
D_TENS_RIGHT_X     EQU 310
D_TENS_UPPER_Y     EQU 180
D_TENS_LOWER_Y     EQU 185

E_TENS_LEFT_X      EQU 295
E_TENS_RIGHT_X     EQU 300
E_TENS_UPPER_Y     EQU 165
E_TENS_LOWER_Y     EQU 185

F_TENS_LEFT_X      EQU 295
F_TENS_RIGHT_X     EQU 300
F_TENS_UPPER_Y     EQU 150
F_TENS_LOWER_Y     EQU 170

G_TENS_LEFT_X      EQU 300
G_TENS_RIGHT_X     EQU 310
G_TENS_UPPER_Y     EQU 165
G_TENS_LOWER_Y     EQU 170

A_ONES_LEFT_X      EQU 330
A_ONES_RIGHT_X     EQU 340
A_ONES_UPPER_Y     EQU 150
A_ONEs_LOWER_Y     EQU 155

B_ONES_LEFT_X      EQU 340
B_ONES_RIGHT_X     EQU 345
B_ONES_UPPER_Y     EQU 150
B_ONES_LOWER_Y     EQU 170

C_ONES_LEFT_X      EQU 340
C_ONES_RIGHT_X     EQU 345
C_ONES_UPPER_Y     EQU 165
C_ONES_LOWER_Y     EQU 185

D_ONES_LEFT_X      EQU 330
D_ONES_RIGHT_X     EQU 340
D_ONES_UPPER_Y     EQU 180
D_ONES_LOWER_Y     EQU 185

E_ONES_LEFT_X      EQU 325
E_ONES_RIGHT_X     EQU 330
E_ONES_UPPER_Y     EQU 165
E_ONES_LOWER_Y     EQU 185

F_ONES_LEFT_X      EQU 325
F_ONES_RIGHT_X     EQU 330
F_ONES_UPPER_Y     EQU 150
F_ONES_LOWER_Y     EQU 170

G_ONES_LEFT_X      EQU 330
G_ONES_RIGHT_X     EQU 340
G_ONES_UPPER_Y     EQU 165
G_ONES_LOWER_Y     EQU 170 


*Task Commands
*   These are frequently called task commands.
DRAWING_MODE_TASK   EQU 92
REPAINT_SCENE_TASK  EQU 94
SET_FILL_TASK       EQU 81
DRAW_RECTANGLE_TASK EQU 87
GET_KEY_TASK        EQU 19  
CLEAR_SCREEN_TASK   EQU 11
CLEAR_SCREEN_VAL    EQU $FF00
DOUBLE_BUFFER       EQU 17
LOAD_TRACK_TASK     EQU 74
PLAY_AUDIO          EQU 77

*Velocity constants.
*   These are the constant velocity values and the Twelfth Power of 2 for fixed point math.
TERMINAL_VELOCITY   EQU 30
TWELFTH_POWER       EQU 4096
ACCELERATION_RATE   EQU 65
STARTINGVELOCITY     EQU 1
STARTINGACCELERATION EQU 1

*Message Active Flags
*   Placed into the first Long of memory at a given Message's location in memory to determine whether or not it is an active message.
IS_ACTIVE           EQU $00000000
IS_NOT_ACTIVE       EQU $FFFFFFFF

*Amount of time the round should last for in hundreths of a second.
GAME_TIMER          EQU 6000
*Event Timer i.e. "WaitForSeconds"
EVENT_WAIT_TIME     EQU 180

*Key codes for all in-game inputs.
P1_LEFT_CODE        EQU $41
P1_UP_CODE          EQU $57
P1_DOWN_CODE        EQU $53
P1_RIGHT_CODE       EQU $44
P2_LEFT_CODE        EQU $4A
P2_UP_CODE          EQU $49
P2_DOWN_CODE        EQU $4B
P2_RIGHT_CODE       EQU $4C
ENTER_CODE          EQU $D

*Total number of messages available to spawn,and their directions.
MESSAGE_LIMIT           EQU 8
NUMBER_OF_DIRECTIONS    EQU 4

*Message Side Lengths
MESSAGE_HEIGHT      EQU 25
MESSAGE_WIDTH       EQU 25

*Random Number Compares
SPAWN_LEFT  EQU 63
SPAWN_UP    EQU 127
SPAWN_DOWN  EQU 191
SPAWN_RIGHT EQU 255

*Message Data-Type Offsets
*   These offsets are for the active messages that are stored in memory.
OFFSET_TO_CHUNKX            EQU 4
OFFSET_TO_SPAWN_LOCATION    EQU 8
OFFSET_TO_LOCATION          EQU 12
OFFSET_TO_NEXT_PLAYER       EQU 16

OFFSET_TO_UP    EQU 32
OFFSET_TO_DOWN  EQU 64
OFFSET_TO_RIGHT EQU 96

*Node X-Positions
*   The X-Positions for all falling messages that can be spawned into a level.
NODE_P1_LEFT     EQU 78
NODE_P1_UP       EQU 129
NODE_P1_DOWN     EQU 180
NODE_P1_RIGHT    EQU 231
NODE_P2_LEFT     EQU 385
NODE_P2_UP       EQU 436
NODE_P2_DOWN     EQU 487
NODE_P2_RIGHT    EQU 538

*Message BMP offets to render the desired message.
*   X Offset to desire parts of the bitmap.
UP_MESSAGE      EQU 0
DOWN_MESSAGE    EQU 52
LEFT_MESSAGE    EQU 104
RIGHT_MESSAGE   EQU 156

*Maximum allowed messages on screen.
PAIR_LIMIT      EQU 4

*Y Sendback Points
*   TOP_Y is where the messages spawn and BOTTOM_Y is where the messages would become inactive.
TOP_Y       EQU 120
BOTTOM_Y    EQU 480

*Score Boundaries and thresholds
*   Used in caclulations to detemine how many points (if any) a player gets for hitting a message.
*   Score_Y is the relative position to base the score around and the boundary is there to be a minimum requirement for the message's y-position.
*   Depending on how clos the message's y is, the player either gain one or three points.
SCORE_Y                    EQU 376
START_SCORING_BOUNDARY     EQU 351
ONE_POINT_THRESHOLD        EQU 50
THREE_POINT_THRESHOLD      EQU 25

*LED Locations
LED_AREA_X      EQU 295
LED_AREA_Y      EQU 150
LED_AREA_WIDTH  EQU 50
LED_AREA_HEIGHT EQU 35

*MISC. BMP Equates
SCREEN_WIDTH            EQU 640
SCREEN_HEIGHT           EQU 480
PORTRAIT_X              EQU 12
PORTRAIT_Y              EQU 8
PORTRAIT_WIDTH          EQU 83
PORTRAIT_HEIGHT         EQU 73
JERRY_POSITION_X        EQU 38
JERRY_POSITION_Y        EQU 14
GARY_POSITION_X         EQU 493
GARY_POSITION_Y         EQU 14
WIN_MESSAGE_WIDTH       EQU 480
WIN_MESSAGE_HEIGHT      EQU 75
WIN_MESSAGE_POSITION_X  EQU 80
WIN_MESSAGE_POSITION_Y  EQU 200

UI_COLOR    EQU $0054FF00      

**************************************END-EQUATES**************************************
*Used as an early conditional return from a subroutine.
Return:
    rts
**************************************BEGIN-LED****************************************
*7-Segment LED Drawing Functions
*   These subroutines are called by another subroutine which is in turn called via a function table.
*   These functions all put the required parameters (Top Left X, Top Right X, Top Y, and Bottom Y)
*   needed to draw a rectangle to the screen using the Draw Rectangle Trap Code.    
DrawAOnes:
    move.w  #A_ONES_LEFT_X,d1
    move.w  #A_ONES_RIGHT_X,d3
    move.w  #A_ONES_UPPER_Y,d2
    move.w  #A_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawBOnes:
    move.w  #B_ONES_LEFT_X,d1
    move.w  #B_ONES_RIGHT_X,d3
    move.w  #B_ONES_UPPER_Y,d2
    move.w  #B_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawCOnes:
    move.w  #C_ONES_LEFT_X,d1
    move.w  #C_ONES_RIGHT_X,d3
    move.w  #C_ONES_UPPER_Y,d2
    move.w  #C_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawDOnes:
    move.w  #D_ONES_LEFT_X,d1
    move.w  #D_ONES_RIGHT_X,d3
    move.w  #D_ONES_UPPER_Y,d2
    move.w  #D_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawEOnes:
    move.w  #E_ONES_LEFT_X,d1
    move.w  #E_ONES_RIGHT_X,d3
    move.w  #E_ONES_UPPER_Y,d2
    move.w  #E_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawFOnes:
    move.w  #F_ONES_LEFT_X,d1
    move.w  #F_ONES_RIGHT_X,d3
    move.w  #F_ONES_UPPER_Y,d2
    move.w  #F_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawGOnes:
    move.w  #G_ONES_LEFT_X,d1
    move.w  #G_ONES_RIGHT_X,d3
    move.w  #G_ONES_UPPER_Y,d2
    move.w  #G_ONES_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts

DrawATens:
    move.w  #A_TENS_LEFT_X,d1
    move.w  #A_TENS_RIGHT_X,d3
    move.w  #A_TENS_UPPER_Y,d2
    move.w  #A_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawBTens:
    move.w  #B_TENS_LEFT_X,d1
    move.w  #B_TENS_RIGHT_X,d3
    move.w  #B_TENS_UPPER_Y,d2
    move.w  #B_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawCTens:
    move.w  #C_TENS_LEFT_X,d1
    move.w  #C_TENS_RIGHT_X,d3
    move.w  #C_TENS_UPPER_Y,d2
    move.w  #C_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawDTens:
    move.w  #D_TENS_LEFT_X,d1
    move.w  #D_TENS_RIGHT_X,d3
    move.w  #D_TENS_UPPER_Y,d2
    move.w  #D_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawETens:
    move.w  #E_TENS_LEFT_X,d1
    move.w  #E_TENS_RIGHT_X,d3
    move.w  #E_TENS_UPPER_Y,d2
    move.w  #E_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawFTens:
    move.w  #F_TENS_LEFT_X,d1
    move.w  #F_TENS_RIGHT_X,d3
    move.w  #F_TENS_UPPER_Y,d2
    move.w  #F_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts
DrawGTens:
    move.w  #G_TENS_LEFT_X,d1
    move.w  #G_TENS_RIGHT_X,d3
    move.w  #G_TENS_UPPER_Y,d2
    move.w  #G_TENS_LOWER_Y,d4
    
    jsr     DrawRectangle
    jsr     Repaint
    rts

DrawOnesZero:    
    jsr DrawAOnes
    jsr DrawBOnes
    jsr DrawCOnes
    jsr DrawDOnes
    jsr DrawEOnes
    jsr DrawFOnes
    rts
DrawOnesOne:
    jsr DrawBOnes
    jsr DrawCOnes
    rts
DrawOnesTwo:
    jsr DrawAOnes
    jsr DrawBOnes
    jsr DrawDOnes
    jsr DrawEOnes
    jsr DrawGOnes
    rts
DrawOnesThree:
    jsr DrawAOnes
    jsr DrawBOnes
    jsr DrawCOnes
    jsr DrawDOnes
    jsr DrawGOnes
    rts
DrawOnesFour:
    jsr DrawBOnes
    jsr DrawCOnes
    jsr DrawFOnes
    jsr DrawGOnes
    rts
DrawOnesFive:
    jsr DrawAOnes
    jsr DrawCOnes
    jsr DrawDOnes
    jsr DrawFOnes
    jsr DrawGOnes
    rts
DrawOnesSix:
    jsr DrawAOnes
    jsr DrawCOnes
    jsr DrawDOnes
    jsr DrawEOnes
    jsr DrawFOnes
    jsr DrawGOnes
    rts
DrawOnesSeven:
    jsr DrawAOnes
    jsr DrawBOnes
    jsr DrawCOnes
    rts
DrawOnesEight:
    jsr DrawAOnes
    jsr DrawBOnes
    jsr DrawCOnes
    jsr DrawDOnes
    jsr DrawEOnes
    jsr DrawFOnes
    jsr DrawGOnes
    rts
DrawOnesNine:
   jsr DrawAOnes
    jsr DrawBOnes
    jsr DrawCOnes
    jsr DrawDOnes
    jsr DrawFOnes
    jsr DrawGOnes
    rts
DrawTensZero:
    jsr DrawATens
    jsr DrawBTens
    jsr DrawCTens
    jsr DrawDTens
    jsr DrawETens
    jsr DrawFTens
    rts
DrawTensOne:
    jsr DrawBTens
    jsr DrawCTens
    rts
DrawTensTwo:
    jsr DrawATens
    jsr DrawBTens
    jsr DrawDTens
    jsr DrawETens
    jsr DrawGTens
    rts 
DrawTensThree:
    jsr DrawATens
    jsr DrawBTens
    jsr DrawCTens
    jsr DrawDTens
    jsr DrawGTens
    rts
DrawTensFour:
    jsr DrawBTens
    jsr DrawCTens
    jsr DrawFTens
    jsr DrawGTens
    rts
DrawTensFive:
    jsr DrawATens
    jsr DrawCTens
    jsr DrawDTens
    jsr DrawFTens
    jsr DrawGTens
    rts
DrawTensSix:
    jsr DrawATens
    jsr DrawCTens
    jsr DrawDTens
    jsr DrawETens
    jsr DrawFTens
    jsr DrawGTens
    rts
    
SetFill:
    move.b  #SET_FILL_TASK,d0
    trap #15
    rts
DrawRectangle:
    move.b  #DRAW_RECTANGLE_TASK,d0
    trap #15
    rts
    
DrawLED:                    *DrawLED takes the Timer throughout the game and uses the quotient and remainder to display the correct time in the correct place (Tens or Ones).
    move.l  Timer,d5
    divs    #100,d5
    cmp.w   PreviousTimer,d5    *If the Timer is the same as the previous timer, then we don't need to waste resources and draw everything again.
    beq     Return
    
    move.w  d5,PreviousTimer
    
    move.l  #LED_AREA_X,4(sp)       *We Redraw the area that the LED is over.
    move.l  #LED_AREA_Y,8(sp)
    move.l  #LED_AREA_WIDTH,12(sp)  
    move.l  #LED_AREA_HEIGHT,16(sp)  
    move.l  #LED_AREA_X,20(sp)  
    move.l  #LED_AREA_Y,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)   
    lea     ImageToLoad,a0
    
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    lea     TensLEDHolder,a5    *We use divs to find the total number of "tens" in the number and use that value as an offset to call a function to draw the correct number in the correct spot.
    move.l  Timer,d5
    divs    #100,d5
    swap    d5
    clr.w   d5
    swap    d5
    divs    #10,d5
    clr.l   d6
    move.w  d5,d6
    mulu    #4,d6
    add.w   d6,a5
    move.l  (a5),d0
    move.l  d0,a5
    jsr     (a5)
    
    lea     OnesLEDHolder,a5    *Here we use the remainder in order to use that as an offset to call a function to draw the correct number in the ones digit in the correct spot.
    swap    d5
    clr.l   d6
    move.w  d5,d6
    mulu    #4,d6
    add.w   d6,a5
    move.l  (a5),d0
    move.l  d0,a5
    jsr     (a5)
    
    lea     ActiveMessages,a0
    
    rts
    
**************************************END-LED******************************************

**************************************BEGIN-MESSAGESPAWNING****************************
*HOW MESSAGES ARE STORED:
*   All messages are stored in the ActiveMessages Array. This is done so that when getting player input
*   We can already know which message "belongs" to which key.
*   Part of this process involves there being a render loop every frame to check for each messages updated position.
*   Part of this requires setting an active and inactive flag in memory for each message.
*   This is done with Equates. Non-Active messages are cleared from the screen and subsequently skipped over until
*   They are set active again. The spawner will only spawn as many as the PAIR_LIMIT allows for.

ResetMessageCounter:                    * This resets the counter used to iterate through the message data.
    lea     ActiveMessages,a0
    move.l  a0,MessagePointer
    move.l  #0,AmountOfMessages
    rts
SpawnMessagePair:
    cmp.l   #PAIR_LIMIT,ActiveMessageCount  *We get a Random and put it into d6, we then use it to spawn a message depending on its range.
    bge     Return                          *This is done every frame, and will try again if it detects that a message has already been spawned in a certain location.
    jsr     seedRandomNumber
    cmp.l   #SPAWN_LEFT,d6
    bgt     CheckUp
    
    move.l  (a0),d0
    cmp.l   #IS_ACTIVE,d0
    beq     CheckP2Left
    
    move.l  #IS_ACTIVE,(a0)
    
    move.l  #OFFSET_TO_CHUNKX,d1
    move.l  #LEFT_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  #NODE_P1_LEFT,d0
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_LOCATION,d1
    move.l  #TOP_Y,(a0,d1)
    
    add.l   #1,ActiveMessageCount
    
CheckP2Left:
    
    move.l  #OFFSET_TO_NEXT_PLAYER,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     Return
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #LEFT_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_NEXT_PLAYER,d1
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  #NODE_P2_LEFT,d0
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_NEXT_PLAYER,d1
    add.l   #OFFSET_TO_LOCATION,d1
    move.l  #TOP_Y,(a0,d1)
    
    add.l   #1,ActiveMessageCount
    
    rts
    
CheckUp:
    cmp.l   #SPAWN_UP,d6
    bgt     CheckDown
    
    move.l  #OFFSET_TO_UP,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     CheckP2Up
    
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #UP_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_UP,d1  
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  #NODE_P1_UP,d0
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_UP,d1
    add.l   #OFFSET_TO_LOCATION,d1
    move.l  #TOP_Y,(a0,d1)
    add.l   #1,ActiveMessageCount
CheckP2Up:
    move.l  #OFFSET_TO_UP,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     Return
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #UP_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_UP,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  #NODE_P2_UP,d0
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_UP,d1
    add.l   #OFFSET_TO_LOCATION,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  #TOP_Y,(a0,d1)
    
    add.l   #1,ActiveMessageCount
    
    rts
    
CheckDown:
    cmp.l   #SPAWN_DOWN,d6
    bgt     SpawnRightPair
    
    move.l  #OFFSET_TO_DOWN,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     CheckP2Down
    
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #DOWN_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_DOWN,d1  
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  #NODE_P1_DOWN,d0
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_DOWN,d1
    add.l   #OFFSET_TO_LOCATION,d1
    move.l  #TOP_Y,(a0,d1)
    add.l   #1,ActiveMessageCount
CheckP2Down:
    move.l  #OFFSET_TO_DOWN,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     Return
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #DOWN_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_DOWN,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  #NODE_P2_DOWN,d0
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_DOWN,d1
    add.l   #OFFSET_TO_LOCATION,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  #TOP_Y,(a0,d1)
    
    add.l   #1,ActiveMessageCount
    
    rts
    
SpawnRightPair:                                 *We check all 8 messages. The messages are stores by directions and then ordered by player number.
    
    move.l  #OFFSET_TO_RIGHT,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     CheckP2Right
    
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #RIGHT_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_RIGHT,d1  
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  #NODE_P1_RIGHT,d0
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_RIGHT,d1
    add.l   #OFFSET_TO_LOCATION,d1
    move.l  #TOP_Y,(a0,d1)
    add.l   #1,ActiveMessageCount
CheckP2Right:
    move.l  #OFFSET_TO_RIGHT,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  (a0,d1),d0
    cmp.l   #IS_ACTIVE,d0
    beq     Return
    move.l  #IS_ACTIVE,(a0,d1)
    
    add.l   #OFFSET_TO_CHUNKX,d1
    move.l  #RIGHT_MESSAGE,(a0,d1)
    
    move.l  #OFFSET_TO_RIGHT,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  #NODE_P2_RIGHT,d0
    add.l   #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  d0,(a0,d1)
    
    move.l  #OFFSET_TO_RIGHT,d1
    add.l   #OFFSET_TO_LOCATION,d1
    add.l   #OFFSET_TO_NEXT_PLAYER,d1
    move.l  #TOP_Y,(a0,d1)
    
    add.l   #1,ActiveMessageCount
    
    rts
****************************************END-MESSAGESPAWNING****************************
*This is just a quick way to allocate everything needed for the messages.
AllocateMessages:
    lea     ActiveMessages,a0
    lea     MessageChunkX,a1
    lea     MessageSpawnLocations,a2
    rts    
****************************************BEGIN-VELOCITY*********************************        
TerminalVel:                        *Used to check whether or not we have reached Terminal Velocity and stops the Velocity from getting higher than that.
    move.l  #TERMINAL_VELOCITY,d0
    move.l  d0,Velocity
    rts
SetVelocity:                    *Iterates through the messages and puts the updated velocity into it's corresponding position.
    move.l  MessagePointer,d1
    move.l  d1,a0
    move.l  #12,d1
    move.l  (a0,d1),d2 
    move.l  Velocity,d0
    add.l   d0 ,d2
    move.l  d2,(a0,d1)
    add.l   #1,AmountOfMessages
    add.l   #16,MessagePointer
    cmp.l   #MESSAGE_LIMIT,AmountOfMessages
    bne     SetVelocity
    lea     ActiveMessages,a0
    move.l  a0,d1
    move.l  d1,MessagePointer
    rts
    
UpdateVelocity:                 *Uses Fixed-Point math to increase the Velocity in increments smaller than 1 over time.
    move.l  StoredVelocity,d0
    add.l   #ACCELERATION_RATE,d0
    move.l  d0,StoredVelocity
    asr.l   #4,d0
    asr.l   #8,d0
    cmp.l   #TERMINAL_VELOCITY,d0
    bgt     TerminalVel             *Send to TerminalVel if greater than Terminal Velocity.
    move.l  d0,Velocity
    rts
******************************************END-VELOCITY********************************* 

****************************************BEGIN-MESSAGEDRAWING***************************    
DrawMessage:
    move.l  MessagePointer,d0           *MessagePointer keeps track of where we are pointing to in the memory for the messages.
    move.l  d0,a1
    move.l  (a1),d0
    cmp.l   #IS_ACTIVE,d0
    bne     SkipRendering               *We Skip Rendering if they are set inactive.
    move.l  #OFFSET_TO_CHUNKX,d1
    move.l  (a1,d1),d2
    move.l  d2,4(sp)
    move.l  #1,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #OFFSET_TO_SPAWN_LOCATION,d1
    move.l  (a1,d1),d2 
    move.l  d2,20(sp) 
    move.l  #OFFSET_TO_LOCATION,d1
    move.l  (a1,d1),d2
    cmp.l   #BOTTOM_Y,d2
    blt     ContinueDrawingMessages
DespawnMessage:
    sub.l   #1,ActiveMessageCount       *ActiveMessageCount keeps track of the total number of Active Messages
    move.l  #IS_NOT_ACTIVE,(a1)
    bra     ContinueDrawingMessages     *We return to drawing messages if we encounter a message that needs to be set inactive while drawing them.
ContinueDrawingMessages:
    move.l  d2,24(sp)
    lea     EndOfArrows,a0
    move.l  a0,28(sp)
    lea     ArrowsImage,a0 
    
    jsr     DrawBitmapChunk
    
SkipRendering:
    add.l   #1,AmountOfMessages
    add.l   #OFFSET_TO_NEXT_PLAYER,MessagePointer   *We use the offset to next player because that is the distance between P1 Left and P2 Left, and so on.
    
    cmp.l   #MESSAGE_LIMIT,AmountOfMessages
    bne     DrawMessage
    
    jsr     ResetMessageCounter
    jsr     Repaint                     *We only repaint once they have all been drawn.
RedrawBackground:
    move.l  MessagePointer,d0           *Now we redraw all of the background that was previously covered by the messages.
    move.l  d0,a1
    move.l  (a1),d0
    cmp.l   #IS_ACTIVE,d0
    bne     SkipRedraw                  *We again skip rendering if the message is inactive since it hasn't moved to cover any new background area.
    move.l  #8,d1
    move.l  (a1,d1),d2 
    move.l  d2,4(sp)
    move.l  #12,d1
    move.l  (a1,d1),d2 
    move.l  d2,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    
    move.l  Velocity,16(sp)              *We are able to use the velocity as the height for the BMP Subroutine.
    move.l  #8,d1
    move.l  (a1,d1),d2  
    move.l  d2,20(sp)
    move.l  #12,d1
    move.l  (a1,d1),d2
    move.l  d2,24(sp)
    
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    
    jsr     DrawBitmapChunk

SkipRedraw:    
    add.l   #1,AmountOfMessages
    add.l   #OFFSET_TO_NEXT_PLAYER,MessagePointer
    
    cmp.l   #MESSAGE_LIMIT,AmountOfMessages
    bne     RedrawBackground
    lea     ActiveMessages,a0
    move.l  a0,MessagePointer
    rts
    
******************************************END-MESSAGEDRAWING***************************
    
SetDoubleBuffer:
    move.b  #DRAWING_MODE_TASK,d0
    move.b  #DOUBLE_BUFFER,d1
    trap #15
    rts
ClearScreen:
    move.b  #CLEAR_SCREEN_TASK,d0
    move.l  #CLEAR_SCREEN_VAL,d1
    trap #15
    rts
Repaint:
    move.b  #REPAINT_SCENE_TASK,d0
    trap #15
    rts
******************************************BEGIN-TIMERS*********************************    
GetTime:
    move.b  #8,d0
    trap #15
    rts
    
GetFrameTime:                   *Used to get time passed from beginning to end of a frame in hundreths of a second. (Approximately)
    move.l  CurrentFrameTime,d0
    sub.l   PreviousFrameTime,d0
    move.l  d0,FrameCounter
    clr.l   d0
    rts
    
AddToTimer:                     *Adjusts the timer accordingly so that it can detect when the game has ended in the main loop.
    move.l  CurrentFrameTime,d0
    sub.l   PreviousFrameTime,d0
    sub.l   d0,Timer
    rts
    
IncreaseEventTimer:             *A Timer used specifically to properly time one event at the beginning if the round.            
    move.l  CurrentFrameTime,d0
    sub.l   PreviousFrameTime,d0
    add.l   d0,EventTimer
    rts
WaitForSeconds:                 *Halt execution for a given time in Hundreths of a second.
    jsr     GetTime
    move.l  d1,PreviousFrameTime  
    jsr     GetTime
    move.l  d1,CurrentFrameTime
    jsr     IncreaseEventTimer
    cmp.l   #EVENT_WAIT_TIME,EventTimer
    blt     WaitForSeconds
    move.l  #0,EventTimer
    rts
********************************************END-TIMERS*********************************    

********************************************BEGIN-CHECKINPUT*************************** 
CheckInputReverse:          *Just as it sounds. This is a version of CheckInput that iterates backwards.
    lea     InputTable,a4   *This is done so that no potential favortism is shown by always checking one
    add.l   #28,a4          *player before the other one.
    clr.l   d5
CheckAllKeysReverse:
    move.l  (a4),d2
    move.b  #GET_KEY_TASK,d0
    move.l  d2,d1
    trap #15
    cmp.b   #0,d1
    bne     CallFunction    
NoInputReverse:
    sub.l   #4,a4
    add.l   #1,d5
    cmp.l   #MESSAGE_LIMIT,d5
    blt     CheckAllKeysReverse
    rts
    
CheckInput:
    lea     InputTable,a4
    clr.l   d5
CheckAllKeys:
    move.l  (a4),d2         *Iterates through the possible key codes and checks for the corresponding input.
    move.b  #GET_KEY_TASK,d0
    move.l  d2,d1
    trap #15
    cmp.b   #0,d1
    bne     CallFunction    
NoInput:
    add.l   #4,a4
    add.l   #1,d5
    cmp.l   #MESSAGE_LIMIT,d5
    blt     CheckAllKeys
    rts
CallFunction:                *Compares all of the values to the entered key code and then branches to the proper place to perform the right check for a given area.
    lea     ActiveMessages,a0                                                           
    move.l  (a4),d2                                                                          
    cmp.l   #P1_LEFT_CODE,d2                                                            
    beq     Player1HitLeft                                                                     
    cmp.l   #P1_UP_CODE,d2                                                                      
    beq     Player1HitUp                                                                
    cmp.l   #P1_DOWN_CODE,d2                                                            
    beq     Player1HitDown                                                                 
    cmp.l   #P1_RIGHT_CODE,d2                                                                   
    beq     Player1HitRight                                                                      
    cmp.l   #P2_LEFT_CODE,d2                                                            
    beq     Player2HitLeft                                                                                                                                
    cmp.l   #P2_UP_CODE,d2
    beq     Player2HitUp
    cmp.l   #P2_DOWN_CODE,d2
    beq     Player2HitDown
Player2HitRight:             *This is repeated for each possible input
    move.l  #OFFSET_TO_LOCATION,d0  *Depending on the input we use a different offset to get the proper data.
    add.l   #OFFSET_TO_RIGHT,d0
    add.l   #OFFSET_TO_NEXT_PLAYER,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)   
    move.l  #NODE_P2_RIGHT,4(sp)    *Whenever the button is pressed we redraw the background at the messages location and despawn the message.
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)   
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P2_RIGHT,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    
    jsr DrawBitmapChunk
    lea ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown   *If the message passes the boundary check we then move on to determining score to add to the player.
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return 
    
    jsr     DetermineScoreToAdd                         
    add.w   d5,Player2Score                             *Once we return from determining the score to add, we add it to the proper players score.
    rts    
Player1HitLeft:                                         *This is repeated as needed for every input.
    move.l  #OFFSET_TO_LOCATION,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P1_LEFT,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P1_LEFT,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    
    jsr DrawBitmapChunk
    lea ActiveMessages,a0    
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player1Score
    rts
Player1HitUp:
    move.l  #OFFSET_TO_LOCATION,d0
    add.l   #OFFSET_TO_UP,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P1_UP,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P1_UP,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    jsr     DrawBitmapChunk
    lea     ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return 
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player1Score
    rts
Player1HitDown:
    move.l  #OFFSET_TO_LOCATION,d0
    add.l   #OFFSET_TO_DOWN,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P1_DOWN,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P1_DOWN,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    jsr     DrawBitmapChunk
    lea     ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return 
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player1Score
    rts
Player1HitRight:
    move.l  #OFFSET_TO_LOCATION,d0
    add.l   #OFFSET_TO_RIGHT,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P1_RIGHT,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P1_RIGHT,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    jsr     DrawBitmapChunk
    lea     ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return 
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player1Score
    rts
Player2HitLeft:
    move.l  #OFFSET_TO_LOCATION,d0
    add.l   #OFFSET_TO_NEXT_PLAYER,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P2_LEFT,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P2_LEFT,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    jsr     DrawBitmapChunk
    lea     ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return 
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player2Score
    rts
Player2HitUp:
    move.l  #OFFSET_TO_LOCATION,d0
    add.l   #OFFSET_TO_UP,d0
    add.l   #OFFSET_TO_NEXT_PLAYER,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P2_UP,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P2_UP,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    jsr     DrawBitmapChunk
    lea     ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return   
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player2Score
    rts
Player2HitDown:
    move.l  #OFFSET_TO_LOCATION,d0
    add.l   #OFFSET_TO_DOWN,d0
    add.l   #OFFSET_TO_NEXT_PLAYER,d0
    move.l  (a0,d0),d5
    move.l  d5,PositionAtKeyDown
    move.l  #BOTTOM_Y,(a0,d0)
    move.l  #NODE_P2_DOWN,4(sp)
    move.l  d5,8(sp)
    move.l  #MESSAGE_WIDTH,12(sp)
    move.l  #MESSAGE_HEIGHT,16(sp)
    move.l  #NODE_P2_DOWN,20(sp)
    move.l  d5,24(sp)
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)
    lea     ImageToLoad,a0
    jsr     DrawBitmapChunk
    lea     ActiveMessages,a0
    
    cmp.l   #START_SCORING_BOUNDARY,PositionAtKeyDown
    blt     Return
    cmp.l   #BOTTOM_Y,PositionAtKeyDown
    bge     Return 
    
    jsr     DetermineScoreToAdd
    add.w   d5,Player2Score
    rts
    
DetermineScoreToAdd:                *Gets distance from SCORE_Y of the message and uses it to evaluate what score to add.    
    move.l  #SCORE_Y,d5
    sub.l   PositionAtKeyDown,d5  
    jsr     AbsoluteValue
    jsr     DetermineScoreAmountToAdd 
    rts
    
DetermineScoreAmountToAdd:
    cmp.l   #ONE_POINT_THRESHOLD,d5
    bgt     Return
    cmp.l   #THREE_POINT_THRESHOLD,d5
    ble     Add3Points
    move.b  #POINT_CODE,d1          *Plays the scoring sound if the player scored.
    move.l  #PLAY_ONCE,d2
    jsr     PlayAudio
    move.l  #1,d5
    rts
Add3Points:
    move.b  #POINT_CODE,d1
    move.l  #PLAY_ONCE,d2
    jsr     PlayAudio
    move.l  #3,d5
    rts
       
AbsoluteValue:          *Converts the distance from SCORE_Y into an absolute distance if the result is negative.
    cmp.l   #0,d5
    bgt     Return
    mulu    #-1,d5
    rts
********************************************END-CHECKINPUT*****************************

********************************************BEGIN-SOUND********************************     
*This uses the Easy68K trap code to load WAV files by string into non-6800 memory to be played at any given time.    
LoadGameSounds:
    lea     LevelMusic,a1
    move.b  #LEVEL_AUDIO_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     MenuMusic,a1
    move.b  #MENU_MUSIC_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     VictoryMusic,a1
    move.b  #VICTORY_MUSIC_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     NoPointSound,a1
    move.b  #NO_POINT_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     PointSound,a1
    move.b  #POINT_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
   
    lea     MainTitleLine,a1
    move.b  #TITLE_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     IntroLine,a1
    move.b  #INTRO_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     JerryWinLine,a1
    move.b  #JERRY_WIN_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    
    lea     GaryWinLine,a1
    move.b  #GARY_WIN_CODE,d1
    
    move.b  #LOAD_TRACK_TASK,d0
    trap #15
    rts
*This uses the Easy68K trap code to play a loaded WAV file given it's code (assigned when loaded) and a parameter in d2 on how to play the sound.    
PlayAudio:
    move.b  #PLAY_AUDIO,d0
    trap    #15
    rts
**********************************************END-SOUND********************************
    
EndGame:                        *Once the game has ended we compare two scores and change the losers portrait to their losing portrait.
    move.w  Player1Score,d0
    cmp.w   Player2Score,d0
    bgt     Player1Wins
    move.l  #0,4(sp)
    move.l  #0,8(sp)
    move.l  #WIN_MESSAGE_WIDTH,12(sp)       *Displaying Win Message.
    move.l  #WIN_MESSAGE_HEIGHT,16(sp)  
    move.l  #WIN_MESSAGE_POSITION_X,20(sp)   
    move.l  #WIN_MESSAGE_POSITION_Y,24(sp)   
    lea     EndP2WinMessage,a0
    move.l  a0,28(sp)   
    lea     StartP2WinMessage,a0
  
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    move.l  #PORTRAIT_X,4(sp)       *Changing Jerry's portrait.        
    move.l  #PORTRAIT_Y,8(sp)
    move.l  #PORTRAIT_WIDTH,12(sp)  
    move.l  #PORTRAIT_HEIGHT,16(sp)  
    move.l  #JERRY_POSITION_X,20(sp)   
    move.l  #JERRY_POSITION_Y,24(sp)   
    lea     EndJerryLose,a0
    move.l  a0,28(sp)   
    lea     StartJerryLose,a0
  
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    move.b  #GARY_WIN_CODE,d1   *Voice Lines for Gary winning.
    move.l  #PLAY_ONCE,d2
    jsr     PlayAudio
    rts
    
Player1Wins:
    move.l  #PORTRAIT_X,4(sp)       *Changing Gary's portrait. 
    move.l  #PORTRAIT_Y,8(sp)
    move.l  #PORTRAIT_WIDTH,12(sp)  
    move.l  #PORTRAIT_HEIGHT,16(sp)  
    move.l  #GARY_POSITION_X,20(sp)   
    move.l  #GARY_POSITION_Y,24(sp)   
    lea     EndGaryLose,a0
    move.l  a0,28(sp)   
    lea     StartGaryLose,a0
  
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    move.l  #0,4(sp)
    move.l  #0,8(sp)
    move.l  #WIN_MESSAGE_WIDTH,12(sp)   *Displaying Win Message.
    move.l  #WIN_MESSAGE_HEIGHT,16(sp)  
    move.l  #WIN_MESSAGE_POSITION_X,20(sp)   
    move.l  #WIN_MESSAGE_POSITION_Y,24(sp)   
    lea     EndP1WinMessage,a0
    move.l  a0,28(sp)   
    lea     StartP1WinMessage,a0
  
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    move.b  #JERRY_WIN_CODE,d1  *Voice lines for Jerry Winning.
    move.l  #PLAY_ONCE,d2
    jsr     PlayAudio
    rts
    
START:
    jsr     LoadGameSounds      
*Here we draw the main menu BMP.
    move.l  #0,4(sp)   ;CHUNK_X *X position we start at in the BMP File.
    move.l  #0,8(sp)    ;CHUNK_Y *Y position we start at in the BMP File.
    move.l  #SCREEN_WIDTH,12(sp)  ;CHUNK_WIDTH  *Desired Width of BMP Chunk
    move.l  #SCREEN_HEIGHT,16(sp)  ;CHUNK_HEIGHT *Desired Height of BMP Chunk.
    move.l  #0,20(sp)   ;DISPLAY_X *X position we start drawing at that the BMP Chunk will be displayed at in our output window.
    move.l  #0,24(sp)   ;DISPLAY_Y *Y position we start drawing at that the BMP Chunk will be displayed at in our output window.
    lea     EndOfStartMenu,a0
    move.l  a0,28(sp)   ;Move the address of the endpoint of the BMP file onto the stack.
    lea     StartMenuBMP,a0
    
    jsr     SetDoubleBuffer
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    move.b  #MENU_MUSIC_CODE,d1 *Start the main menu music.
    move.l  #PLAY_LOOPED,d2
    jsr     PlayAudio
    
    move.b  #TITLE_CODE,d1      *Play the main title voice line.
    move.l  #PLAY_ONCE,d2
    jsr     PlayAudio
    
    move.w  #60,PreviousTimer
    move.l  #0,KeyIterator
    move.w  #0,Player1Score
    move.w  #0,Player2Score
    move.l  #0,EventTimer
    move.l  #GAME_TIMER,Timer
    move.l  #0,AmountOfMessages
    move.l  #0,ActiveMessageCount
    move.l  #0,DirectionCounter
    move.l  #STARTINGACCELERATION,d0
    mulu    #TWELFTH_POWER,d0
    move.l  d0,Acceleration
    move.l  #STARTINGVELOCITY,Velocity
    move.l  #STARTINGVELOCITY,d0
    mulu    #TWELFTH_POWER,d0
    move.l  d0,StoredVelocity              
    move.l  #0,4(sp)
    move.l  #0,8(sp)
    move.l  #SCREEN_WIDTH,12(sp)  
    move.l  #SCREEN_HEIGHT,16(sp)  
    move.l  #0,20(sp)   
    move.l  #0,24(sp)   
    lea     EndOfBitmapData,a0
    move.l  a0,28(sp)   
    lea     ImageToLoad,a0
  
    jsr     DrawBitmapChunk
*We draw the level background in the background before we start our menu loop so that there is a seamless transition.
StartMenuLoop:
    move.l  #ENTER_CODE,d2          *We wait for Enter to be hit before we start the game.
    move.b  #GET_KEY_TASK,d0
    move.l  d2,d1
    trap #15
    cmp.b   #0,d1
    beq     StartMenuLoop 
    
    jsr     Repaint
    
    move.b  #MENU_MUSIC_CODE,d1     *We stop the main menu theme.
    move.l  #STOP_PLAYING,d2
    jsr     PlayAudio
    
    move.b  #INTRO_CODE,d1          *We start playing the intro voice lines.
    move.l  #PLAY_ONCE,d2
    jsr     PlayAudio
    
    move.l  #PORTRAIT_X,4(sp)               *Here we draw both Jerry and Gary's idle portraits.
    move.l  #PORTRAIT_Y,8(sp)
    move.l  #PORTRAIT_WIDTH,12(sp)  
    move.l  #PORTRAIT_HEIGHT,16(sp)  
    move.l  #JERRY_POSITION_X,20(sp)   
    move.l  #JERRY_POSITION_Y,24(sp)   
    lea     EndJerryIdle,a0
    move.l  a0,28(sp)   
    lea     StartJerryIdle,a0
  
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    move.l  #PORTRAIT_X,4(sp)
    move.l  #PORTRAIT_Y,8(sp)
    move.l  #PORTRAIT_WIDTH,12(sp)  
    move.l  #PORTRAIT_HEIGHT,16(sp)  
    move.l  #GARY_POSITION_X,20(sp)   
    move.l  #GARY_POSITION_Y,24(sp)   
    lea     EndGaryIdle,a0
    move.l  a0,28(sp)   
    lea     StartGaryIdle,a0
  
    jsr     DrawBitmapChunk
    jsr     Repaint
    
    jsr     WaitForSeconds          *We wait for a set time (EVENT_WAIT_TIME), and then we continue. This is to let the voice lines play all the way through.
    
    move.l  #UI_COLOR,d1           *Set the fill of the LED Timer to red.
    jsr     SetFill
    
    jsr     DrawTensSix
    jsr     DrawOnesZero
    
    move.b  #LEVEL_AUDIO_CODE,d1    *Start the level music and the game.
    move.l  #PLAY_LOOPED,d2
    jsr     PlayAudio
    
    jsr     AllocateMessages
    
GameLoop:
    jsr     DrawLED
    jsr     CheckInput
    jsr     GetTime
    move.l  d1,PreviousFrameTime
    jsr     SpawnMessagePair
    jsr     ResetMessageCounter
    jsr     DrawMessage
    jsr     ResetMessageCounter
    jsr     CheckInputReverse
    jsr     SetVelocity
    jsr     UpdateVelocity  
    jsr     GetTime
    move.l  d1,CurrentFrameTime
    jsr     AddToTimer
    cmp.l   #0,Timer
    bgt     GameLoop
    
    move.b  #LEVEL_AUDIO_CODE,d1    *Stop playing the level audio when the game loop is finished. 
    move.l  #STOP_PLAYING,d2
    jsr     PlayAudio
    
    jsr     EndGame
    
Exit:
    SIMHALT 

ImageToLoad     INCBIN "BGFinal.bmp"
EndOfBitmapData     ds.w $1
ArrowsImage     INCBIN "Arrows.bmp"
EndOfArrows         ds.w $1
StartMenuBMP    INCBIN "StartMenu.bmp"
EndOfStartMenu      ds.w $1
StartP1WinMessage   INCBIN "Player1Win.bmp"
EndP1WinMessage     ds.w $1
StartP2WinMessage   INCBIN "Player2Win.bmp"
EndP2WinMessage     ds.w $1
StartJerryIdle      INCBIN "JerryTVIdle.bmp"
EndJerryIdle        ds.w $1
StartGaryIdle       INCBIN "GaryTVIdle.bmp"
EndGaryIdle         ds.w $1
StartJerryLose      INCBIN "JerryTVLose.bmp"
EndJerryLose        ds.w $1
StartGaryLose       INCBIN "GaryTVLose.bmp"
EndGaryLose         ds.w $1
Acceleration        ds.l $1
Velocity            ds.l $1
StoredVelocity      ds.l $1
AmountOfMessages    ds.l $1
ActiveMessageCount  ds.l $1
DirectionCounter    ds.l $1
PreviousFrametime   ds.l $1
CurrentFrameTime    ds.l $1
FrameCounter        ds.l $1
Timer               ds.l $1
PreviousTimer       ds.w $1
EventTimer          ds.l $1

InputTable          dc.l $41,$57,$53,$44,$4A,$49,$4B,$4C

FunctionTable       dc.l Player1HitLeft,Player1HitUp,Player1HitDown,Player1HitRight,Player2HitLeft,Player2HitUp,Player2HitDown,Player2HitRight
OnesLEDHolder       dc.l DrawOnesZero,DrawOnesOne,DrawOnesTwo,DrawOnesThree,DrawOnesFour,DrawOnesFive,DrawOnesSix,DrawOnesSeven,DrawOnesEight,DrawOnesNine
TensLEDHolder       dc.l DrawTensZero,DrawTensOne,DrawTensTwo,DrawTensThree,DrawTensFour,DrawTensFive,DrawTensSix    
MessagePointer          ds.l $1
ActiveMessages          ds.l $20
MessageChunkX           ds.l $4
MessageSpawnLocations   ds.l $8

KeyIterator             ds.l $1

PositionAtKeyDown       ds.l $1

Player1Score            ds.w $1
Player2Score            ds.w $1

LevelMusic              dc.b 'LevelMusic.wav',0
MenuMusic               dc.b 'MenuMusic.wav',0
VictoryMusic            dc.b 'Victory.wav',0
NoPointSound            dc.b 'OnePoint.wav',0
PointSound              dc.b 'Scored.wav',0
MainTitleLine           dc.b 'MainTitleLine.wav',0
IntroLine               dc.b 'IntroLines.wav',0
JerryWinLine            dc.b 'JerryWinLine.wav',0
GaryWinLine             dc.b 'GaryWinLine.wav',0
       
    END    START        
    














































*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
