#ifndef __FTRACE_HPP__
#define __FTRACE_HPP__

#define SHT_SYMTAB 2
#define SHT_STRTAB 3
#define STT_FUNC 2
#define STT_NOTYPE 0
#define STT_SECTION 3
#define ELF32_ST_TYPE(i) ((i) & 0xf)
#define MAXLEN 16

typedef uint32_t Elf32_Addr;
typedef uint32_t Elf32_Off;


typedef struct {
    unsigned char e_ident[16];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    Elf32_Addr e_entry;
    Elf32_Off e_phoff;
    Elf32_Off e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
} Elf32_Ehdr;

typedef struct {
    uint32_t sh_name;
    uint32_t sh_type;
    uint32_t sh_flags;
    Elf32_Addr sh_addr;
    Elf32_Off sh_offset;
    uint32_t sh_size;
    uint32_t sh_link;
    uint32_t sh_info;
    uint32_t sh_addralign;
    uint32_t sh_entsize;
} Elf32_Shdr;

typedef struct {
    uint32_t      st_name;
    Elf32_Addr    st_value;
    uint32_t      st_size;
    unsigned char st_info;
    unsigned char st_other;
    uint16_t      st_shndx;
} Elf32_Sym;

typedef struct Symbol{
    char name[MAXLEN];
    uint32_t addr;
    struct Symbol* next;
} Symbol;

void parse_elf(char *elf_file);

#endif // __FTRACE_HPP__