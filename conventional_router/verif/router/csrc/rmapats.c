#include <stdio.h>
#include <stdlib.h>
#include "rmapats.h"

typedef unsigned char UB;
typedef unsigned char scalar;
typedef unsigned short US;
#ifndef __DO_RMAHDR_
typedef unsigned int U;
#endif
#if defined(__sparcv9) || defined(__LP64__) || defined(_LP64) || defined(__ia64)
typedef unsigned long UP;
typedef unsigned long RP;
#else
typedef unsigned int UP;
typedef unsigned int RP;
#endif
typedef void (*FP)(void *, scalar);
typedef void (*FPV)(void *, UB*);
typedef void (*FP1)(void *);
typedef void (*FPLSEL)(void *, scalar, U);
typedef void (*FPLSEL_CBITS)(void *, scalar, U, U cbits);
typedef void (*FPLSELV)(void *, vec32*, U, U);
typedef void (*FPLSELV_CBITS)(void *, vec32*, U, U, U cbits);

#ifdef __cplusplus
  extern "C" {
#endif

#if (_MSC_VER >= 900)
#define RMA_UL unsigned __int64
#else
#define RMA_UL long long unsigned
#endif
typedef union {
    double dummy;
#if defined(__GNUC__) || defined(__STDC__) || defined(__alpha) ||  \
    defined(_AIX) || (_MSC_VER >= 900) || defined(__sony_news) || defined(__cplusplus)
    RMA_UL clockL;
#endif
    unsigned int  clock_hl[2];
} rma_clock_struct;

typedef struct {
        RP pnext;
}RmaDbsLoad;

#define RmaTcCoreCommon   \
                RP pts;   \
                RP pdata; \
                U limit:30, \
                  floaded:1, \
                  fskew:1 

typedef struct {
        RP pnext;
        RmaTcCoreCommon;
}RmaTcCoreSimple;

typedef struct {
        RP pnext;
        RmaTcCoreCommon;
        RP ptscond;
}RmaTcCoreConditional;

typedef struct {
        RmaTcCoreCommon;
}RmaTcCoreSimpleNoList;

typedef struct { 
        RmaTcCoreCommon;
        RP ptscond;
}RmaTcCoreConditionalNoList;

#define RmaTSLoadCommon \
        RP pcondval; \
        U tscond;    \
        scalar condval

typedef struct {
        RmaTSLoadCommon;
}RmaConditionalTSLoadNoList;

typedef struct {
        RP pnext;
        RmaTSLoadCommon;
}RmaConditionalTSLoad;

typedef struct { 
        void* daiCbkList;
        void* aliasIp;
        U     aliasQsymId;
 } RmaDaiCg;

typedef struct { 
        void* vecCbkList;
 } RmaRootCbkCg;

typedef struct { 
        U vrpId;
 } RmaRootVcdCg;

typedef struct { 
        RP forceCbkList;
 } RmaRootForceCbkCg;

extern scalar Xunion[], Xwor[], Xwand[], Xvalchg[];
extern scalar X3val[], X4val[], XcvtstrTR[], Xbuf[], Xbitnot[],Xwor[], Xwand[];
extern scalar globalTable1Input[];
extern RP rmaSchedFunctionArr[];
extern unsigned long long vcs_clocks;
extern UB gHsimDumpScalVal;
extern UB gHsimPliScalVal;
extern U fCallbackHsimNode;
extern U fVcdDumpHsimNode;
extern U fVpdDumpHsimNode;
extern U fRTFrcRelCbk;
extern UB* rmaEvalDelays(UB* pcode, scalar val);
extern void rmaPopTransEvent(UB* pcode);
extern void (*txpFnPtr)(UB* pcode, U);
extern void rmaSetupFuncArray(UP* ra);
extern void SinitHsimPats(void);
extern void VVrpDaicb(void* ip, U nIndex);
extern int SDaicb(void *ip, U nIndex);
extern void SDaicbForHsimNoFlagScalar(void* pDaiCb, unsigned char value);
extern void SDaicbForHsimNoFlagStrengthScalar(void* pDaiCb, unsigned char value);
extern void SDaicbForHsimNoFlag(void* pRmaDaiCg, unsigned char value);
extern void SDaicbForHsimNoFlag2(void* pRmaDaiCg, unsigned char value);
extern void SDaicbForHsimWithFlag(void* pRmaDaiCg, unsigned char value);
extern void SDaicbForHsimNoFlagFrcRel(void* pRmaDaiCg, unsigned char reason, int msb, int lsb, int ndx);
extern void SDaicbForHsimNoFlagFrcRel2(void* pRmaDaiCg, unsigned char reason, int msb, int lsb, int ndx);
extern void VcsHsimValueChangeCB(void* pRmaDaiCg, void* pValue, unsigned int valueFormat);
extern U isNonDesignNodeCallbackList(void* pRmaDaiCg);
extern void SDaicbForHsimCbkMemOptNoFlagScalar(void* pDaiCb, unsigned char value, unsigned char isStrength);
extern void SDaicbForHsimCbkMemOptWithFlagScalar(void* pDaiCb, unsigned char value, unsigned char isStrength);
extern void SDaicbForHsimCbkMemOptNoFlagScalar(void* pDaiCb, unsigned char value, unsigned char isStrength);
extern void SDaicbForHsimCbkMemOptWithFlagScalar(void* pDaiCb, unsigned char value, unsigned char isStrength);
extern void VVrpNonEventNonRegdScalarForHsimOptCbkMemopt(void* ip, U nIndex);
extern void SDaicbForHsimCbkMemOptNoFlagDynElabScalar(U* mem, unsigned char value, unsigned char isStrength);
extern void SDaicbForHsimCbkMemOptWithFlagDynElabScalar(U* mem, unsigned char value, unsigned char isStrength);
extern void SDaicbForHsimCbkMemOptNoFlagDynElabFrcRel(U* mem, unsigned char reason, int msb, int lsb, int ndx);
extern void SDaicbForHsimCbkMemOptNoFlagFrcRel(void* pDaiCb, unsigned char reason, int msb, int lsb, int ndx);
extern void hsimDispatchCbkMemOptForVcd(RP p, U val);
extern void* hsimGetCbkMemOptCallback(RP p);
extern void hsimDispatchCbkMemOptNoDynElabS(RP p, U val, U isStrength);
extern void hsimDispatchCbkMemOptDynElabS(U** pvcdarr, U** pcbkarr, U val, U isStrength);
extern void hsimDispatchCbkMemOptNoDynElabVector(RP /*RmaDaiOptCg* */p, void* pval, U /*RmaValueType*/ vt, U cbits);
extern void copyAndPropRootCbkCg(RmaRootCbkCg* pRootCbk, scalar val);
extern void dumpRootVcdCg(RmaRootVcdCg* pRootVcd, scalar val);
extern void (*rmaPostAnySchedFnPtr)(EBLK* peblk);
extern void SchedSemiLerMP1(UB* pmps, U partId);
extern void hsUpdateModpathTimeStamp(UB* pmps);
extern void doMpd32One(UB* pmps);
extern void SchedSemiLerMP(UB* ppulse, U partId);
extern void scheduleuna(UB *e, U t);
extern void scheduleuna_mp(EBLK *e, unsigned t);
extern void schedule(UB *e, U t);
extern void sched_hsopt(struct dummyq_struct * pQ, EBLK *e, U t);
extern void sched_millenium(struct dummyq_struct * pQ, EBLK *e, U thigh, U t);
extern void schedule_1(EBLK *e);
extern void sched0(UB *e);
extern void sched0lq(UB *e);
extern void sched0una(UB *e);
extern void sched0una_th(struct dummyq_struct *pq, UB *e);
extern void scheduleuna_mp_th(struct dummyq_struct *pq, EBLK *e, unsigned t);
extern void schedal(UB *e);
extern void sched0_th(struct dummyq_struct * pQ, UB *e);
extern void sched0_hsim_front_th(struct dummyq_struct * pQ, UB *e);
extern void sched0_hsim_frontlq_th(struct dummyq_struct * pQ, UB *e);
extern void sched0lq_th(struct dummyq_struct * pQ, UB *e);
extern void schedal_th(struct dummyq_struct * pQ, UB *e);
extern void scheduleuna_th(struct dummyq_struct * pQ, UB *e, U t);
extern void schedule_th(struct dummyq_struct * pQ, UB *e, U t);
extern void schedule_1_th(struct dummyq_struct * pQ, EBLK *peblk);
extern U getVcdFlags(UB *ip);
extern void VVrpNonEventNonRegdScalarForHsimOpt(void* ip, U nIndex);
extern void VVrpNonEventNonRegdScalarForHsimOpt2(void* ip, U nIndex);
extern void SchedSemiLerTBReactiveRegion(struct eblk* peblk);
extern void SchedSemiLerTBReactiveRegion_th(struct eblk* peblk, U partId);
extern void SchedSemiLerTr(UB* peblk, U partId);
extern void appendNtcEvent(UB* phdr, scalar s, U schedDelta);
extern void hsimRegisterEdge(void* sm,  scalar s);
extern U pvcsGetPartId();
extern void HsimPVCSPartIdCheck(U instNo);
extern void debug_func(U partId, struct dummyq_struct* pQ, EBLK* EblkLastEventx); 
extern struct dummyq_struct* pvcsGetQ(U thid);
extern EBLK* pvcsGetLastEventEblk(U thid);
extern void insertTransEvent(RmaTransEventHdr* phdr, scalar s, scalar pv,	scalar resval, U schedDelta, int re, UB* predd, U fpdd);
extern void insertNtcEventRF(RmaTransEventHdr* phdr, scalar s, scalar pv, scalar resval, U schedDelta, U* delays);
extern U doTimingViolation(U ts,RP* pdata, U fskew, U limit, U floaded);
extern int getCurSchedRegion();
extern FP getRoutPtr(RP, U);
extern U rmaChangeCheckAndUpdateE(scalar* pvalDst, scalar* pvalSrc, U cbits);
extern void rmaUpdateE(scalar* pvalDst, scalar* pvalSrc, U cbits);
extern void rmaLhsPartSelUpdateE(scalar* pvalDst, scalar* pvalSrc, U index, U width);
extern void rmaUpdateWithForceSelectorE(scalar* pvalDst, scalar* pvalSrc, U cbits, U* pforceSelector);
extern void rmaUpdateWFromE(vec32* pvalDst, scalar* pvalSrc, U cbits);
extern U rmaLhsPartSelWithChangeCheckE(scalar* pvalDst, scalar* pvalSrc, U index, U width);
extern void rmaLhsPartSelWFromE(vec32* pvalDst, scalar* pvalSrc, U index,U width);
extern U rmaChangeCheckAndUpdateW(vec32* pvalDst, vec32* pvalSrc, U cbits);
extern void rmaUpdateW(vec32* pvalDst, vec32* pvalSrc, U cbits);
extern void rmaUpdateEFromW(scalar* pvalDst, vec32* pvalSrc, U cbits);
extern U rmaLhsPartSelWithChangeCheckW(vec32* pvalDst, vec32* pvalSrc, U index,U width);
extern void rmaLhsPartSelEFromW(scalar* pvalDst, vec32* pvalSrc, U index,U width);
extern void rmaLhsPartSelUpdateW(vec32* pvalDst, vec32* pvalSrc, U index, U width);
extern void rmaEvalWunionW(vec32* dst, vec32* src, U cbits, U count);
extern void rmaEvalWorW(vec32* dst, vec32* src, U cbits, U count);
extern void rmaEvalWandW(vec32* dst, vec32* src, U cbits, U count);
extern void rmaEvalUnionE(scalar* dst, scalar* src, U cbits, U count, scalar* ptable);
extern RmaIbfPcode* rmaEvalPartSelectsW(vec32* pvec32, U startIndex, U onWidth, U offWidth, U count, RmaIbfPcode* pibfPcode);
extern RmaIbfPcode* rmaEvalPartSelectsEToE(scalar* pv, U startIndex, U onWidth, U offWidth, U count, RmaIbfPcode* pibfPcode);
extern RmaIbfPcode* rmaEvalPartSelectsEToW(scalar* pv, U startIndex, U onWidth, U offWidth, U count, RmaIbfPcode* pibfPcode);
extern U VcsForceVecVCg(UB* pcode, UB* pval, UB* pvDst, UB* pvCur, U fullcbits, U ibeginSrc, U ibeginDst, U width, U/*RmaValueConvType*/ convtype, U/*RmaForceType*/ frcType, UB* prhs, UB* prhsDst, U frhs, U* pforcedbits, U fisRoot);
extern U VcsReleaseVecVCg(UB* pcode, UB* pvDst, U fullcbits, U ibeginDst, U width, UB* prhsDst, U frhs, U* pforcedbits, U fisRoot);
extern U VcsDriveBitsAndDoChangeCheckV(vec32* pvSel, vec32* pvCur, U fullcbits, U forcedbits, U isRoot);
extern void cgvecDebug_Eblk(UB* pcode);
#ifdef __cplusplus
  }
