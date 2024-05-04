/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <memory/paddr.h>

void init_rand();
void init_log(const char *log_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_device();
void init_sdb();
void init_disasm(const char *triple);

static void welcome() {
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-NEMU!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
  Log("Exercise: Please remove me in the source code and compile NEMU again.");
}

#ifndef CONFIG_TARGET_AM
#include <getopt.h>
#include <fcntl.h>
#include <unistd.h>
/*
#include <libelf.h>
#include <gelf.h>
*/

#ifdef  CONFIG_FTRACE
#include <ftrace.h>
struct elf ftrace[128] = {};
#endif

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *elf_file = NULL;
static int difftest_port = 1234;

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"elf"      , required_argument, NULL, 'e'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'e': elf_file = optarg; break; 
      case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

#ifdef CONFIG_FTRACE
/*
void parse_elf()
{
 int fd = open(elf_file, O_RDONLY);
    if (fd < 0) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    if (elf_version(EV_CURRENT) == EV_NONE) {
        fprintf(stderr, "ELF library initialization failed: %s\n", elf_errmsg(-1));
        exit(EXIT_FAILURE);
    }

    Elf *elf = elf_begin(fd, ELF_C_READ, NULL);
    if (!elf) {
        fprintf(stderr, "elf_begin() failed: %s\n", elf_errmsg(-1));
        exit(EXIT_FAILURE);
    }

    Elf_Scn *scn = NULL;
    GElf_Shdr shdr;
    int j = 0;
    while ((scn = elf_nextscn(elf, scn)) != NULL) {
        if (gelf_getshdr(scn, &shdr) != &shdr) {
            fprintf(stderr, "gelf_getshdr() failed: %s\n", elf_errmsg(-1));
            exit(EXIT_FAILURE);
        }

        if (shdr.sh_type == SHT_SYMTAB) {
            Elf_Data *data = elf_getdata(scn, NULL);
            if (!data) {
                fprintf(stderr, "elf_getdata() failed: %s\n", elf_errmsg(-1));
                exit(EXIT_FAILURE);
            }

            int count = shdr.sh_size / shdr.sh_entsize;
            for (int i = 0; i < count; ++i) {
                GElf_Sym sym;
                if (gelf_getsym(data, i, &sym) != &sym) {
                    fprintf(stderr, "gelf_getsym() failed: %s\n", elf_errmsg(-1));
                    exit(EXIT_FAILURE);
                }

                char *name = elf_strptr(elf, shdr.sh_link, sym.st_name);
                if (!name) {
                    fprintf(stderr, "elf_strptr() failed: %s\n", elf_errmsg(-1));
                    exit(EXIT_FAILURE);
                }

                if (GELF_ST_TYPE(sym.st_info) == STT_FUNC) {
                    strcpy(ftrace[j].name, name);
                    ftrace[j].addr = sym.st_value;
                    ++j;
                }
            }
        }
    }

    elf_end(elf);
    close(fd);

}
*/

void parse_elf() {
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

#endif
void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  #ifdef  CONFIG_FTRACE
    parse_elf();
  #endif
  /* Set random seed. */
  init_rand();

  /* Open the log file. */
  init_log(log_file);

  /* Initialize memory. */
  init_mem();

  /* Initialize devices. */
  IFDEF(CONFIG_DEVICE, init_device());

  /* Perform ISA dependent initialization. */
  init_isa();

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  /* Initialize the simple debugger. */
  init_sdb();

#ifndef CONFIG_ISA_loongarch32r
  IFDEF(CONFIG_ITRACE, init_disasm(
    MUXDEF(CONFIG_ISA_x86,     "i686",
    MUXDEF(CONFIG_ISA_mips32,  "mipsel",
    MUXDEF(CONFIG_ISA_riscv,
      MUXDEF(CONFIG_RV64,      "riscv64",
                               "riscv32"),
                               "bad"))) "-pc-linux-gnu"
  ));
#endif

  /* Display welcome message. */
  welcome();
}
#else // CONFIG_TARGET_AM
static long load_img() {
  extern char bin_start, bin_end;
  size_t size = &bin_end - &bin_start;
  Log("img size = %ld", size);
  memcpy(guest_to_host(RESET_VECTOR), &bin_start, size);
  return size;
}

void am_init_monitor() {
  init_rand();
  init_mem();
  init_isa();
  load_img();
  IFDEF(CONFIG_DEVICE, init_device());
  welcome();
}
#endif
