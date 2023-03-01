***********************BMP FILE FORMAT CONSTANTS*******************
TO_PIXEL_OFFSET EQU 10  *BMP File format standard offset to location holding the offset to the beginning of the actual pixel data. 
TO_WIDTH        EQU 18  *BMP File format standard offset to Width of bitmap.
TO_HEIGHT       EQU 22  *BMP File format standard offset to Height of bitmap.
TO_END_OF_PIXEL_DATA    EQU 6 *This is the value of the offset from the end of the BMP file to the end of the pixel data. This is used because we start rendering from the top right which in absolute terms, is the bottom of the pixel data.
BMP_SIGNATURE   EQU $424D

****************************TRAP CODES*****************************
WINDOW_SIZE_ADJUSTMENT_TRAP EQU 33
SET_PEN_COLOR_TRAP  EQU 80
DRAW_PIXEL_TRAP EQU 82
PRINT_STRING_TRAP EQU 13
RED EQU $000000FF

    ORG $1000
ClearValues:
    clr.w   WIDTH
    clr.w   HEIGHT              
    clr.l   WIDTH_OFFSET        
    clr.l   ROW_OFFSET         
    clr.l   EFFECTIVE_HEIGHT    
    clr.w   EFFECTIVE_CHUNK_X      
    clr.l   CHUNK_X         
    clr.l   CHUNK_Y         
    clr.l   CHUNK_WIDTH      
    clr.l   CHUNK_HEIGHT      
    clr.l   DISPLAY_X           
    clr.l   DISPLAY_Y
    rts           
StandardSwap:               *Standard Swap takes the little endian formatted numbers from the bitmap data and converts them into big endian so that we can handle the given data such as Width,Height, and Offset.
    move.l 12(sp),d0
    ror.w   #8,d0           *This is done by first rotating the right most word of data and then swapping the words contained in the long and then repeating the rotation. This effectively reverses the waythe number was stored in the bitmap data. 
    swap.w  d0
    ror.w   #8,d0
    
    rts
    
PixelSwap:
    move.l  12(sp),d0        *The pixel data must be handled differently from how the standard numbers are handled. 
    asr.l   #8,d0           *We want to make sure that the alpha channel value is the left most digit. As it is stored now it is not. To fix this we need to do an arithmetic shift right by 8 (The size of a byte).
    swap.w  d0
    ror.w   #8,d0
    clr.b   d0              *One observed issue was that the right shift can occasionlly lead to non-zero values. Any non-zero value results in incorrect rendering.
    ror.w   #8,d0           *For our purposes we will alleviate this by removing the extraneous alpha channel data and setting it to zero.
    swap.w  d0           
    
    rts

DrawBitmapChunk:
    move.l  8(sp),CHUNK_X
    move.l  12(sp),CHUNK_Y
    move.l  16(sp),CHUNK_WIDTH
    move.l  20(sp),CHUNK_HEIGHT
    move.l  24(sp),DISPLAY_X
    move.l  28(sp),DISPLAY_Y
    move.l  32(sp),BitmapEndpoint

*Verify the chosen file is a BMP file    
    move.w  (a0),d0
    cmp.w   #BMP_SIGNATURE,d0
    bne     InvalidFile
    
*WIDTH
    move.l  a0,a1               *We manipulate the address register using the TO_WIDTH value to point to the Width information for the bitmap file. We use the Standard Swap here to get the correct value.
    add.l   #TO_WIDTH,a1
    move.l  (a1),d3
    move.l  d3,8(sp)
    jsr     StandardSwap
    move.l  d0,d3
    move.w  d3,WIDTH            *We store the result into WIDTH.

*HEIGHT
    move.l  a0,a1               *We manipulate the address register using the TO_HEIGHT value to point to the Height information for the bitmap file. We use the Standard Swap here to get the correct value.
    add.l   #TO_HEIGHT,a1
    move.l  (a1),d7
    move.l  d7,8(sp)
    jsr     StandardSwap
    move.l  d0,d7
    move.w  d7,HEIGHT           *We store the result into HEIGHT
   
*Find Initial Offset To Pixel Data
    move.l  BitmapEndpoint,a1
    sub.l   #6,a1
    move.l  d3,(a3)
    move.l  d3,d5
    
    clr.l   d3
    clr.l   d6   
    
DetermineEffectiveOffset:
    clr.l   EFFECTIVE_CHUNK_X                   *EFFECTIVE_CHUNK_X is the "actual" x value since we draw from right to left. However for conventional use, we allow input as if we were using the top left corner of the bitmap. This accounts for that disparity.
    move.l  CHUNK_X,EFFECTIVE_CHUNK_X
    move.l  CHUNK_WIDTH,d0
    add.l   d0,EFFECTIVE_CHUNK_X
    move.w  WIDTH,d0
    sub.l   EFFECTIVE_CHUNK_X,d0
    move.l  d0,WIDTH_OFFSET                     *WIDTH_OFFSET is used later to find the total number of bytes needed to skip to our desired position in the pixel data.
    move.l  CHUNK_Y,d0

    muls     WIDTH,d0
    add.l    WIDTH_OFFSET,d0                    *The total number of pixels to skip would be the CHUNK_Y value multiplied by the width since the amount of pixels in the rows we "pass" would be equal to CHUNK_Y · WIDTH 
    
    asl.l   #2,d0                               *The pixel data is stored in longs so we can do an arithmetic shift left by 2 to multiply by 4. (This is because 2 to the second power is 4).         
    sub.l   d0,a1
    add.l   #4,a1

    clr.l   d0
    move.w  WIDTH,d0                            *Here we do something similar and determine a row offset.
    sub.l   CHUNK_WIDTH,d0                     *This is important because we need the row offset ot account for skipping parts of a row if your bitmap chunk spans a width that is less than the total width of the bitmap.

 
    asl.l   #2,d0
    sub.l   #4,d0
    move.l  d0,ROW_OFFSET
    
    move.l  DISPLAY_X,d5                       *We add the DISPLAY_X and the CHUNK_WIDTH to start at the correct top right pixel to draw.
    add.l   CHUNK_WIDTH,d5
    move.l  DISPLAY_Y,d6
    move.l  DISPLAY_X,d3                   
    
    move.l  #0,EFFECTIVE_HEIGHT  
    move.l  EFFECTIVE_HEIGHT,d0
    
    move.l  CHUNK_HEIGHT,EFFECTIVE_HEIGHT
    move.l  DISPLAY_Y,d0
    add.l   d0,EFFECTIVE_HEIGHT         *We combine the CHUNK_HEIGHT and DISPLAY_Y so that the correct pixels are rendered in our output window.
    move.l  EFFECTIVE_HEIGHT,d0
    
