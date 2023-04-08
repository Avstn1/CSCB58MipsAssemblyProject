#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Austin, 1007299219, bartol27, austin.bartolome@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################


# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#

.data

bitmap_address: .space 524288# spacer to avoid overflow into data array

.eqv BASE_ADDRESS 0x10008000
.eqv UNIT_WIDTH 4
.eqv UNIT_HEIGHT 4
.eqv DISPLAY_WIDTH 256
.eqv DISPLAY_HEIGHT 256
.eqv WAIT_TIME 1


.eqv JUMP_HEIGHT 45

.eqv GRAVITY_WAIT 9
.eqv JUMP_WAIT 8
.eqv PLATFORM_WAIT 9

.eqv QUICK_FALL_VALUE 1

.eqv NO_JUMP 6
.eqv NO_LEFT 7
.eqv NO_RIGHT 8
.eqv FAST_FALL 9
.eqv GRAVITY_TRUE 10

# Movement constants
.eqv LEFT -4
.eqv RIGHT 4
.eqv UP -512
.eqv DOWN 512


double_jump:	.word 4
	
platform_pixel: .word 4	
iteration: 	.word 4
	
pebble_pixel:	.word 4
pebble_collected: 
		.word 4
		
score:		.word 4
health:		.word 4

enemy_pass:	.word 4

you_lose:	.asciiz "youlose.txt"
you_lose_yes: 	.asciiz "youloseyes.txt"
you_lose_no: 	.asciiz "youloseno.txt"
start_game:	.asciiz "startgame.txt"
delete_start_game:
		.asciiz "deletestartgame.txt"
		

newline:	.asciiz "\n"

you_lose_start:
	.asciiz "        "
	

##########################################################################
# MAIN
.text

main:	
	li $sp, 0 # reset stack just in case
RESTART:
	jal GENERATE_BACKGROUND

##########################################################################
# Load start menu!!!!

START:

	jal LEVEL_1
	
##########################################################################


	# dedicate $t0 to the beginning pixel character value
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 66032
	
	addi $sp, $sp, -4 # Load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

	la $t1, start_game
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE

	
start_menu:
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_start_menu
	j start_menu
keypress_start_menu:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x70, commence_game
	j start_menu

#########################################################################
commence_game:
	la $t1, delete_start_game
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE
	
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 66032
	
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal DELETE_ROCK
	
	# dedicate $t0 to the beginning pixel character value
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 66032
	
	addi $sp, $sp, -4 # Load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK
	
	jal LEVEL_1
	
	
# Memory storing
	# Store pebble pixel into memory
	la $t3, pebble_pixel
	li $t9, BASE_ADDRESS
	addi $t9, $t9, 59904
	sw $t9, 0($t3)
	
	# Store pebble collected boolean into memory
	la $t3, pebble_collected
	li $t4, 0
	sw $t4, 0($t3)
	
	# Store score into memory
	la $t3, score
	li $t4, 0
	sw $t4, 0($t3)
		
	# Store health into memory	
	la $t3, health
	li $t4, 3
	sw $t4, 0($t3)

	# Get memory of pebble pixel and address
	la $t3, pebble_pixel
	la $t4, pebble_collected
	lw $t3, 0($t3)
	lw $t4, 0($t4)
	
	addi $sp, $sp, -4 # Load pebble boolean into stack 
	sw $t4, 0($sp)
	addi $sp, $sp, -4 # Load pebble pixel into stack
	sw $t3, 0($sp)
	jal GENERATE_PEBBLE
	
	la $t3, double_jump
	li $t4, 0
	sw $t4, 0($t3)
	
	# Store randomized pebble pixel in stack
	li $t3, 1000
	la $t4, platform_pixel
	sw $t3, 0($t4)
	
	li $t1, BASE_ADDRESS
	addi $t1, $t1, 32764
	
##########################################
# True Game Loop

gravity_loop:

	
# Check player enemy collision
	la $t5, enemy_pass # let enemy pass a little bit otherwise you will lose right away
	lw $t5, ($t5)
	bgt $t5, 0, LEVEL1
	
	addi $sp, $sp, -4 # load pebble pixel value
	sw $t1, 0($sp)
	addi $sp, $sp, -4 # load rock pixel value
	sw $t0, 0($sp)
	jal PEBBLE_COLLECTED
	
	la $t5, pebble_collected
	lw $t5, 0($t5)
	beq $t5, 1, decrease_health
	
	j LEVEL1
