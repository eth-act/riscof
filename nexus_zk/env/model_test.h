#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_signature; begin_signature:             \
        .align 8; .global end_signature; end_signature:

//RV_COMPLIANCE_HALT
#define RVMODEL_HALT                                                    \
        li gp, 1;                                                       \
        sw gp, tohost, t5;                                              \
        fence;                                                          \
        li t6, 0x1;                                                     \
    1:  beq gp, t6, 1b;

//RV_COMPLIANCE_DATA_BEGIN
#define RVMODEL_DATA_BEGIN                                              \
        RVMODEL_DATA_SECTION                                            \

//RV_COMPLIANCE_DATA_END
#define RVMODEL_DATA_END

//RVTEST_IO_INIT
#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()
//RVTEST_IO_ASSERT_GPR_EQ
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

// Convenience macros to specify an instruction fence
// Depending on the platform this can be a memory fence
// This could also expand to a config load
//RVTEST_MEM_FENCE()
#define RVMODEL_FENCE                          \
        fence;                               

#define RVMODEL_BOOT

#endif // _COMPLIANCE_MODEL_H 