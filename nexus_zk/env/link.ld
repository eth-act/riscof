OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  /* Before the first entry point we'll need space for the tohost/fromhost
   * facilities that the virtual device tree code expects to see. */
  . = 0x80000000;
  .text.init : { *(.text.init) }
  .text : { *(.text) }
  .data ALIGN(0x1000) : { *(.data) }
  .bss : { *(.bss) }

  /* Signature region for compliance testing */
  .tohost ALIGN(0x1000) (NOLOAD) : { *(.tohost) }
  .fromhost ALIGN(0x1000) (NOLOAD) : { *(.fromhost) }
  
  /* Signature region for compliance testing */
  .signature ALIGN(0x100) : { 
    PROVIDE(begin_signature = .);
    PROVIDE(end_signature = . + 0x500); /* Reserve 1280 bytes for signature */
    . = . + 0x500;
  }
  _end = .;
} 