decrease_health:
	# allows enemy to pass without fully damaging rock
	la $t5, enemy_pass
	li $t6, 10
	sw $t6, 0($t5)

	la $t5, pebble_collected
	li $t6, 0
	sw $t6, 0($t5)

	la $t5, health
	lw $t6, 0($t5)
	addi $t6, $t6, -1
	sw $t6, 0($t5)
	
# Check score

# Level spawn
LEVEL1:
	
	la $t5, enemy_pass
	lw $t6, 0($t5)
	addi $t6, $t6, -1
	sw $t6, 0($t5)
	
	jal LEVEL_1
	
	jal DISPLAY_SCORE
	
	jal DISPLAY_HEALTH
	
	# Check health
	la $t3, health
	lw $t3, 0($t3)
	beq $t3 ,$zero, END
	
		
			
skip_levels:	
############################################################
# Pebble Spawning
	la $t5, pebble_pixel
	lw $t4, 0($t5)
		
	addi $sp, $sp, -4 # load pebble pixel value
	sw $t4, 0($sp)
	addi $sp, $sp, -4 # load rock pixel value
	sw $t0, 0($sp)
	jal PEBBLE_COLLECTED
	
	la $t4, pebble_pixel
	lw $t6, 0($t4)
	
	la $t5, pebble_collected
	lw $t5, 0($t5)
		
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	addi $sp, $sp, -4
	sw $t6, 0($sp)
	jal GENERATE_PEBBLE
	
	
##########################################
#enemy_spawn
	# Deal with enemy movement
		
	la $t3, iteration
	lw $t3, 0($t3)
	beq $t3, 127, reset_iteration
	j no_reset
reset_iteration:

	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal DELETE_ENEMY

	la $t3, iteration
	li $t4, 0
	sw $t4, 0($t3)
	
	li $v0, 42
	li $a0, 0
	li $a1, 70
	syscall
	
	addi $t3, $a0, 20
	li $t4, 1024
	mult $t3, $t4
	mflo $t3
	addi $t3, $t3, -16 # Randomized pixel will be at the right edge
	addi $t3, $t3, BASE_ADDRESS
	addi $t1, $t3, 0
	
no_reset:

	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal DELETE_ENEMY
	
	addi $t1, $t1, -8
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal GENERATE_ENEMY
	
	la $t5, iteration
	lw $t4, 0($t5)
	addi $t4, $t4, 1
	sw $t4, 0($t5)
	

	beq $s3, 999999, back_from_top
	beq $s3, 999998, move_check_from_top
	
############################################################
# Platform Check
	li $t2, GRAVITY_TRUE
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	beq $t5, 0, move_check
	
	j normal_gravity

quick_fall:
	j skip_gravity

############################################################################
# DEALS WITH PLAYER MOVEMENT
normal_gravity:
	li $v0, 32
	li $a0, GRAVITY_WAIT # Wait 32 mss
	syscall
skip_gravity:
	li $t2, GRAVITY_TRUE
	# Check if touched border or water
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4

	beq $t5, 0, move_check
skip_move_check:
	# Paint below pixel black
	addi $t5, $t0, 0
	addi $t0, $t0, 1024
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK
	
# Continue to check for input while falling
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened_gravity
	j gravity_loop

move_check: # used to check for move whiile on platform
# Initialize key press
	la $t4, double_jump
	li $t5, 0
	sw $t5, 0($t4)
	
	li $s3, 999998
	j gravity_loop
move_check_from_top:
	li $v0, 32
	li $a0, PLATFORM_WAIT # Wait 32 milliseconds
	syscall
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK
	
	li $t2, GRAVITY_TRUE
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	
	li $s3, 0
	beq $t5, NO_JUMP, gravity_loop
	
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened_platform
	
	j move_check
	
keypress_happened_gravity:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, respond_to_a_gravity # ASCII code of 'a' is 0x61
	beq $t2, 0x64, respond_to_d_gravity # ASCII code of 'd' is 0x64 
	beq $t2, 0x73, quick_fall
	beq $t2, 0x77, respond_to_w_gravity
	#beq $t2, 0x66, FIRE_PEBBLE
	beq $t2, 0x70, END
	j gravity_loop
	
keypress_happened_platform:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, respond_to_a_gravity # ASCII code of 'a' is 0x61
	beq $t2, 0x64, respond_to_d_gravity # ASCII code of 'd' is 0x64 
	beq $t2, 0x73, skip_move_check
	beq $t2, 0x77, respond_to_w # ASCII code of 'w' is 0x77 
	#beq $t2, 0x66, FIRE_PEBBLE
	beq $t2, 0x70, END
	j gravity_loop
	
