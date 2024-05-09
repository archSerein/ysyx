#include <cstdio>
#include <cstring>
#include <cstdint>
#include "ftrace.hpp"
#include "defs.hpp"

struct elf ftrace[128] = {};

void parse_elf(char *elf_file) {
    FILE* file = fopen(elf_file, "rb");
    if (file == NULL) {
        printf("Failed to open file: %s\n", elf_file);
        return;
    }
  
    size_t ret;
    Elf32_Ehdr header;
    ret = fread(&header, sizeof(Elf32_Ehdr), 1, file);
    // assert(ret == 1);
    
    Elf32_Shdr sctions[header.e_shnum];
    fseek(file, header.e_shoff, SEEK_SET);
    ret = fread(sctions, sizeof(Elf32_Shdr), header.e_shnum, file);
    // assert(ret == 1);
    

    Elf32_Shdr strtab_section, symtab_section;
    for (int i = 0; i < header.e_shnum; i++) {
        if (sctions[i].sh_type == SHT_STRTAB) {
            strtab_section = sctions[i];
            break;
        }
    }
    for(int i = 0; i < header.e_shnum; i++) {
        if (sctions[i].sh_type == SHT_SYMTAB) {
            symtab_section = sctions[i];
            break;
        }
    }
    
    char buffer[strtab_section.sh_size];

    fseek(file, strtab_section.sh_offset, SEEK_SET);
    ret = fread(buffer, sizeof(char), sizeof(buffer), file);
    // assert(ret == 1);

    fseek(file, symtab_section.sh_offset, SEEK_SET);
    Elf32_Sym strtab;
    
    int count = symtab_section.sh_size / sizeof(Elf32_Sym);
    

    int index = 0;
    for(int i = 0; i < count; i++) {
        ret = fread(&strtab, sizeof(Elf32_Sym), 1, file);
        // assert(ret == 1);
        
        if(ELF32_ST_TYPE(strtab.st_info) == STT_FUNC) {
            strncpy(ftrace[index].name, buffer + strtab.st_name, MAXLEN);
            ftrace[index].name[MAXLEN - 1] = 0;
            ftrace[index].addr = strtab.st_value;
            ++index;
        }
    }
    
    if(ret == 0)  printf("fread error\n");
    fclose(file);
}