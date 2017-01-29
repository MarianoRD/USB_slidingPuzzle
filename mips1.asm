# Proyecto 2
#
# Hecho por:
#	Mariano Rodríguez 12-10892
#	Pablo Gonzalez 13-10575

# Uso de registros:
#	$s0: File descriptor.
#	$s1: Píxeles de la imagen.
#	$s2: Dirección del heap.
#	$s3: Dirección de la información.
#	$s4: Posicion del cuadro negro (apuntador en esquina superior izquierda).
#	$s5: Cantidad de pixeles por cuadro.
#	$s7: Posición del cuadro negro (1-16).

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

main:	
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

############################################################	
# INICIO DE LA MAGIA NEGRA
############################################################

# Calcula el apuntador del cuadro negro
	# Uso de registros
	#	$t0: Dimension de la imagen
	#	$t1: Apuntador de memoria (inicializa en el Heap)
	#	$t2: Tamaño de cada fila
	#	$t3: Tamaño de la imagen
	#	$t4: Lineas por cuadro
	
	# Cargo registros
	move $t0, $s1
	move $t1, $s2
	# Calculo el tamaño de la imagen
	sll $t2, $t0, 2 # Multiplico por 4
	mulu $t3, $t2, $t0 # Bytes de la imagen completa
	# Calculo los pixeles de cada cuadro
	srl $t4, $t0, 2 # Divido entre 4
	move $t4, $s5
	# Busco el apuntador del cubo negro
	addu $t1, $t1, $t3 # Apuntador al final de la imagen
	subu $t1, $t1, $t0 # Inicio de la ultima fila del cuadrado negro
	# Busco cuantos bytes hasta el inicio del cuadro negro
	mulu $t5, $t4, $t2
	subu $t1, $t1, $t5 
	addiu $t1, $t1, $t2 # Inicio del cuadro negro
	# Guarda el resultado
	move $s4, $t1, $t1
	# Inicia el contador de posición
	li $s7, 16
	
# Termina ejecucion
	j salir
	

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


# Mueve el cuadro negro hacia arriba
c_arriba:
	# Uso de registros:
	#	$t0: Apuntador del cuadro negro
	#	$t1: Apuntador del cuadro a ser movido
	#	$t2: Pixel que está siendo movido
	#	$t3: Pixeles por cuadro (ancho)
	#	$t4: Pixeles por cuadro (alto)

	move $t0, $s4
	move $t3, $s5
	move $t4, $s5
	
	# Cambia la posicion del cuadro en el contador
	subu $s7, $s7, 4
	
	
	# Cambia los pixeles

# Mueve el cuadro negro hacia abajo
c_abajo:
	# Uso de registros:
	#	$t0: Apuntador del cuadro negro
	#	$t1: Apuntador del cuadro a ser movido
	#	$t2: Pixel que está siendo movido
	#	$t3: Pixeles por cuadro

	move $t0, $s4
	move $t3, $s5
	
	# Cambia la posicion del cuadro en el contador
	addiu $s7, $s7, 4

# Mueve el cuadro negro a la izquierda
c_izquierda:
	# Uso de registros:
	#	$t0: Apuntador del cuadro negro
	#	$t1: Apuntador del cuadro a ser movido
	#	$t2: Pixel que está siendo movido
	#	$t3: Pixeles por cuadro

	move $t0, $s4
	move $t3, $s5
	
	# Cambia la posicion del cuadro en el contador
	subu $s7, $s7, 1

# Mueve el cuadro negro a la derecha
c_derecha:
	# Uso de registros:
	#	$t0: Apuntador del cuadro negro
	#	$t1: Apuntador del cuadro a ser movido
	#	$t2: Pixel que está siendo movido
	#	$t3: Pixeles por cuadro

	move $t0, $s4
	move $t3, $s5
	
	# Cambia la posicion del cuadro en el contador
	addiu $s7, $s7, 1

# Sale del programa
salir:
	li $v0, 10
	syscall