respond_to_a_gravity:
# Prepare parameters in a stack to call CAN_MOVE
	# Check if touched border or water
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	
	beq $t5, 0, gravity_loop # don't paint to screen if at right border ($t5 == 0)
	
	# Paint left pixel black
	addi $t5, $t0, 0
	addi $t0, $t0, -32
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK
	
	j gravity_loop

respond_to_d_gravity:
	# Check if touched border or water
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	
	beq $t5, 0, gravity_loop # don't paint to screen if at right border ($t5 == 0)
	
	# Paint right pixel black
	addi $t5, $t0, 0
	addi $t0, $t0, 32
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

	j gravity_loop

respond_to_w_gravity:
	la $t3, double_jump
	lw $t3, 0($t3)
	bge $t3, 2, gravity_loop
	j respond_to_w

	
############################################
# TO RESPOND TO W CLICK AND JUMP
##########################################
respond_to_w:
	la $t4, double_jump
	addi $t5, $t5, 1
	sw $t5, 0($t4)
jumped_once:
	li $s6, 0
jump_loop:
	li $s3, 999999 # Information register about jumping back to jump_loop
	j gravity_loop # jump to main loop to let enemies and platform spawn mid jump
back_from_top:
	li $s3, 0
	# Check if touched border or water
	li $t2, 0x77
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	
	beq $t5, 0, gravity_loop # don't paint to screen if at border ($t5 == 0)	
	beq $t5, NO_JUMP, gravity_loop

	addi $t5, $t0, 0
	addi $t0, $t0, -1024

	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened_jumping
jump_sleep:
	li $v0, 32
	li $a0, JUMP_WAIT # Wait 30 milliseconds
	syscall
	addi $s6, $s6, 1
	bne $s6, JUMP_HEIGHT, jump_loop
	li $s3, 0
	j gravity_loop
	
keypress_happened_jumping:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, respond_to_a_jumping # ASCII code of 'a' is 0x61
	beq $t2, 0x64, respond_to_d_jumping # ASCII code of 'd' is 0x64
	beq $t2, 0x73, respond_to_s_jumping # jump cancel
	beq $t2, 0x77, respond_to_w_jumping
	beq $t2, 0x70, END
	j jump_sleep
	
respond_to_a_jumping:
# Prepare parameters in a stack to call CAN_MOVE

	# Check if touched border or water
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	
	beq $t5, 0, gravity_loop # don't paint to screen if at right border ($t5 == 0)
	
	# Paint upper pixel
	addi $t5, $t0, 0
	addi $t0, $t0, -32
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK
	
	j jump_sleep

respond_to_d_jumping:

	# Check if touched border or water
	addi $sp, $sp, -4
	sw $t2, 0($sp) # Load current move
	addi $sp, $sp, -4
	sw $t0, 0($sp) # Load current pixel
	jal CAN_MOVE
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	
	beq $t5, 0, gravity_loop # don't paint to screen if at right border ($t5 == 0)
	
	# Paint right pixel black
	
	addi $t5, $t0, 0
	addi $t0, $t0, 32
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

	j jump_sleep
	
respond_to_w_jumping:
	la $t4, double_jump
	lw $t6, 0($t4)
	bge $t6, 2, jump_sleep
	addi $t6, $t6, 1
	sw $t6, 0($t4)
	j respond_to_w
	
respond_to_s_jumping:
	li $s3, 0
	j gravity_loop
##################################################################
# END GAME AND QUIT? OR RESTART
END:
	la $t1, you_lose
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE	

load_yes:
	la $t1, you_lose_yes
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE
yes_menu:
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_yes_menu
	j yes_menu
keypress_yes_menu:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x64, load_no
	beq $t2, 0x70, RESTART
	j yes_menu

load_no:
	la $t1, you_lose_no
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE
	
no_menu:
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_no_menu
	j no_menu
keypress_no_menu:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, load_yes # ASCII code of 'a' is 0x61
	beq $t2, 0x70, terminate
	j no_menu
terminate:
	li $v0, 10 # terminate the program gracefully
	syscall
	
	
####################################################################################################################
# NECESSARY FUNCTIONS

DELETE_ROCK:
	lw $t6, 0($sp) # pop old pixel value off the stack
	addi $sp, $sp, 4 # reclaim space
	
	li $t7, 0x4dabf7
	li $t4, 0
	addi $t5, $t4, 28
loop_one:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_one

	addi $t6, $t6, 992
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 20
loop_two:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_two
	sw $t7, 0($t6)
	
	addi $t6, $t6, 988
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	sw $t7, 0($t6)
	
	li $t4, 0
	addi $t5, $t4, 32
loop_three:

	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_three
	sw $t7, 0($t6)
	
	addi $t6, $t6, 980
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 40
	li $t2, 0x595959