#endif
scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarHasChanged=0;
extern int curSchedRegion;
extern RP* iparr;
extern int fNotimingchecks;
typedef struct red_t {
	U reject;
	U error;
	U delay;
} RED;
typedef struct predd {
	U type;
	RED delays[1];
} PREDD;
#define HASH_BIT 0xfff
#define TransStE 255

#ifdef __cplusplus
extern "C" {
#endif
void  rmaPropagate0(UB  * pcode, scalar  val);
void  rmaPropagate0f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate0r(UB  * pcode);
void  rmaPropagate1(UB  * pcode, scalar  val);
void  rmaPropagate16(UB  * pcode, scalar  val);
void  rmaPropagate16f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate16r(UB  * pcode);
void  rmaPropagate28(UB  * pcode, scalar  val);
void  rmaPropagate28f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate28r(UB  * pcode);
void  rmaPropagate28t0(UB  * pcode, UB  val);
void  rmaPropagate29(UB  * pcode, scalar  val);
void  rmaPropagate29f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate29r(UB  * pcode);
void  rmaPropagate29t0(UB  * pcode, UB  val);
void  rmaPropagate30(UB  * pcode, scalar  val);
void  rmaPropagate30f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate30r(UB  * pcode);
void  rmaPropagate33(UB  * pcode, scalar  val);
void  rmaPropagate33f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate33r(UB  * pcode);
void  rmaPropagate33t0(UB  * pcode, UB  val);
void  rmaPropagate34(UB  * pcode, scalar  val);
void  rmaPropagate34f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate34r(UB  * pcode);
void  rmaPropagate35(UB  * pcode, scalar  val);
void  rmaPropagate35f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate35r(UB  * pcode);
void  rmaPropagate37(UB  * pcode, scalar  val);
void  rmaPropagate37f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate37r(UB  * pcode);
void  rmaPropagate38(UB  * pcode, scalar  val);
void  rmaPropagate38f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate38r(UB  * pcode);
void  rmaPropagate65(UB  * pcode, scalar  val);
void  rmaPropagate65f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate65r(UB  * pcode);
void  rmaPropagate66(UB  * pcode, scalar  val);
void  rmaPropagate66f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate66r(UB  * pcode);
void  rmaPropagate66t0(UB  * pcode, UB  val);
void  rmaPropagate67(UB  * pcode, scalar  val);
void  rmaPropagate67f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate67r(UB  * pcode);
void  rmaPropagate69(UB  * pcode, scalar  val);
void  rmaPropagate69f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate69r(UB  * pcode);
void  rmaPropagate72(UB  * pcode, scalar  val);
void  rmaPropagate72f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate72r(UB  * pcode);
void  rmaPropagate73(UB  * pcode, scalar  val);
void  rmaPropagate73f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate73r(UB  * pcode);
void  rmaPropagate74(UB  * pcode, scalar  val);
void  rmaPropagate74f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate74r(UB  * pcode);
void  rmaPropagate74t0(UB  * pcode, UB  val);
void  rmaPropagate75(UB  * pcode, scalar  val);
void  rmaPropagate75f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate75r(UB  * pcode);
void  rmaPropagate75t0(UB  * pcode, UB  val);
void  rmaPropagate83(UB  * pcode, scalar  val);
void  rmaPropagate83f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate83r(UB  * pcode);
void  rmaPropagate84(UB  * pcode, scalar  val);
void  rmaPropagate84f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate84r(UB  * pcode);
void  rmaPropagate85(UB  * pcode, scalar  val);
void  rmaPropagate85f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate85r(UB  * pcode);
void  rmaPropagate87(UB  * pcode, scalar  val);
void  rmaPropagate87f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate87r(UB  * pcode);
void  rmaPropagate88(UB  * pcode, scalar  val);
void  rmaPropagate88f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate88r(UB  * pcode);
void  rmaPropagate88t0(UB  * pcode, UB  val);
void  rmaPropagate89(UB  * pcode, scalar  val);
void  rmaPropagate89f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate89r(UB  * pcode);
void  rmaPropagate91(UB  * pcode, scalar  val);
void  rmaPropagate91f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate91r(UB  * pcode);
void  rmaPropagate92(UB  * pcode, scalar  val);
void  rmaPropagate92f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate92r(UB  * pcode);
void  rmaPropagate93(UB  * pcode, scalar  val);
void  rmaPropagate93f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate93r(UB  * pcode);
void  schedNewEvent(struct dummyq_struct * pQ, EBLK  * peblk, U  delay);
#ifdef __cplusplus
}
#endif
void  schedNewEvent(struct dummyq_struct * pQ, EBLK  * peblk, U  delay);
void  schedNewEvent(struct dummyq_struct * pQ, EBLK  * peblk, U  delay)
{
    U  abs_t;
    U  thigh_abs;
    U  hash_index;
    struct futq * pfutq;
    abs_t = ((U )vcs_clocks) + delay;
    hash_index = abs_t & 0xfff;
    peblk->peblkFlink = (EBLK  *)(-1);
    peblk->t = abs_t;
    if (abs_t < (U )vcs_clocks) {
        thigh_abs = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, peblk, thigh_abs + 1, abs_t);
    }
    else if ((pfutq = pQ->hashtab[hash_index].tfutq)) {
        peblk->peblkPrv = pfutq->peblkTail;
        pfutq->peblkTail->peblkFlink = peblk;
        pfutq->peblkTail = peblk;
    }
    else {
        sched_hsopt(pQ, peblk, abs_t);
    }
}
FP rmaFunctionArray[] = {
	(FP) rmaPropagate0,
	(FP) rmaPropagate0f,
	(FP) rmaPropagate0r,
	(FP) rmaPropagate1,
	(FP) rmaPropagate16,
	(FP) rmaPropagate16f,
	(FP) rmaPropagate16r,
	(FP) rmaPropagate28,
	(FP) rmaPropagate28f,
	(FP) rmaPropagate28r,
	(FP) rmaPropagate28t0,
	(FP) rmaPropagate29,
	(FP) rmaPropagate29f,
	(FP) rmaPropagate29r,
	(FP) rmaPropagate29t0,
	(FP) rmaPropagate30,
	(FP) rmaPropagate30f,
	(FP) rmaPropagate30r,
	(FP) rmaPropagate33,
	(FP) rmaPropagate33f,
	(FP) rmaPropagate33r,
	(FP) rmaPropagate33t0,
	(FP) rmaPropagate34,
	(FP) rmaPropagate34f,
	(FP) rmaPropagate34r,
	(FP) rmaPropagate35,
	(FP) rmaPropagate35f,
	(FP) rmaPropagate35r,
	(FP) rmaPropagate37,
	(FP) rmaPropagate37f,
	(FP) rmaPropagate37r,
	(FP) rmaPropagate38,
	(FP) rmaPropagate38f,
	(FP) rmaPropagate38r,
	(FP) rmaPropagate65,
	(FP) rmaPropagate65f,
	(FP) rmaPropagate65r,
	(FP) rmaPropagate66,
	(FP) rmaPropagate66f,
	(FP) rmaPropagate66r,
	(FP) rmaPropagate66t0,
	(FP) rmaPropagate67,
	(FP) rmaPropagate67f,
	(FP) rmaPropagate67r,
	(FP) rmaPropagate69,
	(FP) rmaPropagate69f,
	(FP) rmaPropagate69r,
	(FP) rmaPropagate72,
	(FP) rmaPropagate72f,
	(FP) rmaPropagate72r,
	(FP) rmaPropagate73,
	(FP) rmaPropagate73f,
	(FP) rmaPropagate73r,
	(FP) rmaPropagate74,
	(FP) rmaPropagate74f,
	(FP) rmaPropagate74r,
	(FP) rmaPropagate74t0,
	(FP) rmaPropagate75,
	(FP) rmaPropagate75f,
	(FP) rmaPropagate75r,
	(FP) rmaPropagate75t0,
	(FP) rmaPropagate83,
	(FP) rmaPropagate83f,
	(FP) rmaPropagate83r,
	(FP) rmaPropagate84,
	(FP) rmaPropagate84f,
	(FP) rmaPropagate84r,
	(FP) rmaPropagate85,
	(FP) rmaPropagate85f,
	(FP) rmaPropagate85r,
	(FP) rmaPropagate87,
	(FP) rmaPropagate87f,
	(FP) rmaPropagate87r,
	(FP) rmaPropagate88,
	(FP) rmaPropagate88f,
	(FP) rmaPropagate88r,
	(FP) rmaPropagate88t0,
	(FP) rmaPropagate89,
	(FP) rmaPropagate89f,
	(FP) rmaPropagate89r,
	(FP) rmaPropagate91,
	(FP) rmaPropagate91f,
	(FP) rmaPropagate91r,
	(FP) rmaPropagate92,
	(FP) rmaPropagate92f,
	(FP) rmaPropagate92r,
	(FP) rmaPropagate93,
	(FP) rmaPropagate93f,
	(FP) rmaPropagate93r
};

#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
