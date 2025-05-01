MEMORY {
    flash (rx) : ORIGIN = 0x30000000, LENGTH = 256M
    sdram (rwx) : ORIGIN = 0xa0000000, LENGTH = 32M
    psram (rwx) : ORIGIN = 0x80000000, LENGTH = 4M
    sram (rwx) : ORIGIN = 0x0f000000, LENGTH = 8K
}

INCLUDE /home/serein/ysyx/rt-thread-am/bsp/abstract-machine/extra-ysyxsoc.ld
ENTRY(_start)

SECTIONS {
    . = ORIGIN(flash);
    .ftext : {
        *(entry)
        *(fsbl)
    } > flash AT > flash

    .text : {
        _etext_start = .;
        *(.text*)
        _etext_end = .;
    } > sdram AT > flash
    _load_etext_start = LOADADDR(.text);
    etext = .;
    _etext = .;

    .rodata : {
        _rodata_start = .;
        *(.rodata*)
        *(.srodata*)
        _rodata_end = .;
    } > sdram AT > flash
    _load_rodata_start = LOADADDR(.rodata);

    .data : {
        _data_start = .;
        *(.data*)
        *(.sdata*)
        _data_end = .;
    } > sdram AT > flash
    _load_data_start = LOADADDR(.data);
    edata = .;
    _edata = .;

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(.scommon)
        _bss_end = .;
    } > sdram AT > sdram

    .ssbl : {
        _ssbl_start = .;
        *(ssbl)
    } > sram AT > flash
    _load_ssbl_size = SIZEOF(.ssbl);
    _load_ssbl_start = LOADADDR(.ssbl);

    end = .;
    _end = .;

    _heap_start = ORIGIN(psram);
    . = 0x0f002000;
    _stack_pointer = .;

}