Draw:
    move.l  (a1),d1
    move.l  d1,8(sp)
    jsr     PixelSwap
    move.l  d0,d1           *We use the Pixel Swap to correctly arrange the pixel data.
    
    
    move.b  #SET_PEN_COLOR_TRAP,d0
    trap #15                *We set the Pen Color to the retrieved pixel color.
    move.w  d5,d1
    move.w  d6,d2
    move.b  #DRAW_PIXEL_TRAP,d0          *We use d5 and d6 from earlier to begin drawing our chunk.
    trap #15
    sub.l   #4,a1
    sub.w   #1,d5
    cmp.w   d3,d5           *We wait until we run out of pixels width-wise until we then move to the next row.
    bge     Draw

NextRow:
    sub.l   ROW_OFFSET,a1   *We subtract the address register by the ROW_OFFSET to maintain image accuracy.
    move.l  CHUNK_WIDTH,d5
    add.l   DISPLAY_X,d5
    add.w   #1,d6
    move.l  EFFECTIVE_HEIGHT,d0
    cmp.l   d0,d6
    bne     Draw            *We continue the process until we have reached the last row and then exit the program with our drawn bitmap on the screen.
    jsr     ClearValues 
    rts
    
ChunkSizeErrorX:
    move.l  #PRINT_STRING_TRAP,d0                              *If we encounter an out of bounds situation, we print an error to the screen and terminate the program.
    lea     OUT_OF_BOUNDS_TEXT_X,a1
    trap #15
    SIMHALT
    
ChunkSizeErrorY:
    move.l  #PRINT_STRING_TRAP,d0                              *If we encounter an out of bounds situation, we print an error to the screen and terminate the program.
    lea     OUT_OF_BOUNDS_TEXT_Y,a1
    trap #15
    SIMHALT
    
DisplayBoundsErrorX:
    move.l  #PRINT_STRING_TRAP,d0                              *If we encounter an out of bounds situation, we print an error to the screen and terminate the program.
    lea     DISPLAY_OUT_OF_BOUNDS_TEXT_X,a1
    trap #15
    SIMHALT
    
DisplayBoundsErrorY:
    move.l  #PRINT_STRING_TRAP,d0                              *If we encounter an out of bounds situation, we print an error to the screen and terminate the program.
    lea     DISPLAY_OUT_OF_BOUNDS_TEXT_Y,a1
    trap #15
    SIMHALT
NegativeHandler:
    move.l  #PRINT_STRING_TRAP,d0                              *If we encounter a negative user input, we will kindly yet firmly tell them to correct it.
    lea     NEGATIVE_HANDLER_TEXT,a1
    trap #15
    SIMHALT
InvalidFile:
    move.l  #PRINT_STRING_TRAP,d0
    lea     INVALID_TEXT,a1
    trap #15
    SIMHALT
                                             
WIDTH               ds.w $1
HEIGHT              ds.w $1
WIDTH_OFFSET        ds.l $1
ROW_OFFSET          ds.l $1
EFFECTIVE_HEIGHT    ds.l $1
EFFECTIVE_CHUNK_X   ds.w $1
PREVIOUS_COLOR      ds.l $1
CHUNK_X             ds.l $1
CHUNK_Y             ds.l $1
CHUNK_WIDTH         ds.l $1
CHUNK_HEIGHT        ds.l $1
DISPLAY_X           ds.l $1
DISPLAY_Y           ds.l $1
INVALID_TEXT  dc.l 'ERROR: FILE NOT RECOGNIZED AS BMP. Please try another file',0
OUT_OF_BOUNDS_TEXT_X  dc.l 'ERROR: CHUNK_X Sorry, the desired bitmap chunk is out of bounds. Please try again.',0
OUT_OF_BOUNDS_TEXT_Y  dc.l 'ERROR: CHUNK_Y Sorry, the desired bitmap chunk is out of bounds. Please try again.',0
DISPLAY_OUT_OF_BOUNDS_TEXT_X  dc.l 'ERROR: DISPLAY_X Current display parameters will not draw full bitmap Chunk',0
DISPLAY_OUT_OF_BOUNDS_TEXT_Y  dc.l 'ERROR: DISPLAY_Y Current display parameters will not draw full bitmap Chunk',0
NEGATIVE_HANDLER_TEXT  dc.l 'ERROR: ONE OR MORE NEGATIVE INPUTS. Please correct and try again.',0
BitmapEndpoint  ds.l    $1
  

    ;END START     

    
    


























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
