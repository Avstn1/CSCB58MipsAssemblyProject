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

bitmap_address: .space 1048576 # spacer to avoid overflow into data array

	


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



newline:	.asciiz "\n"
you_lose_yes: .asciiz "youloseyes.txt"
you_lose_no: .asciiz "youloseno.txt"
you_lose_start:
	.space 20



##########################################################################
# MAIN
.text
	li $sp, 0
main:	
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
	jal RANDOM_NUMBER
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
	
	
##########################################################################
# GAME START
RESTART:
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal DELETE_ROCK
	
# GAME LOOP START
	# dedicate $t0 to the beginning pixel character value
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 66032
	
	addi $sp, $sp, -4 # Load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

#########################################################################
# Grey
# Pixel Register: $t0
# Direction Register: $t2
# Start platform counter
	li $t1, 0
	li $t2, 32764
	addi $sp, $sp, -4 # Store intial old pixel iteration into stack
	sw $t2, ($sp)
##########################################################################
# KEEP $T0 AND $T1 FOR MAIN


# ESSENTIALLY THE MAIN LOOP LABEL ########################################
gravity_loop:


#### STARTING PLATFORM #######
	li $t2, 73160
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM

	beq $t1, 255, reset_iteration
	j no_reset
reset_iteration:
	li $t1, 0
	lw $t2, ($sp)
	addi $sp, $sp, -4
	sw $t2, ($sp)
	jal DELETE_TEST_PLATFORM
	addi $sp, $sp, 4

no_reset:
	lw $t2, ($sp)
	addi $sp, $sp, 4
	
	addi $sp, $sp, -4 # Load pixel value first
	sw $t2, ($sp)
	addi $sp, $sp, -4 # Load increment
	sw $t1, ($sp)
	jal PLATFORM_MOVEMENT
	
	addi $t1, $t1, 1 # increment counter

	beq $s3, 999999, back_from_top
	beq $s3, 999998, move_check_from_top
	

# check if on platform
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
	li $a0, GRAVITY_WAIT # Wait 15 milliseconds
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
	li $s3, 999998
	j gravity_loop
move_check_from_top:
	li $v0, 32
	li $a0, PLATFORM_WAIT # Wait 30 milliseconds
	syscall
	
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
	beq $t2, 0x70, END
	j gravity_loop
	
keypress_happened_platform:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, respond_to_a_gravity # ASCII code of 'a' is 0x61
	beq $t2, 0x64, respond_to_d_gravity # ASCII code of 'd' is 0x64 
	beq $t2, 0x77, respond_to_w_gravity # ASCII code of 'w' is 0x77 
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
	addi $t0, $t0, -16
	
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
	addi $t0, $t0, 16
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

	j gravity_loop

respond_to_w_gravity:
	j respond_to_w
	
############################################
# TO RESPOND TO W CLICK AND JUMP
##########################################
respond_to_w:
	li $s6, 0
jump_loop:
	li $s3, 999999 # Information register about jumping back to jump_loop
	j gravity_loop
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
	beq $t2, 0x73, gravity_loop # jump cancel
	#beq $t2, 0x77, respond_to_w_jumping # ASCII code of 'w' is 0x77
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
	addi $t0, $t0, -16
	
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
	addi $t0, $t0, 16
	
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	jal DELETE_ROCK
	
	addi $sp, $sp, -4 # load new pixel value
	sw $t0, 0($sp)
	jal GENERATE_ROCK

	j jump_sleep

respond_to_w_jumping:
	# fill in 
	j jump_sleep
	

##########################################################			
END:


	la $t1, you_lose_yes
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE	

reset_menu:
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_reset_menu
	j reset_menu
keypress_reset_menu:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, load_yes # ASCII code of 'a' is 0x61
	beq $t2, 0x64, load_no
	j reset_menu

load_yes:
	la $t1, you_lose_yes
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE	
	j reset_menu
