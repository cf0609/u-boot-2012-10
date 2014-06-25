/*
 * Copyright (C) 2009 Samsung Electronics
 * Kyungmin Park <kyungmin.park@samsung.com>
 * Minkyu Kang <mk7.kang@samsung.com>
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <config.h>
#include <version.h>
#include <asm/arch/cpu.h>
#include <asm/arch/power.h>

#define APLL_LOCK_OFFSET		0x00		
#define MPLL_LOCK_OFFSET		0x08
#define APLL_CON0_OFFSET		0x100
#define APLL_CON1_OFFSET		0x104
#define MPLL_CON_OFFSET			0x108
#define CLK_SRC0_OFFSET			0x200
#define CLK_SRC1_OFFSET			0x204
#define CLK_SRC2_OFFSET			0x208
#define CLK_SRC3_OFFSET			0x20c
#define CLK_SRC4_OFFSET			0x210
#define CLK_SRC5_OFFSET			0x214
#define CLK_SRC6_OFFSET			0x218
#define CLK_SRC_MASK0_OFFSET	0x280
#define CLK_SRC_MASK1_OFFSET	0x284
#define CLK_DIV0_OFFSET			0x300
#define CLK_DIV1_OFFSET			0x304
#define CLK_DIV2_OFFSET			0x308
#define CLK_DIV3_OFFSET			0x30c
#define CLK_DIV4_OFFSET			0x310
#define CLK_DIV5_OFFSET			0x314
#define CLK_DIV6_OFFSET			0x318
#define CLK_DIV7_OFFSET			0x31c
#define CLK_DIV0_MASK			0x7fffffff
#define APLL_MDIV      	 		0x7d
#define APLL_PDIV       		0x3
#define APLL_SDIV       		0x1
#define MPLL_MDIV				0x29b
#define MPLL_PDIV				0xc
#define MPLL_SDIV				0x1
#define set_pll(mdiv, pdiv, sdiv)	(1<<31 | mdiv<<16 | pdiv<<8 | sdiv)
#define APLL_VAL			set_pll(APLL_MDIV,APLL_PDIV,APLL_SDIV)
#define MPLL_VAL			set_pll(MPLL_MDIV,MPLL_PDIV,MPLL_SDIV)



/*
 * Register usages:
 *
 * r5 has zero always
 */

_TEXT_BASE:
	.word	CONFIG_SYS_TEXT_BASE

	.globl lowlevel_init
lowlevel_init:
	mov	r9, lr