loop_four:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_four
	sw $t7, 0($t6)
	
	addi $t6, $t6, 980
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 36
	li $t2, 0x555555
loop_five:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_five
	sw $t7, 0($t6)
	
	addi $t6, $t6, 984
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 32
	li $t2, 0x505050
loop_six:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_six
	sw $t7, 0($t6)
	
	addi $t6, $t6, 992
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 28
loop_seven:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, loop_seven
	
	jr $ra
	

GENERATE_ROCK:
	lw $t6, 0($sp) # load the new pixel value
	addi $sp, $sp, 4
	
	# Reset and initialize registers
	li $t7, 0x000000
	li $t3, 0xbfbaba
	
	li $t5, 0
	li $t4, 0
	addi $t5, $t4, 28
rock_one:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_one

	addi $t6, $t6, 992
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	sw $t3, 0($t6)
	addi $t6, $t6, 4
	sw $t3, 0($t6)
	addi $t6, $t6, 4
	
	li $t2, 0x616161
	li $t4, 0
	addi $t5, $t4, 20
rock_two:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_two
	sw $t7, 0($t6)
	
	addi $t6, $t6, 988
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	sw $t3, 0($t6)
	addi $t6, $t6, 4
	sw $t3, 0($t6)
	
	li $t4, 0
	addi $t5, $t4, 32
rock_three:

	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_three
	sw $t7, 0($t6)
	
	addi $t6, $t6, 980
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 40
	li $t2, 0x595959
rock_four:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_four
	sw $t7, 0($t6)
	
	addi $t6, $t6, 980
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 36
	li $t2, 0x555555
rock_five:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_five
	sw $t7, 0($t6)
	
	addi $t6, $t6, 984
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 32
	li $t2, 0x505050
rock_six:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_six
	sw $t7, 0($t6)

	addi $t6, $t6, 992
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 28
rock_seven:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, rock_seven

	jr $ra
	
################################################################

	# Calculate original row
	#li $t8, 1024
	#li $t9, 4
	#mult $t8, $t9
    	#mflo $t8
    	#div $t6, $t8
    	#mflo $t3

	
###########################################################################
# Platform generation
GENERATE_PLATFORM:
	lw $t6, 0($sp) # load the offset
	addi $sp, $sp, 4
	
	
	# comments to help 
	# load y coordinate

	addi $t6, $t6, BASE_ADDRESS
	
	li $t7, 0x8e8e8e
	li $t2, 0xffffff
	
	li $t4, 0
	li $t5, 0
	addi $t5, $t4, 120
cloud_one:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_one

	addi $t6, $t6, 900
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 120
	li $t2, 0xf7f2f2
cloud_two:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_two
	
	sw $t7, 0($t6)

	addi $t6, $t6, 900
	sw $t7, 0($t6)
	addi $t6, $t6, 4

	li $t4, 0
	addi $t5, $t4, 120
	li $t2, 0xdbdbdb
cloud_three:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_three
	
	sw $t7, 0($t6)

	addi $t6, $t6, 904
	sw $t7, 0($t6)
	addi $t6, $t6, 4

	li $t4, 0
	addi $t5, $t4, 120
	li $t2, 0xbdbbbb
cloud_four:
	sw $t2, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_four
	
	jr $ra
	
	
DELETE_PLATFORM:
	lw $t6, 0($sp) # load the new pixel value
	addi $sp, $sp, 4
	
	addi $t6, $t6, BASE_ADDRESS
	
	li $t7, 0x4dabf7
	
	li $t4, 0
	li $t5, 0
	addi $t5, $t4, 120
cloud_delete_one:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_delete_one

	addi $t6, $t6, 900
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	
	li $t4, 0
	addi $t5, $t4, 120
cloud_delete_two:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_delete_two
	
	sw $t7, 0($t6)

	addi $t6, $t6, 900
	sw $t7, 0($t6)
	addi $t6, $t6, 4

	li $t4, 0
	addi $t5, $t4, 120
cloud_delete_three:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_delete_three
	
	sw $t7, 0($t6)

	addi $t6, $t6, 904
	sw $t7, 0($t6)
	addi $t6, $t6, 4

	li $t4, 0
	addi $t5, $t4, 120
cloud_delete_four:
	sw $t7, 0($t6)
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, cloud_delete_four
	
	jr $ra
	


