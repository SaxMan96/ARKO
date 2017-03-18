	.data
bufor:	.space 100
msg:	.asciiz "Podaj napis:\n"
msg2:	.asciiz "Po usuniecie spacji:\n"
	.text
	.globl main
main:	
	# wiadomosc
	la $a0, msg
	li $v0, 4
	syscall
	# wczytanie
	la $a0, bufor
	li $a1, 99
	li $v0, 8
	syscall
	
	# usuwanie spacji
	li $s0, ' '
	la $t3, bufor	# tu zaladuje tymczasowo adres bufora
loop:	
	lb $t4, ($t3)	# laduje wartosc znaku
	beqz $t4, end
	bne $t4, $s0, increment
	# space detected
	move $t5, $t3
	# $s5 adres poprz
	# $s6 adres nast
loop2:	
	addi $t6, $t5, 1	
	lb $t7, ($t6)		# laduje wartosc znaku
	sb $s7, ($s5)		# co tu?
	beqz $s5 loop
	b loop2
increment:	
	addi $t3, $t3, 1
	b loop
end:
	# wiadomosc
	la $a0, msg2
	li $v0, 4
	syscall
	
	la $a0, bufor
	li $v0, 4
	syscall
	
	li $v0, 10
	syscall
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	