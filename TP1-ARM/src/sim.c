#include <stdio.h>
#include <assert.h>
#include <string.h>

<<<<<<< Updated upstream
void process_instruction()
{
    /* execute one instruction here. You should use CURRENT_STATE and modify
     * values in NEXT_STATE. You can call mem_read_32() and mem_write_32() to
     * access memory. 
     * */
}
=======
void mem_write_8(uint64_t address, uint8_t value) {
    uint32_t data = mem_read_32(address);
    data = (data & 0xFFFFFF00) | (value & 0xFF);
    mem_write_32(address, data);
}

void mem_write_16(uint64_t address, uint16_t value) {
    uint32_t data = mem_read_32(address);
    data = (data & 0xFFFF0000) | (value & 0xFFFF);
    mem_write_32(address, data);
}

void mem_write_64(uint64_t address, uint64_t value) {
    mem_write_32(address, (uint32_t)(value & 0xFFFFFFFF));
    mem_write_32(address + 4, (uint32_t)(value >> 32));
}

uint64_t mem_read_64(uint64_t address) {
    uint64_t low = mem_read_32(address);
    uint64_t high = mem_read_32(address + 4);
    return (high << 32) | low;
}

uint16_t mem_read_16(uint64_t address) {
    uint32_t data = mem_read_32(address);
    return (uint16_t)(data & 0xFFFF);
}

uint8_t mem_read_8(uint64_t address) {
    uint32_t data = mem_read_32(address & ~0x3);   
    uint8_t offset = address & 0x3;             
    return (data >> (offset * 8)) & 0xFF;        
}

// ALU
#define OPCODE_SUBS_IMM      0b11110001000
#define OPCODE_SUBS_EXT      0b11101011000
#define OPCODE_CMP_IMM       0b11110001
#define OPCODE_CMP_EXT       0b11101011001
#define OPCODE_ANDS_SHIFTED  0b11101010
#define OPCODE_MOVZ          0b110100101
#define OPCODE_EOR           0b11001010000 
#define OPCODE_MUL           0b10011011000
#define OPCODE_CBZ           0b10110100
#define OPCODE_CBNZ          0b10110101
#define OPCODE_STURB         0b00111000000
#define OPCODE_STUR          0b11111000000
#define OPCODE_STURH         0b01111000000
#define OPCODE_LDUR          0b11111000010
#define OPCODE_LDURH         0b01111000010
#define OPCODE_LDURB         0b00111000010
#define OPCODE_ADDS_IMM      0b10110001
#define OPCODE_ADDS_EXT      0b10101011000
#define OPCODE_HLT           0b11010100010
#define OPCODE_ORR           0b10101010000
#define OPCODE_ADD_IMM       0b10010001
#define OPCODE_ADD_EXTENDED   0b10001011000
// B
#define OPCODE_B_COND        0b01010100
#define OPCODE_B             0b000101
#define OPCODE_BR            0b11010110000
// Condicionales
#define OPCODE_BEQ           0b01010100
#define OPCODE_BNE           0b01010101
#define OPCODE_BGT           0b01011010
#define OPCODE_BLT           0b01011011
#define OPCODE_BGE           0b01011000
#define OPCODE_BLE           0b01011001
// Shift
#define OPCODE_LOG_SHIFT     0b1101001101

#define NUM_INSTRUCTIONS (sizeof(instruction_table) / sizeof(Instruction))

typedef struct {
    uint32_t opcode;
    int opcode_len;
    char *name;
    void (*execute)(uint32_t instruction);
} Instruction;

void execute_adds_imm(uint32_t instruction);
void execute_adds_ext(uint32_t instruction);
void execute_subs_imm(uint32_t instruction);
void execute_subs_ext(uint32_t instruction);
void execute_cmp_ext(uint32_t instruction);
void execute_cmp_imm(uint32_t instruction);
void execute_ands_shifted(uint32_t instruction);
void execute_movz(uint32_t instruction);
void execute_b(uint32_t instruction);
void execute_br(uint32_t instruction);
void execute_conditional_branch(uint32_t instruction);
void execute_logical_shift(uint32_t instruction);
void execute_eor(uint32_t instruction);
void execute_orr(uint32_t instruction);
void execute_stur(uint32_t instruction);
void execute_sturb(uint32_t instruction);
void execute_sturh(uint32_t instruction);
void execute_ldur(uint32_t instruction);
void execute_ldurh(uint32_t instruction);
void execute_mul(uint32_t instruction);
void execute_cbz(uint32_t instruction);
void execute_cbnz(uint32_t instruction);
void execute_hlt(uint32_t instruction);
void execute_add_imm(uint32_t instruction);
void execute_add_extended(uint32_t instruction);
void execute_ldurb(uint32_t instruction);