###########################################
# Fucntion for displaying a picture in the bitmap display
LOAD_PICTURE:
	lw $t2, 0($sp)  # offset
	lw $t8, 4($sp)  # address of image filename
	addi $sp, $sp, 8
	add $t2, $t2, BASE_ADDRESS
	# Open the input file for reading
	li $v0, 13         # System call code for open
	la $a0, 0($t8)      # Load the filename address into $a0
	li $a1, 0          # Flags (0 for read-only)
	li $a2, 0          # Mode (ignored for read-only)
	syscall
	move $t5, $v0      # Save the file descriptor in $t5

	li $t4, 0
picture_loop:
	# Read 8 bytes from the file
	li $v0, 14            # System call code for read
	move $a0, $t5         # Load the file descriptor into $a0
	la $a1, you_lose_start       # Load the start address of the buffer into $a1
	li $a2, 8            # Maximum number of bytes to read
	syscall
	
	# Convert the ASCII string to a decimal valuet
	la $t6, you_lose_start        # Load the address of the buffer string into $t6
	addi $t6, $t6, 2      # Skip over the "0x" prefix
	li $t7, 0             # Initialize decimal value to zero
loop:
    	lbu $t8, 0($t6)         # Load current character into $t8
    	beqz $t8, end_loop     # Exit loop if current character is null terminator

    	bge $t8, 97, sub_a     # If character is a-f, subtract 87 to convert to decimal
    	bge $t8, 65, sub_A     # If character is A-F, subtract 55 to convert to decimal
    	bge $t8, 48, sub_0   # If character is 0-9, jump to common
    	
    	# Character is invalid, so terminate the program
    	li $v0, 10             # System call code for exit
    	li $a0, 1              # Return value indicating error
    	syscall
    	j end_loop

sub_a:
    	sub $t9, $t8, 87       # Subtract 87 to convert a-f to decimal
    	j common

sub_A:
    	sub $t9, $t8, 55       # Subtract 55 to convert A-F to decimal
    	j common

sub_0:
	sub $t9, $t8, 48       # Convert ASCII code to decimal value
	j common

common:
    	li $t3, 16
	multu $t7, $t3         # Multiply current value by 16 (since we're reading in hex) 
	mflo $t3	
	addu $t7, $t3, $t9   	 	
    	addi $t6, $t6, 1       # Move to next character in string
    	j loop
end_loop:
	beq $t7, 5197647, skip_draw
	sw $t7, 0($t2)
	
skip_draw:
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 131072 , picture_loop
	
	# Close the file
	li $v0, 16            # System call code for close
	move $a0, $t5         # Load the file descriptor into $a0
	syscall

	jr $ra


################################################################
GENERATE_ENEMY:
	lw $t2, 0($sp) # load enemy pixel value 
	addi $sp, $sp, 4

	li $t6, 0x000000
	li $t4, 0
enemy1_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, enemy1_loop
	
	addi $t2, $t2, 1004
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	
	li $t5, 0xff0000
	li $t4, 0
enemy2_loop:
	sw $t5, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, enemy2_loop
	
	sw $t6, 0($t2)
	
	addi $t2, $t2, 1004
	li $t4, 0
enemy3_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 24, enemy3_loop
	# output pixel value back to memory
enemy_end:
	jr $ra


################################################################
DELETE_ENEMY:
	lw $t2, 0($sp)
	addi $sp, $sp, 4

	li $t6, 0x4dabf7
	li $t4, 0
delete_enemy1_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, delete_enemy1_loop

	addi $t2, $t2, 1004
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	
	li $t4, 0
delete_enemy2_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, delete_enemy2_loop
	
	sw $t6, 0($t2)
	
	addi $t2, $t2, 1004
	li $t4, 0
delete_enemy3_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 24, delete_enemy3_loop
	
	# output pixel value back to memory
	
delete_enemy_end:
	jr $ra

################################################################
GENERATE_PEBBLE:
	lw $t2, 0($sp) # load pebble pixel value offset
	addi $sp, $sp, 4
	lw $t3, 0($sp) # load pebble truth value (pebble collected)
	addi $sp, $sp, 4 
	beq $t3, 0, no_random_pebble
		
pebble_randomize:
# Store ra value into stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $sp, $sp, -4 # store pixel value into stack
	sw $t2, ($sp)
	jal DELETE_PEBBLE
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	li $v0, 42
	li $a0, 0
	li $a1, 56
	syscall
	
	addi $t5, $a0, 32
	li $t8, 1024
	mult, $t5, $t8
	mflo $t5
	
	li $v0, 42
	li $a0, 0
	li $a1, 80
	syscall
	
	li $t8, 4
	addi $t2, $a0, 32
	mult $t2, $t8
	mflo $t2
	add $t2, $t2, $t5
	addi $t2, $t2, BASE_ADDRESS

