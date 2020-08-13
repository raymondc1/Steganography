.data

prompt:             .asciiz "This program encodes a message to a BMP file, or decodes the BMP file to get the message\n"
EncodeChoice:       .asciiz "1. Press 1 to Encode a message\n"
DecodeChoice:       .asciiz "2. Press 2 to Decode a message\n"
chooseDecode:       .asciiz "You chose to decode\n"
chooseEncode:       .asciiz "You chose to encode\n"
wrongInput:         .asciiz "\nInvalid Input Please Enter 1 or 2\n"
keyEncodePrompt:    .asciiz "Enter key to encode: "
keyDecodePrompt:    .asciiz "Enter key to decode: "
inputMessagePrompt: .asciiz "Enter the message to encode: "

ifile:	  .asciiz "input.bmp"
ofile:	  .asciiz "output.bmp"
message:  .space 24576
BMPimage: .space 196662

.text

main:
	li $v0, 4
	la $a0, prompt
	syscall
	
UserInput:
	li $v0, 4
	la $a0, EncodeChoice
	syscall
	
	li $v0, 4
	la $a0, DecodeChoice
	syscall
	
	li $v0, 5
	syscall
	move $s2, $v0	#s2 stores user input choice
	
	beq $s2, 1, Encode
	beq $s2, 2, Decode
	
	li $v0, 4
	la $a0, wrongInput
	syscall
	
	j UserInput
	
Exit:
	li $v0, 10
	syscall
	
Encode:
	li $v0, 4
	la $a0, chooseEncode
	syscall
	
	li $v0, 4
	la $a0, keyEncodePrompt
	syscall
	
	li $v0, 5
	syscall
	move $s3, $v0	# key stored in s3
	
	li $v0, 4
	la $a0, inputMessagePrompt
	syscall
	
	li $v0, 8
	la $a0, message
	li $a1, 24576
	syscall
	
#########################################################################################
#                              open file for reading                                    #
#########################################################################################

	li	$v0, 13		# 13 to open file
	la	$a0, ifile	# load input file to $a0, this file should never change
	li	$a1, 0		# $a1 is flag, 0 for read, 1 for write
	li	$a2, 0		# $a2 is mode, leave alone?
	syscall			# return file descriptor in $v0
	move 	$s7, $v0	# save file descriptor in $s7

	li	$v0, 14		# 14 to read file
	move	$a0, $s7	# $a0 takes in file descriptor
	la	$a1, BMPimage	# $a1 takes in where to save read value
	li	$a2, 196662	# $a2 takes in the size to read
	syscall			# returns size in $v0

	li	$v0, 16		# 16 to close file
	move	$a0, $s7	# closes file that is in $a0
	syscall			# close file

#########################################################################################
#                             encode message to BMPimage                                #
#########################################################################################

	la	$s0, BMPimage	# loads the input.bmp that was saved to space to pointer $s0
	la	$s1, message	# load string to pointer $s1
	addi	$s0, $s0, 54	# add 54 to pointer $s0 so it doesn't point to the bmp header part
	
	li	$t2, 54		# counter for file size
	li	$t3, 0		# counter for character bits
	lb	$t1, 0($s1)	# loads first byte of message (MMMMMMMM)

Encode_Loop:
	lb	$t0, 0($s0)	# loads byte of pixel (PPPPPPPP)
	and	$t9, $t1, 128	# saves the MSB of the message to $t9 (M0000000)
	srl	$t9, $t9, 7	# swift $t9 so the MSB from message shows as 0000000M
	and	$t0, $t0, 254	# change the pixel bit so it's ready to add the MSB of message to it (PPPPPPP0)
	or	$t0, $t0, $t9	# add those two values together and we get PPPPPPPM
	
	sb	$t0, 0($s0)	# saves PPPPPPPPM to the pointer $s0 location
	add	$s0, $s0, $s3	# increment pointer so it points to next k byte of the image
	add	$t2, $t2, $s3	# increment $t2 to keep track of file size
	
	sll	$t1, $t1, 1	# swifts message so it gets the next MSB (MMMMMMM0)
	addi	$t3, $t3, 1	# increment bit counter for message
		
	beq	$t2, 196662, End_E	# if reach the end of BMP file size, exit loop
	beq	$t3, 8, nextChar	# if all bits of the current meesage byte is stored, get next byte of message
	
	j	Encode_Loop		# jumps back to loop
	
	nextChar:
		beq $t1, '\0', End_E	# if value just finished added to BMP is NULL terminator, exit loop
		li $t3, 0		# sets bit counter back to 0
		addi $s1, $s1, 1	# increment pointer to point to next character from string
		lb $t1, 0($s1)		# load the pointer $s1 value to $t1
		
		j Encode_Loop		# jumps back to loop to store bits into BMP image
		
End_E:
	