// Tabla de identificacion de instrucciones
Instruction instruction_table[] = {
    {OPCODE_ADDS_IMM, 8, "ADDS_IMM", execute_adds_imm},
    {OPCODE_ADDS_EXT, 11, "ADDS_EXT", execute_adds_ext},
    {OPCODE_SUBS_IMM, 11, "SUBS_IMM", execute_subs_imm},
    {OPCODE_SUBS_EXT, 11, "SUBS_EXT", execute_subs_ext},
    {OPCODE_CMP_EXT,11, "CMP_EXT", execute_cmp_ext},
    {OPCODE_CMP_IMM, 11, "CMP_IMM", execute_cmp_imm},
    {OPCODE_ANDS_SHIFTED, 8, "ANDS_SHIFTED", execute_ands_shifted},
    {OPCODE_MOVZ, 9, "MOVZ", execute_movz},
    {OPCODE_B, 6, "B", execute_b},
    {OPCODE_BR, 11, "BR", execute_br},
    {OPCODE_BEQ, 8, "BEQ", execute_conditional_branch},
    {OPCODE_BNE, 8, "BNE", execute_conditional_branch},
    {OPCODE_BGT, 8, "BGT", execute_conditional_branch},
    {OPCODE_BLT, 8, "BLT", execute_conditional_branch},
    {OPCODE_BGE, 8, "BGE", execute_conditional_branch},
    {OPCODE_BLE, 8, "BLE", execute_conditional_branch},
    {OPCODE_LOG_SHIFT, 10,"LOG_SHIFT", execute_logical_shift},
    {OPCODE_EOR, 11, "EOR", execute_eor},
    {OPCODE_ORR, 11, "ORR", execute_orr},
    {OPCODE_STUR, 11,"STUR", execute_stur},
    {OPCODE_STURB, 11, "STURB", execute_sturb},
    {OPCODE_STURH,11, "STURH", execute_sturh},
    {OPCODE_LDUR, 11,"LDUR", execute_ldur},
    {OPCODE_LDURH, 11,"LDURH", execute_ldurh},
    {OPCODE_MUL, 11, "MUL", execute_mul},
    {OPCODE_CBZ, 8, "CBZ", execute_cbz},
    {OPCODE_CBNZ, 8, "CBNZ", execute_cbnz},
    {OPCODE_HLT, 11, "HLT", execute_hlt},
    {OPCODE_ADD_EXTENDED, 11, "ADD_EXTENDED", execute_add_extended},
    {OPCODE_ADD_IMM, 8, "ADD_IMM", execute_add_imm},
    {OPCODE_LDURB, 11, "LDURB", execute_ldurb},
};

void process_instruction()
{
    uint32_t instruction = mem_read_32(CURRENT_STATE.PC);

    int i;
    int matched = 0;
    uint32_t extracted_opcode = 0;
    
    for (i = 0; i < NUM_INSTRUCTIONS; i++) {
        uint32_t code = instruction_table[i].opcode;
        int len_opcode = instruction_table[i].opcode_len;

        switch (len_opcode) {
            case 11:
                extracted_opcode = (instruction >> 21) & 0x7FF;  // 11 bits
                break;
            case 10:
                extracted_opcode = (instruction >> 22) & 0x3FF;  // 10 bits
                break;
            case 9:
                extracted_opcode = (instruction >> 23) & 0x1FF;  // 9 bits
                break;
            case 8:
                extracted_opcode = (instruction >> 24) & 0xFF;   // 8 bits
                break;
            default:
                continue;
        }

        if (extracted_opcode == instruction_table[i].opcode) {
            instruction_table[i].execute(instruction);
            matched = 1;
            break;
        }
    }
    if (!matched) {
        RUN_BIT = 0;  
    }
    if (matched && RUN_BIT && NEXT_STATE.PC == CURRENT_STATE.PC) {
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
    }
    
}