load_no:
	la $t1, you_lose_no
	addi $sp $sp, -4
	sw $t1, 0($sp)
	li $t1, 0
	addi $sp, $sp, -4
	sw $t1, 0($sp)	
	jal LOAD_PICTURE
	j reset_menu



terminate:
	li $v0, 10 # terminate the program gracefully
	syscall
##########################################################
# NECESSARY FUNCTIONS

RANDOM_NUMBER:
	#deals with background ocean randomize
	li $v0, 42
	li $a0, 0
	li $a1, 10
	syscall
	jr $ra
	
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
	
TEST_PLATFORM:
	lw $t6, 0($sp)
	addi $sp, $sp, 4
	addi $t2, $t6, 0
	addi $t6, $t6, BASE_ADDRESS
	

	# Calculate original row
	li $t8, 1024
	li $t9, 4
	mult $t8, $t9
	mflo $t8
	div $t6, $t8
	mflo $t3
	
	li $t7, 0x8e8e8e
	li $t4, 0
	li $t5, 0
	addi $t5, $t4, 120
test_loop:
	##################################
	# Calculate new row (if on new row)
	li $t8, 1024
	li $t9, 4
	mult $t8, $t9
	mflo $t8
	div $t6, $t8
	mflo $t8
	##################################

	blt $t8, $t3, skip_test
	bgt $t8, $t3, skip_test

	sw $t7, 0($t6)
skip_test:
	addi $t6, $t6, 4
	addi $t4, $t4, 4

	bne $t4, $t5, test_loop

	
	addi $sp, $sp, -4
	sw $t2, ($sp)
	
	jr $ra
	
	
DELETE_TEST_PLATFORM:
	lw $t6, 0($sp)
	addi $sp, $sp, 4
	
	addi $t2, $t6, 0 # Store old pixel value and re-output it
	addi $sp, $sp, -4
	sw $t2, ($sp)
	
	addi $t6, $t6, BASE_ADDRESS
	
	# Calculate original row
	li $t8, 1024
	li $t9, 4
	mult $t8, $t9
	mflo $t8
	div $t6, $t8
	mflo $t3
	
	li $t7, 0x4dabf7
	li $t4, 0
	li $t5, 0
	addi $t5, $t4, 120
test_delete_loop:
	##################################
	# Calculate new row (if on new row)
	li $t8, 1024
	li $t9, 4
	mult $t8, $t9
	mflo $t8
	div $t6, $t8
	mflo $t8
	##################################

	blt $t8, $t3, skip_delete_test
	bgt $t8, $t3, skip_delete_test

	sw $t7, 0($t6)
skip_delete_test:
	addi $t6, $t6, 4
	addi $t4, $t4, 4
	bne $t4, $t5, test_delete_loop
	
	jr $ra
	

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
	lw $t0, 4($sp)  # address of image filename
	addi $sp, $sp, 8
	li $t1, BASE_ADDRESS

	# Open the input file for reading
	li $v0, 13         # System call code for open
	la $a0, ($t0)      # Load the filename address into $a0
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
	li $a2, 10            # Maximum number of bytes to read
	syscall
	
	# Convert the ASCII string to a decimal valuet
	la $t6, you_lose_start        # Load the address of the string into $t6
	addi $t6, $t6, 2      # Skip over the "0x" prefix
	li $t7, 0             # Initialize decimal value to zero
loop:
	lbu $t8, ($t6) # Load current byte into $t8
	beqz $t8, end_loop # Exit loop if current byte is null terminator
	andi $t9, $t8, 0xFF # Convert signed byte to unsigned byte value
	sub $t9, $t9, 48 # Convert ASCII code for '0' to decimal value
	bge $t9, 17, sub_a # If character is a-f, subtract 17 to convert to decimal
	bge $t9, 10, sub_A # If character is A-F, subtract 10 to convert to decimal
	li $t3, 16
	mult $t7, $t3 # Multiply current value by 16 (since we're reading in hex)
	mflo $t7
	add $t7, $t7, $t9 # Add decimal value of current character
	addi $t6, $t6, 1 # Move to next byte in string
	j loop