no_random_pebble:
	addi $t7, $t2, 0 # Store beginning pixel of pebble whether randomized or not
	li $t6, 0
	li $t4, 0
pebble1_loop:	

	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, pebble1_loop
	
	addi $t2, $t2, 1004
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	
	li $t5, 0x888888
	li $t4, 0
pebble2_loop:
	sw $t5, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, pebble2_loop
	
	sw $t6, 0($t2)
	
	addi $t2, $t2, 1004
	li $t4, 0
pebble3_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 24, pebble3_loop
	
	# output pixel value back to memory
pebble_end:
	la $t4, pebble_pixel
	sw $t7, 0($t4)
		
	la $t4, pebble_collected
	li $t7, 0
	sw $t7, 0($t4)
	
	jr $ra

################################################################
DELETE_PEBBLE:

	lw $t2, 0($sp)
	addi $sp, $sp, 4

	li $t6, 0x4dabf7
	li $t4, 0
delete_pebble1_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, delete_pebble1_loop
	
	addi $t2, $t2, 1004
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	
	li $t4, 0
delete_pebble2_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 16, delete_pebble2_loop
	
	sw $t6, ($t2)
	addi $t2, $t2, 1004
	li $t4, 0
delete_pebble3_loop:
	sw $t6, 0($t2)
	addi $t2, $t2, 4
	addi $t4, $t4, 4
	bne $t4, 24, delete_pebble3_loop
	
	# output pixel value back to memory
delete_pebble_end:
	jr $ra
	
#################################################################
PEBBLE_COLLECTED:
	
	# Can reuse with enemy pebbles
	lw $t2, ($sp) # load rock pixel value
	addi $sp, $sp, 4
	lw $t3, ($sp) # load pebble pixel value
	addi $sp, $sp, 4
	
	bge $t3, $t2, first_row
	addi $t5, $t3, 16
	bge $t3, $t2, first_row
	j not_equal
first_row:
	addi $t2, $t2, 28
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	addi $t2, $t2, 992
	bge $t3, $t2, second_row
	j not_equal
second_row:
	addi $t2, $t2, 20
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	addi $t2, $t2, 988
	bge $t3, $t2, third_row
	j not_equal
third_row:
	addi $t2, $t2, 32
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	addi $t2, $t2, 980
	bge $t3, $t2, fourth_row
	j not_equal
fourth_row:
	addi $t2, $t2, 40
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	addi $t2, $t2, 980
	bge $t3, $t2, fifth_row
	j not_equal
fifth_row:
	addi $t2, $t2, 36
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	addi $t2, $t2, 984
	bge $t3, $t2, sixth_row
	j not_equal
sixth_row:
	addi $t2, $t2, 32
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	addi $t2, $t2, 992
	bge $t3, $t2, seventh_row
	j not_equal
seventh_row:
	addi $t2, $t2, 28
	ble $t3, $t2, equal
	addi $t5, $t3, 16
	ble $t5, $t2, equal
	
	j not_equal
equal:
	la $t8, pebble_collected # Set pebble collected boolean value to 1
	li $t7, 1
	sw $t7, 0($t8)
	
	la $t7, score
	lw $t8, 0($t7)
	addi $t8, $t8, 1
	sw $t8, 0($t7)
not_equal:
	jr $ra
#################################################################
# Checks if the avatar can move
CAN_MOVE:
	lw $t4, 0($sp) # Load $t4 with current pixel
	lw $t5, 4($sp) # Load #t5 with current move
	addi $sp, $sp, 8
	li $t6, 1024 # $t6 holds pixel divisor

	# Parse move (move paramter is stored at $t4)
	beq $t5, 0x61, check_left
	beq $t5, 0x64, check_right
	beq $t5, 0x73, check_ocean
	beq $t5, GRAVITY_TRUE, check_ocean
	beq $t5, 0x77, check_up
	
check_left:
	addi $t4, $t4, 3056
	li $t5, 1024
	div $t4, $t5
	mfhi $t5
	beq $t5, 0, no_move
	li $t9, -1
	j return_can_move
check_right:
	addi $t4, $t4, 2092
	addi $t6, $t4, -1020
	li $t5, 1024
	div $t6, $t5
	mfhi $t5
	beq $t5, 0, no_move
	li $t9, -1
	j return_can_move
check_up:
	addi $t4, $t4, -1020
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 1020
	ble $t4, $t5, no_move
	lw $t5, 0($t4)
	beq $t5, 0x8e8e8e, no_move
	
	li $t9, -1
	j return_can_move
check_ocean:
	# Check if current pixel touched the water (108544 <= $t4 <= 109564)
	addi $t4, $t4, 7168
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 108544
	bge $t4, $t5, END
	li $t9, -1