void execute_hlt(uint32_t instruction){
    printf("Instrucción HLT detectada. Fin de la simulación\n");
    RUN_BIT = 0;
}

void execute_adds_imm(uint32_t instruction) {
    uint8_t rd = instruction & 0x1F;        
    uint8_t rn = (instruction >> 5) & 0x1F; 
    uint32_t imm12 = (instruction >> 10) & 0xFFF; 
    uint32_t shift = (instruction >> 22) & 0x3; 
    uint64_t operando = imm12;
    if (shift == 1) operando <<= 12; 
    NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rn] + operando;

    NEXT_STATE.FLAG_N = (NEXT_STATE.REGS[rd] >> 63) & 1;
    NEXT_STATE.FLAG_Z = (NEXT_STATE.REGS[rd] == 0)?1:0;
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_adds_ext(uint32_t instruction) { 
    uint8_t rd = instruction & 0x1F;        
    uint8_t rn = (instruction >> 5) & 0x1F;
    uint8_t imm3 = (instruction >> 10) & 0b111;
    uint8_t option = (instruction >> 13) & 0b111;
    uint8_t rm = (instruction >> 16) & 0x1F;
    NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rn] + CURRENT_STATE.REGS[rm];

    NEXT_STATE.FLAG_N = (NEXT_STATE.REGS[rd] < 0);
    NEXT_STATE.FLAG_Z = (NEXT_STATE.REGS[rd] == 0);
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}