#if 0
	/* r5 has always zero */
	mov	r5, #0

	ldr	r8, =S5PC100_GPIO_BASE

	/* Disable Watchdog */
	ldr	r0, =S5PC100_WATCHDOG_BASE		@0xEA200000
	orr	r0, r0, #0x0
	str	r5, [r0]

	/* setting SRAM */
	ldr	r0, =S5PC100_SROMC_BASE
	ldr	r1, =0x9
	str	r1, [r0]

	/* S5PC100 has 3 groups of interrupt sources */
	ldr	r0, =S5PC100_VIC0_BASE			@0xE4000000
	ldr	r1, =S5PC100_VIC1_BASE			@0xE4000000
	ldr	r2, =S5PC100_VIC2_BASE			@0xE4000000

	/* Disable all interrupts (VIC0, VIC1 and VIC2) */
	mvn	r3, #0x0
	str	r3, [r0, #0x14]				@INTENCLEAR
	str	r3, [r1, #0x14]				@INTENCLEAR
	str	r3, [r2, #0x14]				@INTENCLEAR

	/* Set all interrupts as IRQ */
	str	r5, [r0, #0xc]				@INTSELECT
	str	r5, [r1, #0xc]				@INTSELECT
	str	r5, [r2, #0xc]				@INTSELECT

	/* Pending Interrupt Clear */
	str	r5, [r0, #0xf00]			@INTADDRESS
	str	r5, [r1, #0xf00]			@INTADDRESS
	str	r5, [r2, #0xf00]			@INTADDRESS

	/* for UART */
	bl uart_asm_init

	/* for TZPC */
	bl tzpc_asm_init

1:
#endif
//debug
#if 1
	ldr r1, =0xE0200280 					
	ldr r0, =0x00001111
	str r0, [r1]

	mov r2, #0x1000

	ldr r1, =0xE0200284 					
	mov r0, #5
	str r0, [r1]

#endif
	mov	lr, r9
	mov	pc, lr

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */
system_clock_init:
	ldr	r8, =S5PV210_CLOCK_BASE		@ 0xE0100000
	/*seting clock off,and not use PLL*/
	ldr	r1,=0x0
	str	r1, [r0, #CLK_SRC0_OFFSET]	

	/*set lock time*/
	ldr	r1,=0x0000ffff
	str	r1,[r0,#APLL_LOCK_OFFSET]
	STR	R1,[R0,#MPLL_LOCK_OFFSET]

	/*Seting divo*/
	/*clear bit[0~31]*/
	ldr r1, [r0, #CLK_DIV0_OFFSET]
	ldr	r2, =CLK_DIV0_MASK
	bic	r1, r1, r2	
	ldr	r2, =0x14131440	
	orr	r1, r1, r2	
	str	r1, [r0, #CLK_DIV0_OFFSET]

	// FOUT = MDIV*FIN/(PDIV*2^(SDIV-1))=0x7d*24/(0x3*2^(1-1))=1000 MHz	
	ldr	r1, =APLL_VAL
	str	r1, [r0, #APLL_CON0_OFFSET]
	// FOUT = MDIV*FIN/(PDIV*2^SDIV)=0x29b*24/(0xc*2^1)= 667 MHz	
	ldr	r1, =MPLL_VAL
	str	r1, [r0, #MPLL_CON_OFFSET]
	ldr	r1, [r0, #CLK_SRC0_OFFSET]	
	ldr	r2, =0x10001111	
	orr	r1, r1, r2	
	str	r1, [r0, #CLK_SRC0_OFFSET]
#if 0	
	/* Set Clock divider */
	ldr	r1, =0x00011110
	str	r1, [r8, #0x304]
	ldr	r1, =0x1
	str	r1, [r8, #0x308]
	ldr	r1, =0x00011301
	str	r1, [r8, #0x300]

	/* Set Lock Time */
	ldr	r1, =0xe10			@ Locktime : 0xe10 = 3600
	str	r1, [r8, #0x000]		@ APLL_LOCK
	str	r1, [r8, #0x004]		@ MPLL_LOCK
	str	r1, [r8, #0x008]		@ EPLL_LOCK
	str	r1, [r8, #0x00C]		@ HPLL_LOCK

	/* APLL_CON */
	ldr	r1, =0x81bc0400		@ SDIV 0, PDIV 4, MDIV 444 (1332MHz)
	str	r1, [r8, #0x100]
	/* MPLL_CON */
	ldr	r1, =0x80590201		@ SDIV 1, PDIV 2, MDIV 89 (267MHz)
	str	r1, [r8, #0x104]
	/* EPLL_CON */
	ldr	r1, =0x80870303		@ SDIV 3, PDIV 3, MDIV 135 (67.5MHz)
	str	r1, [r8, #0x108]
	/* HPLL_CON */
	ldr	r1, =0x80600603
	str	r1, [r8, #0x10C]

	/* Set Source Clock */
	ldr	r1, =0x1111			@ A, M, E, HPLL Muxing
	str	r1, [r8, #0x200]		@ CLK_SRC0

	ldr	r1, =0x1000001			@ Uart Clock & CLK48M Muxing
	str	r1, [r8, #0x204]		@ CLK_SRC1

	ldr	r1, =0x9000			@ ARMCLK/4
	str	r1, [r8, #0x400]		@ CLK_OUT
#endif
	/* wait at least 200us to stablize all clock */
	mov	r2, #0x10000
1:	subs	r2, r2, #1
	bne	1b

	mov	pc, lr

/*
 * uart_asm_init: Initialize UART's pins
 */
uart_asm_init:
	mov	r0, r8
	ldr	r1, =0x22222222
	str	r1, [r0, #0x0]			@ GPA0_CON
	ldr	r1, =0x00022222
	str	r1, [r0, #0x20]			@ GPA1_CON

	mov	pc, lr

/*
 * tzpc_asm_init: Initialize TZPC
 */
tzpc_asm_init:
	ldr	r0, =0xE3800000
	mov	r1, #0x0
	str	r1, [r0]
	mov	r1, #0xff
	str	r1, [r0, #0x804]
	str	r1, [r0, #0x810]

	ldr	r0, =0xE2800000
	str	r1, [r0, #0x804]
	str	r1, [r0, #0x810]
	str	r1, [r0, #0x81C]

	ldr	r0, =0xE2900000
	str	r1, [r0, #0x804]
	str	r1, [r0, #0x810]

	mov	pc, lr
