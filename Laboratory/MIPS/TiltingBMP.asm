.data
		
header:		.space 56
offset:		.space 4
size:		.space 4 # rozmiar pliku wejsciowego
width:		.space 4 
height:		.space 4 
poczatek:	.space 4
pomocniczy:	.space 4


startMsg:	.asciiz "Przechylanie Obrazka BMP w Architekturze MIPS\n   Mateusz Dorobek WEiTI PW Informatyka 2017.04\n"
readMsg:	.asciiz "Wczytano Obraz\n   Przetwarzanie...\n"
chooseMsg:	.asciiz "Wybierz plik: 1, 2, 3\n"
chooseErrorMsg:	.asciiz "Zly wybor pliku.\n"
errorMsg:	.asciiz "Blad wczytywanie pliku (zwiazany z plikiem)\n"
fileNameIn1:	.asciiz "fileIn1.bmp"
fileNameIn2:	.asciiz "fileIn2.bmp"
fileNameIn3:	.asciiz "fileIn3.bmp"
fileNameOut:	.asciiz "fileOut.bmp"

		.text
		.globl main

main:
	# powitanie:
	la $a0, startMsg
	li $v0, 4
	syscall
	
readFile:
	# -----------------------  Czytanie pliku  ---------------------------------

	# --------------------------------------------------------------------------
	# ------------------  Przeznaczenie rejestrow  -----------------------------
	# --------------------------------------------------------------------------
	# $t1 - deskryptor
	# $s0 - rozmiar bitmapy
	# $s1 - adres zaalokowanej pamieci
	# $s2 - szerokosc
	# $s3 - wysokosc
	# --------------------------------------------------------------------------
	# Wybierz plik
	la $a0, chooseMsg
	li $v0, 4
	syscall
	# Czytam wybor
	li $v0, 5
	syscall
	move $t2, $v0
	beq $t2, 1, fileIn1
	beq $t2, 2, fileIn2
	beq $t2, 3, fileIn3
	b chooseError
	
fileIn1:
	# otwieranie pliku 'fileIn1.bmp':
	la $a0, fileNameIn1	# file name
	li $a1, 0		# flags 0 = read-only, 1 = write-only with create, 9 - and append
	li $a2, 0		# mode
	li $v0, 13		# open file
	syscall
	b descriptor
fileIn2:
	# otwieranie pliku 'fileIn2.bmp':
	la $a0, fileNameIn2	# file name
	li $a1, 0		# flags 0 = read-only, 1 = write-only with create, 9 - and append
	li $a2, 0		# mode
	li $v0, 13		# open file
	syscall
	b descriptor
fileIn3:
	# otwieranie pliku 'fileIn3.bmp':
	la $a0, fileNameIn3	# file name
	li $a1, 0		# flags 0 = read-only, 1 = write-only with create, 9 - and append
	li $a2, 0		# mode
	li $v0, 13		# open file
	syscall
descriptor:
	move $t1, $v0 		# deskryptor pliku do $t1 ujemny w przypadku bledu
	bltz $t1, fileError	# jesli blad skaczemy do fileError
	
	# przeczytano:
	la $a0, readMsg
	li $v0, 4
	syscall
	
	# ---------------------  Wczytywanie naglowka pliku  -----------------------
	
	# wczytanie calego NAGLOWKA:
  	move $a0, $t1     
	la   $a1, header+2   	  # lw laduje tylko slowa o adreasie podzielnym przez 4
  	li   $a2, 54
  	li   $v0, 14   
  	syscall			
	
	lw $s0, header+4	# s0 - rozmiar bitmapy
	lw $s2, header+20	# s2 - zapisanie szerokosci obrazka
	lw $s3, header+24	# s3 - zapisanie wysokosci obrazka
	# laduje 4 bajty - 32 bity - trzeba rozbic na 2 instr
	
	sw $s2, width
	sw $s3, height
	
	sub $s0, $s0, 54
	sw  $s0, size
	
	# Alokacja pamieci o rozmiarze pliku:
	move $a0, $s0	# rozmiar pamieci
	li $v0, 9
	syscall
	# Adres zaalokowanej pamieci
	move $s1, $v0
	sw $s1, poczatek
	
	# wczytanie BITMAPY:
	move $a0, $t1		
	la $a2, ($s0)		# rozmiar pliku do wczytanie jest w $s0
	la $a1, ($s1)		# adres do wczytania jest w $s1
	li $v0, 14
	syscall
	
	# Zamkniecie pliku
	move $a0, $t1
	li $v0, 16
	syscall
	
	# -------- BITMAPINFOHEADER - 40 bajtów --------
	# Nag³ówkiem plików BMP w Windows od wersji V3
	# jest BITMAPINFOHEADER, struktura 
	# sk³adaj¹ca siê z 11 pól o ³¹cznej d³ugoœci 40 bajtów 
	
