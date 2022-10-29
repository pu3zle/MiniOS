;;-----------------_DEFINITIONS ONLY_-----------------------
;; IMPORT FUNCTIONS FROM C
%macro IMPORTFROMC 1-*
%rep  %0
    %ifidn __OUTPUT_FORMAT__, win32 ; win32 builds from Visual C decorate C names using _ 
    extern _%1
    %1 equ _%1
    %else
    extern %1
    %endif
%rotate 1 
%endrep
%endmacro

;; EXPORT TO C FUNCTIONS
%macro EXPORT2C 1-*
%rep  %0
    %ifidn __OUTPUT_FORMAT__, win32 ; win32 builds from Visual C decorate C names using _ 
    global _%1
    _%1 equ %1
    %else
    global %1
    %endif
%rotate 1 
%endrep
%endmacro

%define break xchg bx, bx

IMPORTFROMC KernelMain

TOP_OF_STACK                equ 0x200000
KERNEL_BASE_PHYSICAL        equ 0x200000
;;-----------------^DEFINITIONS ONLY^-----------------------

segment .text
[BITS 32]
ASMEntryPoint:
    cli
    MOV     DWORD [0x000B8000], 'O1S1'
%ifidn __OUTPUT_FORMAT__, win32
    MOV     DWORD [0x000B8004], '3121'                  ; 32 bit build marker
%else
    MOV     DWORD [0x000B8004], '6141'                  ; 64 bit build marker
%endif



    MOV     ESP, TOP_OF_STACK                           ; just below the kernel
    
    break

    ; Disable CR0.PG
    MOV     EBX,    CR0
    AND     EBX,    ~(1 << 31)
    MOV     CR0,    EBX

    ; Enable CR4.PAE
    MOV     EAX,    CR4
    OR      EAX,    1 << 5
    MOV     CR4,    EAX
    
    ; Load PML4
    MOV     EAX,    PML4
    MOV     CR3,    EAX

    ; Set IA32_EFER.LME
    MOV     ECX,    0xC0000080
    RDMSR
    OR      EAX,    1 << 8
    WRMSR

    ; Set CR0.PG and CR0.PE
    OR      EBX, (1<<31) | (1<<0)
    MOV     CR0,    EBX

    MOV     AX,     GDTTable.data64
    MOV     DS,     AX
    MOV     SS,     AX
    MOV     ES,     AX
    MOV     GS,     AX
    MOV     FS,     AX

    JMP     GDTTable.code64:.bits64

    .bits64:
    [BITS 64]

    ; see https://wiki.osdev.org ,Intel's manual, http://www.brokenthorn.com/Resources/ ,http://www.jamesmolloy.co.uk/tutorial_html/

    MOV     RAX, KernelMain     ; after 64bits transition is implemented the kernel must be compiled on x64
    CALL    RAX
    
    break
    CLI
    HLT

;;--------------------------------------------------------


__cli:
    CLI
    RET

__sti:
    STI
    RET

__magic:
    XCHG    BX,BX
    RET
    
__enableSSE:                ;; enable SSE instructions (CR4.OSFXSR = 1)  
    MOV     RAX, CR4
    OR      RAX, 0x00000200
    MOV     CR4, RAX
    RET
    
EXPORT2C ASMEntryPoint, __cli, __sti, __magic, __enableSSE

align 0x1000
PTE:
    %assign i 0
    %rep 1024
        dq 0x0000000000000003 + 0x1000 * i
    %assign i i+1
    %endrep

align 0x1000
PDE:
    dq 0x0000000000000003 + PTE
    dq 0x0000000000000003 + PTE + 0x1000

align 0x1000
PDPT:
    dq 0x0000000000000003 + PDE

align 0x1000
PML4:
    dq 0x0000000000000003 + PDPT