sub_a:
	sub $t9, $t9, 39 # Subtract 39 to convert a-f to decimal
	j common
sub_A:
	sub $t9, $t9, 7 # Subtract 7 to convert A-F to decimal
common:
	li $t3, 16
	mult $t7, $t3
	mflo $t7 # Multiply current value by 16 (since we're reading in hex)
	add $t7, $t7, $t9 # Add decimal value of current character
	addi $t6, $t6, 1 # Move to next byte in string
	j loop
end_loop:

	#li $v0, 1
	#addi $a0, $t7, 0
	#syscall
	#j terminate

	beq $t7, 0x767676, skip_draw
	sw $t7, ($t1)
skip_draw:
	addi $t1, $t1, 4
	addi $t4, $t4, 4
	bne $t4, 131072 , picture_loop

	# Close the file
	li $v0, 16            # System call code for close
	move $a0, $t5         # Load the file descriptor into $a0
	syscall

	jr $ra


################################################################
GENERATE_ENEMY:







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
	lw $t5, ($t4)
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
	lw $t5, ($t6)
	beq $t5, 0x8e8e8e, no_move # Checks if bottom of rock hits a platform
	addi $t6, $t6, 24
	lw $t5, ($t6)
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
	

######################################################`
PLATFORM_MOVEMENT:

	# REQUIREMENTS AND GIVENS
	#	- Must use stack to keep track of randomized pixel value + offsets
	#	- Must create a random integer from 1 to 90 (perhaps) to generate platforms on
	#	- Must shift platforms to the beginning of the row (from right to left)
	#	- Must create a new platform to start shifting after a couple iterations of shifting (perhaps 128 iterations of -4 shifting (OR 64 iterations of -8 shifting)

	# For reusability, load paramter to decide which image to display: 1 for platforms, 2 for enemies, platforms move at -12 but enemies move quicker at -24
	
	# Only paramters required is iteration number ( 85, -12 iterations ) and old pixel value (for first iteration)
	lw $t2, ($sp) # Load iteration
	addi $sp, $sp, 4
	
	lw $t3, ($sp) # Load into $t3 from stack (SECOND PARAMETER)
	addi $sp, $sp, 4

	
	# 0. First check if pixel is at its first iteration, if it is go to step 1, otherwise skip randomize step and load old pixel value
    	
	bge $t2, 1, old_pixel
	
	# 1. Initialize new randomized pixel
randomize:

	li $v0, 42
	li $a0, 0
	li $a1, 70
	syscall
	
	addi $t3, $a0, 20
	li $t4, 1024
	mult $t3, $t4
	mflo $t3
	addi $t3, $t3, -4
	
	
	# 2.Use old pixel input
old_pixel:
	# Store old $ra value
	addi $sp, $sp, -4 # STORE LAST FUNC CALL ADDRESS
	sw $ra, 0($sp)
	
	# 3. Shift randomized pixel (or platform) to the left by -12 and delete old platform
	
	addi $sp, $sp, -4
	sw $t3, ($sp)
	jal DELETE_TEST_PLATFORM
	
	lw $t3, ($sp)
	addi $sp, $sp, 4
	
	addi $t3, $t3, -4
	# 4. Generate new platform
	addi $sp, $sp, -4
	sw $t3, ($sp)
	jal TEST_PLATFORM

	lw $t3, ($sp)
	addi $sp, $sp, 4

	# Load old $ra value
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	# Load $t1 into stack
	addi $sp, $sp, -4 
	sw $t3, ($sp)
	
	jr $ra
	
######################################################
# DEALS WITH PLATFORMS
LEVEL_1:

	addi $sp, $sp, -4 # STORE LAST FUNC CALL ADDRESS
	sw $ra, 0($sp)

	li $t2, 83392
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM
	
	li $t2, 45520
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM

	li $t2, 61632
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM
	
	li $t2, 62144
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal GENERATE_PLATFORM


	lw $ra, 0($sp)
	addi $sp, $sp, 4

	jr $ra
##########################################################################
	
	

