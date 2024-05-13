.section .data
# these  strings will be used to print machine codes
addi_x2: .string " 00000 000 00010 0010011\n"
addi_x1: .string " 00000 000 00001 0010011\n"
const_add: .string "0000000 00010 00001 000 00001 0110011\n"
const_mul: .string "0000001 00010 00001 000 00001 0110011\n"
const_sub: .string "0100000 00010 00001 000 00001 0110011\n"
const_xor: .string "0000100 00010 00001 000 00001 0110011\n"
const_and: .string "0000111 00010 00001 000 00001 0110011\n"
const_or: .string "0000110 00010 00001 000 00001 0110011\n"

.section .bss
input_buffer: .space 256
printing_bit: .space 256  # print the number in binary for machine code

.section .text
.global  _start

_start:
        mov $0,  %eax                   # system call number for sys_read(0)
        mov $0,  %edi                   # file descriptor for standard input(0)
        lea input_buffer(%rip), %rsi    #load effective address of input_bufer into   rsi
        mov $256, %edx
        syscall

        mov %eax, %edx  #move the number of bytes read  into %edx
        lea input_buffer(%rip), %rsi #pointer to input_buffer
        
        xor %r8, %r8    #to be sure it is zero
        xor %r9, %r9    #to be sure it is zero
        xor %rcx, %rcx  #to be sure it is zero
        xor %rbx,%rbx   #to be sure it is zero
        jmp parsing_loop


parsing_loop:               # we need to do stack operations in loop
    xor %r8,%r8
    movb (%rsi),  %r8b      # load a byte from input_buffer 
    inc %rsi                # increment rsi to point next character
    cmp $' ', %r8b          # if it is space jump to push value to stack
    je push_value
    
    jmp operator_checking   # find whether it is an operator or not
continue_parsing:    
    cmp $'\n',%r8b          
    je exit_program

    #if it is an integer
    subb $'0', %r8b          # make its value the integer one .
    imulw $10, %r9w          # put it in r9 with multiplying 10 to keep track of number
    addw %r8w, %r9w
    xor %r8, %r8
    jmp parsing_loop


push_value:      # push value to stack and reset r8 and r9
        push %r9
        xor %r8,%r8
        xor %r9, %r9
        jmp parsing_loop



operator_checking:
    xor %rbx,%rbx
    xor %rcx, %rcx
    # do the job according to the operator
    cmp $'+', %r8b
    je addition

    cmp $'-', %r8b
    je  subtraction

    cmp $'*', %r8b
    je multiplication

    cmp $'^', %r8b
    je btwxor

    cmp $'&', %r8b
    je btwand

    cmp $'|', %r8b
    je btwor
    
    jmp continue_parsing


################################################

continue_operation:                    # it is for end of the operations part
        xor %rax,%rax                  # it pushes the result of operation to stack
        push %r12
        mov %r14, %rsi
        movb (%rsi), %r8b
        inc %rsi
        cmp $' ',%r8b  
        jne exit_program
        jmp parsing_loop


exit_program:
        mov $60, %eax
        xor %edi, %edi
        syscall


#######################
## addition part:
addition:
        xor %r13,%r13
        xor %rax, %rax
        mov $2, %cl   # to calculate binary number
        pop %rax             # pop first number
        pop %r12            #pop second number
        mov %r12, %r9      # recording second number
        addw %ax, %r12w     # the result is in r12

        mov %rsi,%r14
        movb $12,%r13b

        jmp addi_to_x2_addition

addi_to_x1_addition:
        xor %rcx,%rcx                #printing addi for second number machine code
        mov $2,%cl                   #with finding the binary value of number with dividing 2
        cmp $24, %r13b               #and pushing the remainder to stack until 12 bit
        je printing_addi_addition
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        inc %r13b
        push %rdx
        jmp addi_to_x1_addition

addi_to_x2_addition:          # printing addi  for first number machine code
        xor %rcx,%rcx         # with finding the binary value of number with dividing 2
        mov $2,%cl            # and pushing the remainder to stack until 12 bit
        cmp $0, %r13b
        je printing_addi_addition
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        dec %r13b
        push %rdx
        jmp addi_to_x2_addition

printing_addi_addition:   
        # printing  x2 and x1           # it pops the binary bits one by one from stack
        cmp $12, %r13b                  # and print it to standard output                                                                
        je exit_printing_addi_x2_addition
        cmp $36, %r13b
        je exit_printing_addi_x1_addition
        inc %r13b
        # pop the number from the stack, add '0' and print
        pop %r8
        add $'0',%r8
        mov %r8,printing_bit
        lea printing_bit(%rip),%rsi
        mov $1, %eax
        mov $1,%edx
        mov $1, %edi
        syscall
        jmp printing_addi_addition