#########################################################################################
#                           make output file for writing                                #
#########################################################################################

	li	$v0, 13		# 13 to open a file
	la	$a0, ofile	# load output file, will make new one if file isn't in folder
	li	$a1, 1		# $a1 is flag for read or write, 0 for read, 1 for write
	li	$a2, 0		# $a2 is mode, leave alone?
	syscall			# return file descriptor in $v0
	move	$s7, $v0	# save file descriptor to $s7

	li	$v0, 15		# 15 to write to file
	move	$a0, $s7	# $a0 takes in file descriptor
	la	$a1, BMPimage	# $a1 takes in what value to write
	li	$a2, 196662	# $a2 takes in the size to write
	syscall			# returns size in $v0
	
	li	$v0, 16		# 16 to close file
	move	$a0, $s7	# closes file that is in $a0	
	syscall			# close file
	
	j Exit
	
Decode:
	li $v0, 4
	la $a0, chooseDecode
	syscall
	
	li $v0, 4
	la $a0, keyDecodePrompt
	syscall
	
	li, $v0, 5
	syscall
	move $s3, $v0	# key stored in s3
	
#########################################################################################
#                         Opening our output file for reading                           #
#########################################################################################

	li	$v0, 13	 	# 13 lets us open files
	la	$a0, ofile	# Here we read in our output image 
	li	$a1, 0		# We put 0 in $a1 to tell it we are 'reading'
	li	$a2, 0		# Set the mode to 0
	syscall 
	move 	$s7, $v0	# Saving our file descriptor 
	
	li	$v0, 14		# 14 let's us read a file
	move	$a0, $s7	# We store our file descriptor in $a0
	la	$a1, BMPimage	# We put the location where we want to store it, in $a1
	li	$a2, 196662	# We store the size in which we will read
	syscall			# returns the size in $v0
	    
	li	$v0, 16		# 16 let's us close the file
	move	$a0, $s7	# specify which file we are closing with the file description
	syscall			# close the file

#########################################################################################
#                    Decode our output image back into the message                      #
#########################################################################################

	la $s0, BMPimage	# loads the output.bmp that was saved to space to pointer $s0
	la $s1, message
	addi $s0, $s0, 54	# add 54 to pointer so we skip the header portion of the image
	
	li $t2, 54		# counter for file size
	li $t3, 0		# counter for character bits
	
	lb $t1, 0($s1)		# load in our string
	andi $t1, $t1, 0
	
	loopDecode:
		lb $t0, 0($s0)     # Here we load in a byte from the image in $t0
		andi $t0 , $t0, 1  # If the byte is nonn-zero then we store a 1 in $t0
		sll $t0, $t0, 7    # Here we shift left 7 times in our byte
		or $t1, $t1, $t0   # if the value in $t0 or $t1 is 1 then we store a 1 in $t1
		add $s0, $s0, $s3  # Here we increment our pointer
		add $t2, $t2, $s3  # increase counter for file size
		
		lb $t0, 0($s0)     # Same thing from here on, just decrementing by how much we are shifting  
		andi $t0 , $t0, 1  # so that we check every single bit
		sll $t0, $t0, 6    
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		lb $t0, 0($s0)     # Shifting by 5
		andi $t0 , $t0, 1  
		sll $t0, $t0, 5    
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		lb $t0, 0($s0)     # Shifting by 4
		andi $t0 , $t0, 1  
		sll $t0, $t0, 4    
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		lb $t0, 0($s0)     # Shifting by 3
		andi $t0 , $t0, 1  
		sll $t0, $t0, 3    
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		lb $t0, 0($s0)     # Shifting by 2
		andi $t0 , $t0, 1  
		sll $t0, $t0, 2    
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		lb $t0, 0($s0)    # Shifting by 1 
		andi $t0 , $t0, 1  
		sll $t0, $t0, 1    
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		lb $t0, 0($s0)    # No shift! 
		andi $t0 , $t0, 1   
		or $t1, $t1, $t0   
		add $s0, $s0, $s3
		add $t2, $t2, $s3
		
		addi $t3, $t3, 8
		
		beq $t2, 196662, exitDecode  # Once we reach the end of the image, we're done
		beq $t3, 8, saveChar	     # Once have a char to save
		
		j loopDecode #jump back to the beginning of our loop
		
		saveChar:	# Here we save a char we got to our output string
			sb $t1, 0($s1)	#We save the byte
			beq $t1, '\0', exitDecode #If we hit the null char then we know the string is over
			li $t3, 0 # here we reset our counter
			addi $s1, $s1, 1 #increment our pointer
			lb $t1, 0($s1) #load in another byte
			andi $t1, $t1, 0  
			j loopDecode	# here we restart the loop
			
		exitDecode: #here we are going to print our output statement and then exit
		li $v0, 4	# load 4 to print a string
		la $a0, message # load in our output string
		syscall #print out the string
		
	j Exit