check_platform:
	addi $t6 $t4, 0
	addi $t6, $t6, -4
	lw $t5, 0($t6)
	beq $t5, 0x8e8e8e, no_move # Checks if bottom of rock hits a platform
	addi $t6, $t6, 24
	lw $t5, 0($t6)
	beq $t5, 0x8e8e8e, no_move
	# Not on a platform
	li $t9, NO_JUMP # also determines whether on platform or not
	j return_can_move

# No move can be made, so $t9 is set to 0
no_move:
	li $t9, 0
	addi $sp, $sp, -4
	sw $t9, 0($sp)
	j end_can_move
return_can_move:
	addi $sp, $sp, -4
	sw $t9, 0($sp)
end_can_move:
	jr $ra
	
	
############################################################
# DEALS WITH PLATFORM LEVELS
LEVEL_1:
	addi $sp, $sp, -4 # STORE LAST FUNC CALL ADDRESS
	sw $ra, 0($sp)

	li $t2, 73152
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM
	
	li $t2, 51392
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM
	
	li $t2, 90816
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	jr $ra
##########################################################################
	
GENERATE_BACKGROUND:
	li $t0, BASE_ADDRESS
# initialize outer_loop counter
	li $t4, 0	
outer_loop:
# initialize inner_loop counter
	li $t5, 0
inner_loop:
	# Check curent pixel and paint sky or sea depending on whether pixel is greater than 315
	bgt $t4, 420, sea
sky:	
	li, $t1, 0x4dabf7
	sw $t1, 0($t0)
	j increment
	
sea:	
	li $v0, 42
	li $a0, 0
	li $a1, 10
	syscall
	blt $a0, 4, dark_blue
	blt $a0, 7, medium_blue
light_blue:
	li $t2, 0x052fab
	j paint_sea
medium_blue:
	li $t2, 0x173eb0
	j paint_sea
dark_blue:
	li $t2, 0x001a66
paint_sea:	
	sw $t2, 0($t0)
	
# increment loop counters
increment:
	addi $t0, $t0, 4
	addi $t5, $t5, 4
	blt $t5, 1024, inner_loop
	
	addi $t4, $t4, 4
	blt $t4, 512, outer_loop
	
	jr $ra


######################################################
# Display the current score
DISPLAY_SCORE:

	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	
	la $t3, score
	lw $t3, 0($t3)
	beq $t3, 0, zero
	beq $t3, 1, one
	beq $t3, 2, two
	beq $t3, 3, three
	beq $t3, 4, four
	beq $t3, 5, five
	beq $t3, 6, six
	beq $t3, 7, seven
	beq $t3, 8, eight
	beq $t3, 9, nine
	beq $t3, 10, ten
	j score_end
	
##########################################
# Display 0
zero:
	li $t6, 0
	addi $t4, $t4, 4104
zero_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, zero_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	li $t6, 0	
zero_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, zero_loop2

	j score_end

######################################
# Display 1
one:
	li $t4, BASE_ADDRESS
	li $t6, 0
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
delete_zero_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_zero_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	li $t6, 0	
delete_zero_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_zero_loop2
	
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4120
	li $t6, 0
one_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	addi $t6, $t6, 4
	bne $t6, 20, one_loop1

	j score_end
	
#########################################
# Display 2
two:
	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4120
	li $t6, 0
delete_one_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	addi $t6, $t6, 4
	bne $t6, 20, delete_one_loop1
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
two_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, two_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	
	li $t6, 0
two_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, two_loop2
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1024
	li $t6, 0
two_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, two_loop3

	j score_end
three:

	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_two_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_two_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	
	li $t6, 0
delete_two_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_two_loop2
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1024
	li $t6, 0
delete_two_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_two_loop3
	
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
three_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, three_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	li $t6, 0
three_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, three_loop2
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	li $t6, 0
three_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, three_loop3
	
	
	j score_end
four:

	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_three_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_three_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	li $t6, 0
delete_three_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_three_loop2
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	
	addi $t4, $t4, 1012
	li $t6, 0
delete_three_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_three_loop3
	
	

	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	
	li $t6, 0
four_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, four_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)

	j score_end

#################################
# Display 5
five:
	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	
	li $t6, 0
delete_four_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_four_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)
	
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
five_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, five_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	li $t6, 0
five_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, five_loop2
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
five_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, five_loop3

	j score_end
###################################
# Display 6
six:

	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_five_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_five_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	li $t6, 0
delete_five_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_five_loop2
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
delete_five_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_five_loop3
	
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
six_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, six_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	li $t6, 0
six_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, six_loop2
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
six_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, six_loop3

	j score_end