exit_printing_addi_x2_addition:   # this part is for printing default part of addi    
        lea addi_x2(%rip), %rsi   # machine code structure
        xor %edx,%edx
        mov $25,%edx
        syscall
        xor %rax,%rax
        mov %r9, %rax
        xor %r9, %r9
        xor %r8, %r8
        jmp  addi_to_x1_addition
exit_printing_addi_x1_addition:  # this part is for printing default part of addi 
        lea addi_x1(%rip), %rsi   # machine code structure
        xor %edx,%edx
        mov $25,%edx
        syscall
        jmp print_const_add        


print_const_add:                    #this part is for printing add structure for machine code
        mov $1, %eax
        mov $1, %edi
        lea const_add(%rip), %rsi
        xor %edx,%edx
        mov $38,%edx
        syscall
        jmp continue_operation

## multiplication part
multiplication:
        xor %r13,%r13
        xor %rax, %rax
        mov $2, %cl   # to calculate binary number
        pop %rax              # pop first number
        pop %r12              #pop second number
        mov %r12, %r9      # recording second number
        imulw %ax, %r12w    # the result is in r12
        mov %rsi,%r14
        movb $12,%r13b
        jmp addi_to_x2_multiplication

addi_to_x1_multiplication:
        xor %rcx,%rcx                #printing addi for first number machine code
        mov $2,%cl                   #with finding the binary value of number with dividing 2
        cmp $24, %r13b               #and pushing the remainder to stack until 12 bit
        je printing_addi_multiplication
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        inc %r13b
        push %rdx
        jmp addi_to_x1_multiplication

addi_to_x2_multiplication:
        xor %rcx,%rcx                    #printing addi  for second number machine code 
        mov $2,%cl                       # with finding the binary value of number with dividing 2
        cmp $0, %r13b                    #and pushing the remainder to stack until 12 bit
        je printing_addi_multiplication
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        dec %r13b
        push %rdx
        jmp addi_to_x2_multiplication

printing_addi_multiplication:   
        # printing  x2 and x1                      # it pops the binary bits one by one from stack
        cmp $12, %r13b                             # and print it to standard output   
        je exit_printing_addi_x2_multiplication
        cmp $36, %r13b
        je exit_printing_addi_x1_multiplication
        inc %r13b
        # pop the number from the stack, add '0' and print
        pop %r8
        add $'0',%r8
        mov %r8,printing_bit
        lea printing_bit(%rip),%rsi
        mov $1, %eax
        mov $1,%edx
        mov $1, %edi
        syscall
        jmp printing_addi_multiplication
exit_printing_addi_x2_multiplication:      # this part is for printing default part of addi  
        lea addi_x2(%rip), %rsi            # machine code structure
        xor %edx,%edx
        mov $25,%edx
        syscall
        xor %rax,%rax
        mov %r9, %rax
        xor %r9, %r9
        xor %r8, %r8
        jmp  addi_to_x1_multiplication
exit_printing_addi_x1_multiplication:  # this part is for printing default part of addi
        lea addi_x1(%rip), %rsi        # machine code structure
        xor %edx,%edx
        xor %edx,%edx
        mov $25,%edx
        syscall
        jmp print_const_mul   
print_const_mul:                 #this part is for printing multiplication structure for machine code
        mov $1, %eax
        mov $1, %edi
        lea const_mul(%rip), %rsi
        xor %edx,%edx
        mov $38,%edx
        syscall
        jmp continue_operation

## or part
btwor:
    xor %r13,%r13
    xor %rax, %rax
    mov $2, %cl   # to calculate binary number
    pop %rax             # pop first number
    pop %r12            #pop second number
    mov %r12, %r9      # recording second number
    orw %ax, %r12w     # the result is in r12


    mov %rsi,%r14
    movb $12,%r13b

    jmp addi_to_x2_or

addi_to_x1_or:
        xor %rcx,%rcx
        mov $2,%cl
        cmp $24, %r13b           #printing addi for first number machine code
        je printing_addi_or      #with finding the binary value of number with dividing 2
        xor %rdx, %rdx           #and pushing the remainder to stack until 12 bit
        div %rcx   # remainder #edx
        inc %r13b
        push %rdx
        jmp addi_to_x1_or

addi_to_x2_or:
        xor %rcx,%rcx              #printing addi  for second number machine code
        mov $2,%cl                 # with finding the binary value of number with dividing 2
        cmp $0, %r13b              #and pushing the remainder to stack until 12 bit
        je printing_addi_or
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        dec %r13b
        push %rdx
        jmp addi_to_x2_or

printing_addi_or:   
        # printing  x2 and x1
        cmp $12, %r13b                           # it pops the binary bits one by one from stack
        je exit_printing_addi_x2_or              # and print it to standard output  
        cmp $36, %r13b
        je exit_printing_addi_x1_or
        inc %r13b
        # pop the number from the stack, add '0' and print
        pop %r8
        add $'0',%r8
        mov %r8,printing_bit
        lea printing_bit(%rip),%rsi
        mov $1, %eax
        mov $1,%edx
        mov $1, %edi
        syscall
        jmp printing_addi_or

exit_printing_addi_x2_or:               # this part is for printing default part of addi  
        lea addi_x2(%rip), %rsi          # machine code structure
        xor %edx,%edx
        mov $25,%edx
        syscall
        xor %rax,%rax
        mov %r9, %rax
        xor %r9, %r9
        xor %r8, %r8
        jmp  addi_to_x1_or
exit_printing_addi_x1_or:              # this part is for printing default part of addi
        lea addi_x1(%rip), %rsi        # machine code structure
        xor %edx,%edx
        mov $25,%edx
        syscall
        jmp print_const_or        


print_const_or:                #this part is for printing or structure for machine code
        mov $1, %eax
        mov $1, %edi
        lea const_or(%rip), %rsi
        xor %edx,%edx
        mov $38,%edx
        syscall
        jmp continue_operation

#### and part

btwand:
        xor %r13,%r13
        xor %rax, %rax
        mov $2, %cl   # to calculate binary number
        pop %rax             # pop first number
        pop %r12            #pop second number
        mov %r12, %r9      # recording second number

        andw %ax, %r12w     # the result is in ebx
        mov %rsi,%r14
        movb $12,%r13b

        jmp addi_to_x2_and


addi_to_x1_and:
        xor %rcx,%rcx
        mov $2,%cl
        cmp $24, %r13b                  #printing addi for second number machine code
        je printing_addi_and             #with finding the binary value of number with dividing 2
        xor %rdx, %rdx                   #and pushing the remainder to stack until 12 bit
        div %rcx   # remainder #edx
        inc %r13b
        push %rdx
        jmp addi_to_x1_and

addi_to_x2_and:
        xor %rcx,%rcx                    # printing addi  for first number machine code
        mov $2,%cl                       # with finding the binary value of number with dividing 2
        cmp $0, %r13b                    # and pushing the remainder to stack until 12 bit
        je printing_addi_and
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        dec %r13b
        push %rdx
        jmp addi_to_x2_and

printing_addi_and:   
        # printing  x2 and x1
        cmp $12, %r13b
        je exit_printing_addi_x2_and                     # it pops the binary bits one by one from stack
        cmp $36, %r13b                                  # and print it to standard output 
        je exit_printing_addi_x1_and
        inc %r13b
        # pop the number from the stack, add '0' and print
        pop %r8
        add $'0',%r8
        mov %r8,printing_bit
        lea printing_bit(%rip),%rsi
        mov $1, %eax
        mov $1,%edx
        mov $1, %edi
        syscall
        jmp printing_addi_and

exit_printing_addi_x2_and:
        lea addi_x2(%rip), %rsi
        xor %edx,%edx                  # this part is for printing default part of addi
        mov $25,%edx                   # machine code structure
        syscall
        xor %rax,%rax
        mov %r9, %rax
        xor %r9, %r9
        xor %r8, %r8
        jmp  addi_to_x1_and
exit_printing_addi_x1_and:              
        lea addi_x1(%rip), %rsi         # this part is for printing default part of addi 
        xor %edx,%edx                   # machine code structure
        mov $25,%edx
        syscall
        jmp print_const_and        


print_const_and:
        mov $1, %eax                    #this part is for printing add structure for machine code
        mov $1, %edi
        lea const_and(%rip), %rsi
        xor %edx,%edx
        mov $38,%edx
        syscall
        jmp continue_operation

## xor part
btwxor:
        xor %r13,%r13
        xor %rax, %rax
        mov $2, %cl   # to calculate binary number
        pop %rax             # pop first number
        pop %r12            #pop second number
        mov %r12, %r9      # recording second number
        xorw %ax, %r12w    # the result is in ebx

        mov %rsi,%r14
        movb $12,%r13b

        jmp addi_to_x2_xor


addi_to_x1_xor:
        xor %rcx,%rcx
        mov $2,%cl
        cmp $24, %r13b                   #printing addi for first number machine code
        je printing_addi_xor             #with finding the binary value of number with dividing 2
        xor %rdx, %rdx                   #and pushing the remainder to stack until 12 bit
        div %rcx   # remainder #edx
        inc %r13b
        push %rdx
        jmp addi_to_x1_xor

addi_to_x2_xor:
        xor %rcx,%rcx
        mov $2,%cl              #printing addi  for second number machine code
        cmp $0, %r13b           # with finding the binary value of number with dividing 2
        je printing_addi_xor    #and pushing the remainder to stack until 12 bit
        xor %rdx, %rdx
        div %rcx   # remainder #edx
        dec %r13b
        push %rdx
        jmp addi_to_x2_xor

printing_addi_xor:   
        # printing  x2 and x1
        cmp $12, %r13b
        je exit_printing_addi_x2_xor            # it pops the binary bits one by one from stack
        cmp $36, %r13b                          # and print it to standard output 
        je exit_printing_addi_x1_xor
        inc %r13b
        # pop the number from the stack, add '0' and print
        pop %r8
        add $'0',%r8
        mov %r8,printing_bit
        lea printing_bit(%rip),%rsi
        mov $1, %eax
        mov $1,%edx
        mov $1, %edi
        syscall
        jmp printing_addi_xor

exit_printing_addi_x2_xor:
        lea addi_x2(%rip), %rsi
        xor %edx,%edx
        mov $25,%edx
        syscall                 # this part is for printing default part of addi  
        xor %rax,%rax           # machine code structure
        mov %r9, %rax
        xor %r9, %r9
        xor %r8, %r8
        jmp  addi_to_x1_xor
exit_printing_addi_x1_xor:
        lea addi_x1(%rip), %rsi
        xor %edx,%edx           # this part is for printing default part of addi
        mov $25,%edx            # machine code structure
        syscall
        jmp print_const_xor        


print_const_xor:
        mov $1, %eax                    #this part is for printing multiplication structure for machine code
        mov $1, %edi
        lea const_xor(%rip), %rsi
        xor %edx,%edx
        mov $38,%edx
        syscall
        jmp continue_operation

# subtraction part
subtraction:
        xor %r13,%r13
        xor %rax, %rax
        mov $2, %cl   # to calculate binary number
        pop %rax             # pop first number
        pop %r12            #pop second number which is : secondnumber - firstnumber
        mov %r12, %r9      # recording second number
        subw %ax, %r12w    # the result is in r9d
        mov %rsi,%r14
        movb $12,%r13b

        jmp addi_to_x2_subtraction
addi_to_x1_subtraction:
        xor %rcx,%rcx
        mov $2,%cl
        cmp $24, %r13b                  #printing addi for first number machine code
        je printing_addi_subtraction    #with finding the binary value of number with dividing 2
        xor %rdx, %rdx                  #and pushing the remainder to stack until 12 bit
        div %rcx   # remainder #edx
        inc %r13b
        push %rdx
        jmp addi_to_x1_subtraction

addi_to_x2_subtraction:
        xor %rcx,%rcx
        mov $2,%cl
        cmp $0, %r13b                   #printing addi  for second number machine code
        je printing_addi_subtraction    # with finding the binary value of number with dividing 2
        xor %rdx, %rdx                   #and pushing the remainder to stack until 12 bit
        div %rcx   # remainder #edx
        dec %r13b
        push %rdx
        jmp addi_to_x2_subtraction

printing_addi_subtraction:   
        # printing  x2 and x1
        cmp $12, %r13b
        je exit_printing_addi_x2_subtraction            # it pops the binary bits one by one from stack
        cmp $36, %r13b                                  # and print it to standard output  
        je exit_printing_addi_x1_subtraction
        inc %r13b
        # pop the number from the stack, add '0' and print
        pop %r8
        add $'0',%r8
        mov %r8,printing_bit
        lea printing_bit(%rip),%rsi
        mov $1, %eax
        mov $1,%edx
        mov $1, %edi
        syscall
        jmp printing_addi_subtraction

exit_printing_addi_x2_subtraction:
        lea addi_x2(%rip), %rsi
        xor %edx,%edx           # this part is for printing default part of addi 
        mov $25,%edx            # machine code structure
        syscall
        xor %rax,%rax
        mov %r9, %rax
        xor %r9, %r9
        xor %r8, %r8
        jmp  addi_to_x1_subtraction
exit_printing_addi_x1_subtraction:
        lea addi_x1(%rip), %rsi         # this part is for printing default part of addi
        xor %edx,%edx                   # machine code structure
        mov $25,%edx
        syscall
        jmp print_const_sub        


print_const_sub:
        mov $1, %eax             #this part is for printing or structure for machine code
        mov $1, %edi
        lea const_sub(%rip), %rsi
        xor %edx,%edx
        mov $38,%edx
        syscall
        jmp continue_operation
