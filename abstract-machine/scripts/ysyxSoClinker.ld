MEMORY {
    flash : ORIGIN = 0x30000000, LENGTH = 256M
    sram : ORIGIN = 0x0f000000, LENGTH = 8k
}
REGION_ALIAS("REGION_TEXT", flash);
REGION_ALIAS("REGION_RODATA", flash);
REGION_ALIAS("REGION_DATA", sram);
REGION_ALIAS("REGION_BSS", sram);

ENTRY(_start)

SECTIONS {
    /* _pmem_start and _entry_offset are defined in LDFLAGS */
    /* Adjust the location counter if required. */

    /* .text section located in flash for code */
    . = ORIGIN(flash);
    .text : {
        *(entry)            /* Entry point symbols */
        *(.text*)           /* All text sections */
    } > REGION_TEXT
    
    etext = .;
    _etext = .;

    /* .rodata section located in flash for read-only data */
    .rodata : {
        *(.rodata*)         /* All read-only data sections */
        *(.srodata*)        /* All small read-only data sections */
    } > REGION_RODATA

    /* .data section initialized in flash but loaded into sram */
    .data : {
        _data_start = .;
        *(.data*)            /* All data sections */
        *(.sdata*)           /* All small data sections */
        _data_end = .;
    } > REGION_DATA AT > flash
    _load_data_size = SIZEOF(.data);
    _load_data_start = LOADADDR(.data);

    /* Define the load address of the data section in flash */
    edata = .;
    _edata = .;

    /* .bss section located in sram for uninitialized data */
    .bss : {
        _bss_start = .;     /* Start of the BSS section */
        *(.bss*)            /* All bss sections */
        *(.sbss*)           /* All small bss sections */
        *(.scommon)         /* All common symbols */
        _bss_end = .;       /* End of the BSS section */
    } > REGION_BSS

    /* Define heap and stack */
    _heap_start = .;  /* Align the heap start to 4KB boundary */

    . = 0x0f002000;     /* Heap size of 0x2000 bytes (8KB total SRAM) */
    _stack_pointer = .;           /* Set stack pointer */
    
    end = .;                      /* End symbol */
    _end = .;
}