########################################
# Display 7
seven:
	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_six_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_six_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	li $t6, 0
delete_six_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_six_loop2
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
delete_six_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_six_loop3
	

	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
seven_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, seven_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)

	j score_end
################################
# Display 8
eight:

	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_seven_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_seven_loop1
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)
	addi $t4, $t4, 1024
	sw $t5, 0($t4)
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
eight_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, eight_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
eight_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, eight_loop2
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012

	li $t6, 0
eight_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, eight_loop3
	

	j score_end
########################
# Display 9
nine:

	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_eight_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_eight_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
delete_eight_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_eight_loop2
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012

	li $t6, 0
delete_eight_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_eight_loop3
	
	
	li $t4, BASE_ADDRESS
	li $t5, 0x000000
	addi $t4, $t4, 4104
	li $t6, 0
nine_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, nine_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
nine_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, nine_loop2
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1012

	li $t6, 0
nine_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, nine_loop3

	j score_end

ten:
	li $t4, BASE_ADDRESS
	li $t5, 0x4dabf7
	addi $t4, $t4, 4104
	li $t6, 0
delete_nine_loop1:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_nine_loop1
	
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi $t4, $t4, 1012
	li $t6, 0
delete_nine_loop2:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_nine_loop2
	
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1012

	li $t6, 0
delete_nine_loop3:
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	addi $t6, $t6, 4
	bne $t6, 16, delete_nine_loop3
	
	
# DISPLAY A CHECKMARK IF AT 10 BECAUSE ITS EASIER

	li $t4, BASE_ADDRESS
	li $t5, 0x00ff40
	addi $t4, $t4, 4128
	sw $t5, 0($t4)
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1020
	sw $t5, 0($t4)
	addi $t4, $t4, 1008
	sw $t5, 0($t4)
	addi $t4, $t4, 12
	sw $t5, 0($t4)
	addi, $t4, $t4, 1016
	sw $t5, 0($t4)
	addi $t4, $t4, 4
	sw $t5, 0($t4)
	
	j score_end

score_end:
	jr $ra
	
#####################################################################
# Display health
DISPLAY_HEALTH:

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t5, health
	lw $t5, ($t5)
	beq $t5, 3, three_heart
	beq $t5, 2, two_heart
	beq $t5, 1, one_heart
	beq $t5, 0, no_heart
	j finish_heart
	
no_heart:
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4136
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4168
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4200
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_HEART
	
	j finish_heart

one_heart:
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4136
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal GENERATE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4168
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4200
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_HEART
	
	j finish_heart


two_heart:
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4136
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal GENERATE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4168
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal GENERATE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4200
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_HEART
	
	j finish_heart


three_heart:
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4136
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal GENERATE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4168
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal GENERATE_HEART
	
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 4200
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal GENERATE_HEART
	
	
finish_heart:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	jr $ra

#####################################################################

GENERATE_HEART:
	lw $t3, 0($sp) # Load pixel value to store at
	addi $sp, $sp, 4
	
	li $t5, 0
	li $t6, 0xca0000
	
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 8
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 1004
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	
	addi $t3, $t3, 1000
	sw $t5, 0($t3)
	addi $t3, $t3, 4

	li $t7, 0
heart_loop1:
	sw $t6, 0($t3)
	addi $t7, $t7, 4
	addi $t3, $t3, 4
	bne $t7, 20, heart_loop1
	sw $t5, 0($t3)
	
	addi $t3, $t3, 1004
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	
	addi $t3, $t3, 1012
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 1020
	sw $t5, 0($t3)
	
	jr $ra
	
	
####################################################################
DELETE_HEART:
	lw $t3, 0($sp) # Load pixel value to store at
	addi $sp, $sp, 4
	
	li $t5, 0x4dabf7
	li $t6, 0x4dabf7
	
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 8
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 1004
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	
	addi $t3, $t3, 1000
	sw $t5, 0($t3)
	addi $t3, $t3, 4

	li $t7, 0
delete_heart_loop:
	sw $t6, 0($t3)
	addi $t7, $t7, 4
	addi $t3, $t3, 4
	bne $t7, 20, delete_heart_loop
	sw $t5, 0($t3)
	
	addi $t3, $t3, 1004
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	
	addi $t3, $t3, 1012
	sw $t5, 0($t3)
	addi $t3, $t3, 4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	sw $t5, 0($t3)
	addi $t3, $t3, 1020
	sw $t5, 0($t3)
	
	jr $ra
	

#############################################################

DISPLAY_DAMAGED:
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	
	
	
	
	
	
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra