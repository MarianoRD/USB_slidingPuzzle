# Proyecto 2
#
# Hecho por:
#	Mariano Rodríguez 12-10892
#	Pablo Gonzalez 13-10575

# Uso de registros:
#	$s0: File descriptor.
#	$s1: Píxeles de la imagen.
#	$s2: Dirección del heap.
#	$s3: Fila (Bytes) <- (Dirección de la información.)
#	$s4: Posicion del cuadro negro (apuntador en esquina superior izquierda).
#	$s5: Cantidad de pixeles por cuadro.
#	$s7: Posición del cuadro negro (0-15).

# Numeración de la imagen
#
#	 ____ ____ ____ ____
#	|    |    |    |    |
#	|  0 |  1 |  2 |  3 |
#	|____|____|____|____|
#	|    |    |    |    |
#	|  4 |  5 |  6 |  7 |
#	|____|____|____|____|
#	|    |    |    |    |
#	|  8 |  9 | 10 | 11 |
#	|____|____|____|____|
#	|    |    |    |    |
#	| 12 | 13 | 14 | 15 |
#	|____|____|____|____|
#


.data
	solicitud:	.asciiz "\nIntroduzca el nombre de la imagen: "
	pixelimg:	.asciiz "\nPíxeles de la imagen (ancho o alto): "
	nombre: 	.space 24
	
	# Conectar Bitmap
	conectar:	.asciiz "\nPor favor abra, configure y conecte el Bitmap Display, con los siguientes datos: "
	direccion:	.asciiz "\nDirección base de memoria: "
	dirheap:	.asciiz "0x10040000 "
	presione:	.asciiz "\nPresione enter para continuar: "
	dimension:	.asciiz "\nDimensiones de la imagen: "
	comience:	.asciiz "\nComience a jugar, usando las teclas W,A,S,D para jugar y Esc para salir."
	.align 2
	apuntadores: 	.space	60 # 15 palabras

##########################################################################################################################
#						Inicio del Programa							 #
##########################################################################################################################	
	
.text
	# Impresion de 'solicitud'
	la $a0, solicitud
	li $v0, 4
	syscall
	# Recepción del nombre
	la $a0, nombre
	la $a1, 19 # Cantidad de caracteres
	li $v0, 8
	syscall

# Borrar \n 

borrarsalto:
	# Funcion que borra el salto de linea (\n) al final del nombre de la imagen
	lb $t0, nombre($t1)
	beq $t0, 0xA, borrar
	addi $t1, $t1, 1
	b borrarsalto

# Borrar el salto de linea
borrar:
	sb $zero, nombre($t1)
	
# Impresión de la solicitud del tamaño de la imagen
	la $a0, pixelimg
	li $v0, 4
	syscall
# Recepción del tamaño
	li $v0, 5
	syscall
# Guardo el tamaño
	move $s1, $v0

# Solicito al usuario que abra y conecte el Bitmap Display
	jal conectarbitmap

	
	# Abre el archivo
	la $a0, nombre
	li $a1, 0 # Flag, 0: lectura, 1: escritura
	li $a2, 0 # Flag mode
	li $v0, 13
	syscall
	
	# Guarda el "file descriptor"
	move $s0, $v0
	
	# Calculo del tamano de la imagen (4B/color)
	mulu $t1, $s1, $s1 	# Multiplico alto por ancho
	mulu $t2, $t1, 4		# Multiplico el resultado por 4 que va a ser la cantidad de bytes por pixel
	
	# Reservo la memoria (comienzo del Heap)
	move $a0, $t2
	li $v0, 9
	syscall
	move $s2, $v0
	
	# Vuelvo a reservar la memoria (para información)
	# move $a0, $t2 Ya de la llamada anterior
	li $v0, 9
	syscall
	# Guardo la direccion de la informacion
	move $s3, $v0
	
	# Lee la imagen
	move $a0, $s0
	move $a1, $s3
	move $a2, $t2
	li $v0, 14
	syscall

	# Muevo la informacion al Heap
	# Cargo los registros
	move $t3, $t1
	move $t1, $s3
	move $t2, $s2

mueveinfo:
	# Uso de registros
	#	$t0: Pixel siendo movido
	#	$t1: Direccion de informacion
	#	$t2: Direccion del Heap
	#	$t3: Contador de iteraciones
	lw $t0, ($t1)
	sw $t0, ($t2)
	addiu $t1, $t1, 4
	addiu $t2, $t2, 4
	subu $t3, $t3, 1
	bnez $t3, mueveinfo
	

############################################################################################################################
# 						PRE-PROCESAMIENTO							   #
############################################################################################################################

# Calculo de los distintos apuntadores de memoria (Esquina superior izquierda de cada cuadro)
	# Uso de registros
	#	$t0: Dimension de la imagen
	#	$t1: Apuntador de memoria (inicializa en el Heap)
	#	$t2: Tamaño de cada fila
	#	$t3: Tamaño de 4 cuadros
	#	$t4: Pixeles por cuadro
	#	$t5: Apuntador calculado

	# Cargo registros
	move $t0, $s1
	move $t1, $s2
	# Calculo el tamaño de la fila
	sll $t2, $t0, 2 # Multiplico por 4
	move $s3, $t2 # Guardo los datos
	# Pixeles por cuadro (ancho o alto)
	srl $t4, $t0, 2 # Divido entre 4
	move $s5, $t4
	# Bytes de los 4 cuadros
	mulu $t3, $t2, $t4
	
	# Empiezo a calcular los apuntadores
	# Primera fila
	sw $s2, apuntadores # Cuadro 0
	addu $t5, $s2, $t0
	sw $t5, apuntadores+4 #Cuadro 1
	addu $t5, $t5, $t0
	sw $t5, apuntadores+8 #Cuadro 2
	addu $t5, $t5, $t0
	sw $t5, apuntadores+12 #Cuadro 3
	# Segunda fila
	move $t5, $s2 # Reinicio apuntador de memoria
	addu $t5, $t5, $t3 # Sumo 4 cuadros
	sw $t5, apuntadores+16 #Cuadro 4
	addu $t5, $t5, $t0
	sw $t5, apuntadores+20 #Cuadro 5
	addu $t5, $t5, $t0
	sw $t5, apuntadores+24 #Cuadro 6
	addu $t5, $t5, $t0
	sw $t5, apuntadores+28 #Cuadro 7
	# Tercera fila
	move $t5, $s2 # Reinicio apuntador de memoria
	sll $t9, $t3, 1
	addu $t5, $t5, $t9 # Sumo 8 cuadros
	sw $t5, apuntadores+32 #Cuadro 8
	addu $t5, $t5, $t0
	sw $t5, apuntadores+36 #Cuadro 9
	addu $t5, $t5, $t0
	sw $t5, apuntadores+40 #Cuadro 10
	addu $t5, $t5, $t0
	sw $t5, apuntadores+44 #Cuadro 11
	# Cuarta fila
	move $t5, $s2 # Reinicio apuntador de memoria
	addu $t9, $t9, $t3 
	addu $t5, $t5, $t9 # Sumo 12 cuadros
	sw $t5, apuntadores+48 #Cuadro 12
	addu $t5, $t5, $t0
	sw $t5, apuntadores+52 #Cuadro 13
	addu $t5, $t5, $t0
	sw $t5, apuntadores+56 #Cuadro 14
	addu $t5, $t5, $t0
	sw $t5, apuntadores+60 #Cuadro 15
	
	# Apuntador del cuadro negro
	lw $s4, apuntadores+60
	# Inicia el contador de posición
	li $s7, 15

############################################################################################################################
#							PROGRAMA							   #
############################################################################################################################

# Habilita las interrupciones por taclado
	li $t0, 0xFFFF0000 # Cargo la direccion del teclado
	ori $t0, $t0, 0x2 # Habilito las interrupciones (interrupt_enable:1)
# Mensaje de inicio de juego
	li $v0 4                # syscall 4 (print_str)
	la $a0 comience
	syscall
#########################################
li $t4, 0x8000 # timer interrupt enable bit
or $t4, $t4, 0x1000 # bonk interrupt bit
or $t4, $t4, 1 # global interrupt enable
mtc0 $t4, $12 # set interrupt mask (Status register)
##########################################
main:
	nop
	nop
	j main

		# Mueve un cuadro con otro
mueve_cuadro:
	# Recepción de datos:
	#	$a0: Apuntador cuadro negro
	#	$a1: Apuntador cuadro a ser movido
	# Uso de registros:
	#	$t0: Apuntador del cuadro negro
	#	$t1: Apuntador del cuadro a ser movido
	#	$t2: Contador de cantidad de filas movidas (alto)
	#	$t6: Pixeles por cuadro (ancho)
	
	move $t0, $a0 # Apuntador del cuadro negro
	mulu $t5, $t4, $s3
	subu $t1, $t0, $t5 # Esquina superior izquierda del cuadro a ser movido
	move $t2, $t1 # Le doy la ubicacion del cuadro a mover al registro que hace recorrido
	
	move $t2, $zero # 
	move $t6, $s5 # Contadores
	
	# Cambia la posicion del cuadro en el contador
	subu $s7, $s7, 4
	
	
	# Cambia los pixeles

c_mueve: 
	beqz $t6, reiniciac_mueve
	# Cambia los pixeles
	lw $t4, ($t0)
	lw $t5, ($t1)
	sw $t5, ($t0)
	sw $t4, ($t1)
	# Mueve los punteros
	addiu $t0, $t0, 4
	addiu $t1, $t1, 4
	subu $t6, $t6, 1
	j c_mueve

reiniciac_mueve:
	beq $t2, $s5  regresar1
	addu $t2, $t2, 1
	mulu $t7, $t2, $s3
	addu $t1, $t2, $t7 # Mueve a la siguiente fila del cuadro a mover
	addu $t0, $s4, $t7 # Mueve a la siguiente fila del cuadro negro
	move $t6, $s5 # Reinicia contador primero (llega a 0)
	j c_mueve		

#########################################################################################################################
#							FUNCIONES							#
#########################################################################################################################

conectarbitmap:

	# Imprime la solicitud
	la $a0, conectar
	li $v0, 4
	syscall

	# Imprime los datos de la imagen (ancho y alto)
	# Ancho
	la $a0, dimension
	li $v0, 4
	syscall
	move $a0, $s1
	li $v0, 1
	syscall
	
	# Dirección
	la $a0, direccion
	li $v0, 4
	syscall
	la $a0, dirheap
	syscall
	
	# Continuar
continuar: 
	la $a0, presione
	li $v0, 4
	syscall
	li $v0, 12
	syscall
	# Chequeo de que haya sido enter
	bne $v0, 0xA, continuar
	jr $ra




# Regresa a donde se estaba ejecutando el programa
regresar1:
	jr $ra

# Sale del programa
salir:
	li $v0, 10
	syscall


############################################################################################################################
#							INTERRUPCIONES							   #
############################################################################################################################
# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (C) 1990-2004 James Larus, larus@cs.wisc.edu.
# ALL RIGHTS RESERVED.
#
# SPIM is distributed under the following conditions:
#
# You may make copies of SPIM for your own use and modify those copies.
#
# All copies of SPIM must retain my name and copyright notice.
#
# You may not sell SPIM or distributed SPIM in conjunction with a commerical
# product or service without the expressed written consent of James Larus.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE.
#

########################################################################
# NOTE: Comments added and expanded by Neal Wagner, April 4, 1999
#       and by Matthew Patitz, October 21, 2008
#   ("Text" below refers to Patterson and Hennessy, _Computer
#    Organization and Design_, Morgan Kaufmann.)
#
# INTERRUPT HANDLING IN MIPS:
# Coprocessor 0 has extra registers useful in handling exceptions
# There are four useful coprocessor 0 registers:
#-------------------------------------------------------------------|
#  REG NAME | NUMBER |   USAGE                                      |
#-------------------------------------------------------------------|
#  BadVAddr |   8    | Memory addr at which addr exception occurred |
#  Status   |  12    | Interrupt mask and enable bits               |
#  Cause    |  13    | Exception type and pending interrupt bits    |
#  EPC      |  14    | Address of instruction that caused exception |
#-----------|--------|----------------------------------------------|
# Details:
#   Status register: has an interrupt mask with a bit for each of
#      five interrupt levels.  If a bit is one, interrupts at that
#      level are allowed.  If a bit is zero, interrupts at that level
#      are disabled.  The low order 6 bits of the Status register
#      implement a three-level stack for the "kernel/user" and
#      "interrupt enable" bits.  The "kernel/user" bit is 0 if the
#      program was running in the kernel when the interrupt occurred
#      and 1 if it was in user mode.  If the "interrupt enable" bit is 1,
#      interrupts are allowed.  If it is 0, they are disabled.  At an
#      interrupt, these six bits are shifted left by two bits.
#   Cause register: The value in bits 2-5 of the Cause register
#      describes the particular type of exception.  The error messages
#      below describe these values.  Thus a 7 in bits 2-5 corresponds
#      to message __e7_ below, or a "bad address in data/stack read".
#
# There are special machine instructions for accessing these
# coprocessor 0 registers:
#      mfc0  Rdest, CPsrc: "move from coprocessor 0" moves data 
#         from the special coprocessor 0 register CPsrc into the
#         general purpose register Rdest.
#      mtc0  Rsrc, CPdest: "move to coprocessor 0" moves data 
#         from the general purpose register Rsrc into the special
#         coprocessor 0 register CPdest.
# (There are also coprocessor load and store instructions.)
#
# ACTIONS BY THE TRAP HANDLER CODE BELOW:
#  Branch to address 0x80000180 and execute handler there:
#  1. Save $a0 and $v0 in s0 and s1 and $at in $k1.
#  2. Move Cause into register $k0.
#  3. Do action such as print an error message.
#  4. Increment EPC value so offending instruction is skipped after
#     return from exception.
#  5. Restore $a0, $v0, and $at.
#  6. Clear the Cause register and re-enable interrupts in the Status
#     register.
#  6. Execute "eret" instruction to return execution to the instruction
#     at EPC.
#
########################################################################

# Define the exception handling code.  This must go first!
	.data
	.globl LockFlag
	LockFlag:.word 0
	
	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0

#####################################################
# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can serve as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS32:
	.ktext 0x80000180

#####################################################
# Save $at, $v0, and $a0
#
	.set noat
	move $k1 $at            # Save $at
	.set at

	sw $v0 s1               # Not re-entrant and we can't trust $sp
	sw $a0 s2               # But we need to use these registers


#####################################################
# Print information about exception
#
	li $v0 4                # syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1                # syscall 1 (print_int)
	mfc0 $k0 $13            # Get Cause register
	srl $a0 $k0 2           # Extract ExcCode Field
	andi $a0 $a0 0xf
	syscall

	li $v0 4                # syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)      # $a0 has the index into
	                        # the __excp array (exception
	                        # number * 4)
	nop
	syscall

#####################################################
# Bad PC exception requires special checks
#
	bne $k0 0x18 ok_pc
	nop

	mfc0 $a0 $14            # EPC
	andi $a0 $a0 0x3        # Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10               # Exit on really bad PC
	syscall

#####################################################
#  PC is alright to continue
#
ok_pc:

	li $v0 4                # syscall 4 (print_str)
	la $a0 __m2_            # "occurred and ignored" message
	syscall

	srl $a0 $k0 2           # Extract ExcCode Field
	andi $a0 $a0 0xf
	bne $a0 0 ret           # 0 means exception was an interrupt
	nop

#####################################################
# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.
#  -> not implemented
#
# Codigos ASCII
# 	w: 0x77, a:0x61, s:0x73, d:0x64, ESC:0x1B

li $v0 4                # syscall 4 (print_str)
	la $a0 __m1_
	syscall

	# En caso de ESC salir
	lw $a0, 0xFFFF0004
	bne $a0 0x1B, tecla_w
	li $v0, 10
	syscall
	
	# Caso W
	tecla_w:
	lw $a0, 0xFFFF0004
	bne $a0 0x77, tecla_a
	# Chequea que sea un movimiento valido
	srl $k0, $s7, 2
	beqz $k0, error_tecla
	# Realiza el movimiento
	subu $s7, $s7, 4
	sll $k0, $s7, 2
	lw $a1, apuntadores($k0)
	move $a0, $s4
	# Deshabilita las interrupciones
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	andi $k1, $k1, 0x00 # Deshabilito las interrupciones (interrupt_enable:1)
	# Cambio los cuadros
	la $k0, mueve_cuadro
	jalr $ra
	# Actualizo $s4
	lw $s4, apuntadores($k0)
	# Habilito las interrupciones y regreso al programa
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	ori $k1, $k1, 0x2 # Habilito las interrupciones (interrupt_enable:1)
	j regresar # Regreso al programa

	# Caso A
	tecla_a:
	lw $a0, 0xFFFF0004
	bne $a0 0x61, tecla_s
	# Chequea que sea un movimiento valido
	remu $k0, $s7, 4
	beqz $k0, error_tecla
	# Realiza el movimiento
	subu $s7, $s7, 1
	sll $k0, $s7, 2
	lw $a1, apuntadores($k0)
	move $a0, $s4
	# Deshabilita las interrupciones
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	andi $k1, $k1, 0x00 # Deshabilito las interrupciones (interrupt_enable:1)
	# Cambio los cuadros
	la $k0, mueve_cuadro
	jalr $ra
	# Actualizo $s4
	lw $s4, apuntadores($k0)
	# Habilito las interrupciones y regreso al programa
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	ori $k1, $k1, 0x2 # Habilito las interrupciones (interrupt_enable:1)
	j regresar # Regreso al programa
	
	# Caso S
	tecla_s:
	lw $a0, 0xFFFF0004
	bne $a0 0x73, tecla_d
	# Chequea que sea un movimiento valido
	srl $k0, $s7, 2
	beq $k0, 3, error_tecla
	# Realiza el movimiento
	addiu $s7, $s7, 4
	sll $k0, $s7, 2
	lw $a1, apuntadores($k0)
	move $a0, $s4
	# Deshabilita las interrupciones
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	andi $k1, $k1, 0x00 # Deshabilito las interrupciones (interrupt_enable:1)
	# Cambio los cuadros
	la $k0, mueve_cuadro
	jalr $ra
	# Actualizo $s4
	lw $s4, apuntadores($k0)
	# Habilito las interrupciones y regreso al programa
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	ori $k1, $k1, 0x2 # Habilito las interrupciones (interrupt_enable:1)
	j regresar # Regreso al programa
	
	# Caso D
	tecla_d:
	lw $a0, 0xFFFF0004
	bne $a0 0x64, regresar
	# Chequea que sea un movimiento valido
	remu $k0, $s7, 4
	beq $k0, 3, error_tecla
	# Realiza el movimiento
	addiu $s7, $s7, 1
	sll $k0, $s7, 2
	lw $a1, apuntadores($k0)
	move $a0, $s4
	# Deshabilita las interrupciones
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	andi $k1, $k1, 0x00 # Deshabilito las interrupciones (interrupt_enable:1)
	# Cambio los cuadros
	la $k0, mueve_cuadro
	jalr $ra
	# Actualizo $s4
	lw $s4, apuntadores($k0)
	# Habilito las interrupciones y regreso al programa
	li $k1, 0xFFFF0000 # Cargo la direccion del teclado
	ori $k1, $k1, 0x2 # Habilito las interrupciones (interrupt_enable:1)
	j regresar # Regreso al programa

error_tecla:
	li $v0 4                # syscall 4 (print_str)
	la $a0 __m1_
	syscall
	la $a0 __e25_
	syscall
	j regresar



#####################################################
# Return from (non-interrupt) exception. Skip offending
# instruction at EPC to avoid infinite loop.
#
ret:

	mfc0 $k0 $14            # Get EPC register value
	addiu $k0 $k0 4         # Skip faulting instruction by skipping
	                        # forward by one instruction
                          # (Need to handle delayed branch case here)
	mtc0 $k0 $14            # Reset the EPC register

regresar:
#####################################################
# Restore registers and reset procesor state
#
	lw $v0 s1               # Restore $v0 and $a0
	lw $a0 s2

	.set noat
	move $at $k1            # Restore $at
	.set at

	mtc0 $0 $13             # Clear Cause register

	mfc0 $k0 $12            # Set Status register
	ori  $k0 0x1            # Interrupts enabled
	mtc0 $k0 $12


#####################################################
# Return from exception on MIPS32
#
	eret

# End of exception handling
#####################################################



#