void execute_subs_imm(uint32_t instruction) {
    uint32_t rd = instruction & 0x1F;             
    uint32_t rn = (instruction >> 5) & 0x1F;        
    uint32_t imm12 = (instruction >> 10) & 0xFFF;   
    uint64_t operando = imm12;

    uint32_t shift = (instruction >> 22) & 0x3;
    if (shift == 1) operando <<= 12;

    int64_t result = (int64_t)CURRENT_STATE.REGS[rn] - (int64_t)operando;

    NEXT_STATE.REGS[rd] = result;
    NEXT_STATE.FLAG_N = (result < 0) ? 1 : 0;
    NEXT_STATE.FLAG_Z = (result == 0) ? 1 : 0;

    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_subs_ext(uint32_t instruction) {
    uint32_t rd = instruction & 0x1F;
    uint32_t rn = (instruction >> 5) & 0x1F;
    uint32_t rm = (instruction >> 16) & 0x1F;
    uint64_t result = (int64_t)CURRENT_STATE.REGS[rn] - (int64_t)CURRENT_STATE.REGS[rm];

    if (rd != 31) NEXT_STATE.REGS[rd] = result;

    NEXT_STATE.FLAG_N = (result >> 63) & 1; 
    NEXT_STATE.FLAG_Z = (result == 0) ? 1 : 0;
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_cmp_ext(uint32_t instruction) {
    uint32_t rn = (instruction >> 5) & 0x1F; 
    uint32_t rm = (instruction >> 16) & 0x1F; 
    uint64_t result = CURRENT_STATE.REGS[rn] - CURRENT_STATE.REGS[rm];

    NEXT_STATE.FLAG_N = (result >> 63) & 1; 
    NEXT_STATE.FLAG_Z = (result == 0) ? 1 : 0; 
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_cmp_imm(uint32_t instruction) {
    uint32_t rn = (instruction >> 5) & 0x1F;
    uint32_t imm12 = (instruction >> 10) & 0xFFF;
    uint64_t result = CURRENT_STATE.REGS[rn] - (int64_t)imm12;
    
    NEXT_STATE.FLAG_N = (result < 0);
    NEXT_STATE.FLAG_Z = (result == 0);
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_ands_shifted(uint32_t instruction) {
    uint32_t rd = instruction & 0x1F;
    uint32_t rn = (instruction >> 5) & 0x1F;
    uint32_t rm = (instruction >> 16) & 0x1F;
    uint64_t result = CURRENT_STATE.REGS[rn] & CURRENT_STATE.REGS[rm];

    NEXT_STATE.REGS[rd] = result;
    NEXT_STATE.FLAG_N = (result >> 63) & 1;
    NEXT_STATE.FLAG_Z = (result == 0);
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_movz(uint32_t instruction) {
    uint32_t rd = instruction & 0x1F;
    uint64_t imm16 = (instruction >> 5) & 0xFFFF;
    uint32_t hw = (instruction >> 21) & 0x3;
    uint64_t shift_amount = hw * 16;

    NEXT_STATE.REGS[rd] = imm16 << shift_amount;
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_b(uint32_t instruction) {
    int32_t imm26 = (instruction & 0x3FFFFFF);
    if (imm26 & 0x2000000) {
        imm26 |= 0xFC000000;
    }
    imm26 <<= 2;
    NEXT_STATE.PC = CURRENT_STATE.PC + imm26;
}

void execute_br(uint32_t instruction) {
    uint32_t rn = (instruction >> 5) & 0x1F;
    NEXT_STATE.PC = CURRENT_STATE.REGS[rn];
}

void execute_conditional_branch(uint32_t instruction) {
    uint32_t cond = instruction & 0b1111; 
    int32_t imm19 = (instruction >> 5) & 0x7FFFF;
    
    if (imm19 & 0x40000) {
        imm19 |= 0xFFF80000;
    }
    imm19 <<= 2;

    switch (cond) {
        case 0b0000:  // BEQ
            if (CURRENT_STATE.FLAG_Z == 1) {
                NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
                return;
            }
            break;
    
        case 0b0001:  // BNE
            if (CURRENT_STATE.FLAG_Z == 0) NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
            break;
    
        case 0b1010:  // BGE
            if (CURRENT_STATE.FLAG_N == CURRENT_STATE.FLAG_Z) NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
            break;
    
        case 0b1011:  // BLT
            if (CURRENT_STATE.FLAG_N == 1 && CURRENT_STATE.FLAG_Z == 0) {
                NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
            } else {
                NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            }
            break;
    
        case 0b1100:  // BGT 
            if (CURRENT_STATE.FLAG_N == 0 && CURRENT_STATE.FLAG_Z == 0) NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
            break;
    
        case 0b1101:  // BLE
            if (CURRENT_STATE.FLAG_Z == 1 || CURRENT_STATE.FLAG_N == 1) NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
            break;
    
        default:
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
    }
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_logical_shift(uint32_t instruction) {
    uint32_t rd = instruction & 0b11111;  
    uint32_t rn = (instruction >> 5) & 0b11111;
    uint32_t Imms = (instruction >> 10) & 0b111111;  
    uint32_t Immr = (instruction >> 16) & 0b111111; 

    uint64_t Rn = CURRENT_STATE.REGS[rn]; 
    uint64_t new_val;

    if (Imms != 0b111111) {
        // LSL
        if ((64 - Immr) < 64) {
            new_val = Rn << (64 - Immr); 
        } else {
            new_val = 0;
        }
    } else {
        // LSR
        if (Immr < 64) {
            new_val = Rn >> Immr;
        } else {
            new_val = 0;
        }
    }

    if (rd == 0b11111) {
        return;
    } else {
        NEXT_STATE.REGS[rd] = new_val;
    }

    NEXT_STATE.PC = CURRENT_STATE.PC + 4;

}


void execute_eor(uint32_t instruction) {
    uint32_t rd = (instruction & 0b00000000000000000000000000011111);
    uint32_t rn = (instruction & 0b00000000000000000000001111100000) >> 5;
    uint32_t rm = (instruction & 0b00000000000111110000000000000000) >> 16;

    int64_t Rn = CURRENT_STATE.REGS[rn];
    int64_t Rm = CURRENT_STATE.REGS[rm];
    int64_t new_val = Rn ^ Rm;

    if (rd != 31) {  
        NEXT_STATE.REGS[rd] = new_val;
    }
}

void execute_sturb(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    int32_t imm9 = (instruction >> 12) & 0x1FF;

    uint64_t address = CURRENT_STATE.REGS[rn] + imm9;
    uint8_t value = CURRENT_STATE.REGS[rt] & 0xFF;

    mem_write_8(address, value);
}

void execute_sturh(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    int32_t imm9 = (instruction >> 12) & 0x1FF;

    uint64_t address = CURRENT_STATE.REGS[rn] + imm9;
    uint16_t value = CURRENT_STATE.REGS[rt] & 0xFFFF;

    mem_write_16(address, value); 
}

void execute_ldur(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    int32_t imm9 = (instruction >> 12) & 0x1FF;

    uint64_t address = CURRENT_STATE.REGS[rn] + imm9;
    NEXT_STATE.REGS[rt] = mem_read_64(address);
}

void execute_ldurh(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    int32_t imm9 = (instruction >> 12) & 0x1FF;

    uint64_t address = CURRENT_STATE.REGS[rn] + imm9;
    NEXT_STATE.REGS[rt] = mem_read_16(address);
}

void execute_ldurb(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    int32_t imm9 = (instruction >> 12) & 0x1FF;

    if (imm9 & 0x100) { 
        imm9 |= 0xFFFFFE00;
    }

    uint64_t address = CURRENT_STATE.REGS[rn] + imm9;
    NEXT_STATE.REGS[rt] = mem_read_8(address);
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_mul(uint32_t instruction) {
    uint8_t rd = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    uint8_t rm = (instruction >> 16) & 0x1F;

    NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rn] * CURRENT_STATE.REGS[rm];
    NEXT_STATE.FLAG_N = (NEXT_STATE.REGS[rd] < 0);
    NEXT_STATE.FLAG_Z = (NEXT_STATE.REGS[rd] == 0);
}

void execute_cbz(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    int32_t imm19 = (instruction >> 5) & 0x7FFFF;
    
    if (imm19 & 0x40000) {
        imm19 = imm19 - (1 << 19);
    }
    imm19 <<= 2;

    if (CURRENT_STATE.REGS[rt] == 0) {
        NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
    }
}

void execute_cbnz(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;
    int32_t imm19 = (instruction >> 5) & 0x7FFFF;

    if (imm19 & 0x40000) {
        imm19 = imm19 - (1 << 19);
    }
    imm19 <<= 2;

    if (CURRENT_STATE.REGS[rt] != 0) {
        NEXT_STATE.PC = CURRENT_STATE.PC + imm19;
    }
}

void execute_stur(uint32_t instruction) {
    uint8_t rt = instruction & 0x1F;    
    uint8_t rn = (instruction >> 5) & 0x1F;
    int32_t imm9 = (instruction >> 12) & 0x1FF; 

    uint64_t address = CURRENT_STATE.REGS[rn] + imm9;
    uint64_t value = CURRENT_STATE.REGS[rt];

    mem_write_64(address, value);
}
void execute_orr(uint32_t instruction){
    uint8_t rd = instruction & 0x1F;
    uint8_t rn = (instruction >> 5) & 0x1F;
    uint8_t imm6 = (instruction >> 10) & 0b111111;
    uint32_t rm = (instruction >> 16) & 0x1F;
    uint64_t operand = CURRENT_STATE.REGS[rm];

    NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rn] | operand;
    NEXT_STATE.FLAG_N = (NEXT_STATE.REGS[rd] < 0);
    NEXT_STATE.FLAG_Z = (NEXT_STATE.REGS[rd] == 0);
    NEXT_STATE.PC = CURRENT_STATE.PC + 4;
}

void execute_add_imm(uint32_t instruction){
    uint8_t rd = instruction & 0x1F;
    uint8_t rn = (instruction>>5) & 0x1F;
    uint32_t imm12 = (instruction>>10) & 0b11111111111;
    uint8_t shift = (instruction >>22) & 0b11;

    uint64_t value;
    if (shift == 01){
        imm12 <<= 12;
    }

    NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rn] + imm12;
    NEXT_STATE.FLAG_N = (NEXT_STATE.REGS[rd] < 0);
    NEXT_STATE.FLAG_Z = (NEXT_STATE.REGS[rd] == 0);
}

void execute_add_extended(uint32_t instruction){
    uint8_t rd = instruction & 0x1F;
    uint8_t rn = (instruction>>5) & 0x1F;
    uint8_t imm3 = (instruction >>10) & 0b111;
    uint8_t option = (instruction >>13) & 0b111;
    uint8_t rm = (instruction>>16) & 0x1F;

    uint64_t operand = CURRENT_STATE.REGS[rm];
    operand <<= imm3;
    uint64_t result = CURRENT_STATE.REGS[rn] + operand;
    NEXT_STATE.REGS[rd] = result;

    NEXT_STATE.FLAG_N = (NEXT_STATE.REGS[rd] < 0);
    NEXT_STATE.FLAG_Z = (NEXT_STATE.REGS[rd] == 0);
}
>>>>>>> Stashed changes