tilt: 
	# ---------------------------  Przechylanie  ------------------------------
	
	# --------------------------------------------------------------------------
	# ------------------  Przeznaczenie rejestrow  -----------------------------
	# --------------------------------------------------------------------------
	# $t0 - wska¿nik na wiersz pomocniczy
	# $t1 - wskaŸnik po kolejnych elementach
	# $t2 - wskaŸnik po wierszach
	# $t3 - liczba bajtów w wierszu
	# $t4 - licznik po bajtach w wierszu
	# $t5 - padding
	# $t6 - licznik po kolejnych wierszach (height)
	# $s0 - rozmiar pliku
	# $s1 - adres zaalokowanej pamieci
	# $s2 - szerokosc
	# $s3 - wysokoscc
	# $s4 - padding
	# $s5 - rejestr pomocniczy przy przenoszeniu wartosci wskaznikami
	# $s6 - numer wiersza w ktorym sie znajdujemy (0,1,2,...) rowny przesunieciu
	# $s7 - pomocniczy - rozne zastosowania
	# --------------------------------------------------------------------------
	
	
	# Liczenie PADDINGU
	li $t5, 4		
	divu $s2, $t5		# dzielenie s2 przez t5, reszta z dzielenia w HI
	mfhi $t5		# przekopiowanie hi do t5
	
	# Alokacja pamieci o rozmiarze szerkowosci wiersza:
	mul $t6, $s2, 3		
	move $a0, $t6		# rozmiar wiersza pomocniczego
	li $v0, 9
	syscall
	# Adres zaalokowanej pamieci na wiersz pomocniczy
	move $t0, $v0
	sw $t0, pomocniczy
	
	lw   $t1, poczatek
	lw   $t2, poczatek
	lw   $t3, width
	mul $t3, $t3, 3		#liczba pikseli w wierszu x3 (RGB) zeby poruszac sie po bajtach
	move $t4, $t3
	lw   $t6, height
	li   $s6, 0
	# Zapisanie pierwszego wiersza bitmapy do wiersza pomocniczego
loopForEachRow:
	move $t4, $t3
	lw $t0, pomocniczy
	move $t1, $t2
copyToTempRow:
	# Zapisuje ca³y wiersz bez paddingu do wiersza pomocniczego
	# t1 --> t0
	lb $s5, ($t1)
	sb $s5, ($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	addi $t4, $t4, -1
	bnez $t4, copyToTempRow

# Ustawienie wskaznikow na poczatek wierza
	lw $t0, pomocniczy
	move $t1, $t2
# Przesuniecie wskaznika na wiersz pomocniczy o odpowiednia wartosc
	mul $t4, $s6, 3		# Wskazanie na poczatek pikseli do przepisania
	add $t0, $t0, $t4	
	move $s7, $t3		# liczba bajtow w wierszu (bez paddingu)
shiftingRow:
	# t0 --> t1
	lb $s5, ($t0)
	sb $s5, ($t1)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	addi $s7, $s7, -1
	beqz $s7, nextRow	# Jak juz przerobi wszystkie piksele to nastepny wiersz
	addi $t4, $t4, 1
	# Jezeli dotrzemy do konca wiersza pikseli bez paddingu to przepisujemy jego poczatek
	bne $t4, $t3, shiftingRow
	# Ustawiam wskaznik na poczatek wiersza
	lw $t0, pomocniczy
	li $t4, 0	
	b shiftingRow	
nextRow:	
	# Przesuniecie do kolejnego wiersza
	add $t2, $t2, $t3	# Liczba bajtów
	add $t2, $t2, $t5	# Padding
	# Mamy wskaznik na kolejny wiersz
	addi $s6, $s6, 1
	mul $s7, $s6, 3
	# Jezeli obazek wyzszy niz szerszy to wracam z przesunieciem na poczatek wiersza
	bne $s7, $t3, NieZerujPrzesuniecia
ZerujPrzesuniecie:
	li $s6, 0
	addi $t6, $t6, -1
	beqz $t6, saveFile
	b loopForEachRow
NieZerujPrzesuniecia:
	addi $t6, $t6, -1
	beqz $t6, saveFile
	b loopForEachRow

saveFile:
	# zapisujemy wynik pracy w pliku "out.bmp"
	la $a0, fileNameOut
	li $a1, 1		# falga 1 = write-only with create
	li $a2, 0		
	li $v0, 13
	syscall
	
	move $t0, $v0 		# deskryptor pliku do $t0 ujemny w przypadku bledu
	bltz $t0, fileError	# jesli blad skaczemy do file exec
	
	bltz $t0, fileError	# jesli bald to skok do fileError label
	lw $s0, size		# ladowanie rejestrow
	lw $s1, poczatek	
	
	# Zapis NAGLOWKA
	move $a0, $t0		
	la $a1, header+2
	la $a2, 54
	li $v0, 15
	syscall
	
	# Zapis BITMAPY
	move $a0, $t0		
	la $a1, ($s1)		
	la $a2, ($s0)		
	li $v0, 15
	syscall
	
	move $a0, $t0
	li $v0, 16		# zamykanie pliku
	syscall
	
	b exit
chooseError:
	la $a0, chooseErrorMsg 	# komunikat o bledzie
	li $v0, 4
	syscall
	b exit
fileError:
	la $a0, errorMsg 	# komunikat o bledzie
	li $v0, 4
	syscall
exit:	
	# zamkniecie programu:
	li $v0, 10
	syscall