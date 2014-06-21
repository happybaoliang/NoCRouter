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
void  rmaPropagate4(UB  * pcode, scalar  val);
void  rmaPropagate13(UB  * pcode, scalar  val);
void  rmaPropagate13f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate13r(UB  * pcode);
void  rmaPropagate13t0(UB  * pcode, UB  val);
void  rmaPropagate14(UB  * pcode, scalar  val);
void  rmaPropagate14f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate14r(UB  * pcode);
void  rmaPropagate14t0(UB  * pcode, UB  val);
void  rmaPropagate15(UB  * pcode, scalar  val);
void  rmaPropagate15f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate15r(UB  * pcode);
void  rmaPropagate16(UB  * pcode, scalar  val);
void  rmaPropagate16f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate16r(UB  * pcode);
void  rmaPropagate31(UB  * pcode, scalar  val);
void  rmaPropagate31f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate31r(UB  * pcode);
void  rmaPropagate32(UB  * pcode, scalar  val);
void  rmaPropagate32f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate32r(UB  * pcode);
void  rmaPropagate33(UB  * pcode, scalar  val);
void  rmaPropagate33f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate33r(UB  * pcode);
void  rmaPropagate38(UB  * pcode, scalar  val);
void  rmaPropagate38f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate38r(UB  * pcode);
void  rmaPropagate39(UB  * pcode, scalar  val);
void  rmaPropagate39f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate39r(UB  * pcode);
void  rmaPropagate40(UB  * pcode, scalar  val);
void  rmaPropagate40f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate40r(UB  * pcode);
void  rmaPropagate41(UB  * pcode, scalar  val);
void  rmaPropagate41f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate41r(UB  * pcode);
void  rmaPropagate45(UB  * pcode, scalar  val);
void  rmaPropagate45f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate45r(UB  * pcode);
void  rmaPropagate45t0(UB  * pcode, UB  val);
void  rmaPropagate46(UB  * pcode, scalar  val);
void  rmaPropagate46f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate46r(UB  * pcode);
void  rmaPropagate46t0(UB  * pcode, UB  val);
void  rmaPropagate47(UB  * pcode, scalar  val);
void  rmaPropagate47f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate47r(UB  * pcode);
void  rmaPropagate48(UB  * pcode, scalar  val);
void  rmaPropagate48f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate48r(UB  * pcode);
void  rmaPropagate52(UB  * pcode, scalar  val);
void  rmaPropagate52f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate52r(UB  * pcode);
void  rmaPropagate52t0(UB  * pcode, UB  val);
void  rmaPropagate63(UB  * pcode, scalar  val);
void  rmaPropagate63f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate63r(UB  * pcode);
void  rmaPropagate64(UB  * pcode, scalar  val);
void  rmaPropagate64f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate64r(UB  * pcode);
void  rmaPropagate65(UB  * pcode, scalar  val);
void  rmaPropagate65f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate65r(UB  * pcode);
void  rmaPropagate66(UB  * pcode, scalar  val);
void  rmaPropagate66f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate66r(UB  * pcode);
void  rmaPropagate66t0(UB  * pcode, UB  val);
void  rmaPropagate79(UB  * pcode, scalar  val);
void  rmaPropagate79f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate79r(UB  * pcode);
void  rmaPropagate80(UB  * pcode, scalar  val);
void  rmaPropagate80f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate80r(UB  * pcode);
void  rmaPropagate86(UB  * pcode, scalar  val);
void  rmaPropagate86f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate86r(UB  * pcode);
void  rmaPropagate90(UB  * pcode, scalar  val);
void  rmaPropagate90f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate90r(UB  * pcode);
void  rmaPropagate93(UB  * pcode, scalar  val);
void  rmaPropagate124(UB  * pcode, scalar  val);
void  rmaPropagate124f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate124r(UB  * pcode);
void  rmaPropagate125(UB  * pcode, scalar  val);
void  rmaPropagate125f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate125r(UB  * pcode);
void  rmaPropagate130(UB  * pcode, scalar  val);
void  rmaPropagate130f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate130r(UB  * pcode);
void  rmaPropagate131(UB  * pcode, scalar  val);
void  rmaPropagate131f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate131r(UB  * pcode);
void  rmaPropagate132(UB  * pcode, scalar  val);
void  rmaPropagate132f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate132r(UB  * pcode);
void  rmaPropagate135(UB  * pcode, scalar  val);
void  rmaPropagate135f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate135r(UB  * pcode);
void  rmaPropagate139(UB  * pcode, scalar  val);
void  rmaPropagate140(UB  * pcode, scalar  val);
void  rmaPropagate142(UB  * pcode, scalar  val);
void  rmaPropagate153(UB  * pcode, scalar  val);
void  rmaPropagate153f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate153r(UB  * pcode);
void  rmaPropagate156(UB  * pcode, scalar  val);
void  rmaPropagate156f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate156r(UB  * pcode);
void  rmaPropagate157(UB  * pcode, scalar  val);
void  rmaPropagate157f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate157r(UB  * pcode);
void  rmaPropagate158(UB  * pcode, scalar  val);
void  rmaPropagate158f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate158r(UB  * pcode);
void  rmaPropagate158t0(UB  * pcode, UB  val);
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
	(FP) rmaPropagate4,
	(FP) rmaPropagate13,
	(FP) rmaPropagate13f,
	(FP) rmaPropagate13r,
	(FP) rmaPropagate13t0,
	(FP) rmaPropagate14,
	(FP) rmaPropagate14f,
	(FP) rmaPropagate14r,
	(FP) rmaPropagate14t0,
	(FP) rmaPropagate15,
	(FP) rmaPropagate15f,
	(FP) rmaPropagate15r,
	(FP) rmaPropagate16,
	(FP) rmaPropagate16f,
	(FP) rmaPropagate16r,
	(FP) rmaPropagate31,
	(FP) rmaPropagate31f,
	(FP) rmaPropagate31r,
	(FP) rmaPropagate32,
	(FP) rmaPropagate32f,
	(FP) rmaPropagate32r,
	(FP) rmaPropagate33,
	(FP) rmaPropagate33f,
	(FP) rmaPropagate33r,
	(FP) rmaPropagate38,
	(FP) rmaPropagate38f,
	(FP) rmaPropagate38r,
	(FP) rmaPropagate39,
	(FP) rmaPropagate39f,
	(FP) rmaPropagate39r,
	(FP) rmaPropagate40,
	(FP) rmaPropagate40f,
	(FP) rmaPropagate40r,
	(FP) rmaPropagate41,
	(FP) rmaPropagate41f,
	(FP) rmaPropagate41r,
	(FP) rmaPropagate45,
	(FP) rmaPropagate45f,
	(FP) rmaPropagate45r,
	(FP) rmaPropagate45t0,
	(FP) rmaPropagate46,
	(FP) rmaPropagate46f,
	(FP) rmaPropagate46r,
	(FP) rmaPropagate46t0,
	(FP) rmaPropagate47,
	(FP) rmaPropagate47f,
	(FP) rmaPropagate47r,
	(FP) rmaPropagate48,
	(FP) rmaPropagate48f,
	(FP) rmaPropagate48r,
	(FP) rmaPropagate52,
	(FP) rmaPropagate52f,
	(FP) rmaPropagate52r,
	(FP) rmaPropagate52t0,
	(FP) rmaPropagate63,
	(FP) rmaPropagate63f,
	(FP) rmaPropagate63r,
	(FP) rmaPropagate64,
	(FP) rmaPropagate64f,
	(FP) rmaPropagate64r,
	(FP) rmaPropagate65,
	(FP) rmaPropagate65f,
	(FP) rmaPropagate65r,
	(FP) rmaPropagate66,
	(FP) rmaPropagate66f,
	(FP) rmaPropagate66r,
	(FP) rmaPropagate66t0,
	(FP) rmaPropagate79,
	(FP) rmaPropagate79f,
	(FP) rmaPropagate79r,
	(FP) rmaPropagate80,
	(FP) rmaPropagate80f,
	(FP) rmaPropagate80r,
	(FP) rmaPropagate86,
	(FP) rmaPropagate86f,
	(FP) rmaPropagate86r,
	(FP) rmaPropagate90,
	(FP) rmaPropagate90f,
	(FP) rmaPropagate90r,
	(FP) rmaPropagate93,
	(FP) rmaPropagate124,
	(FP) rmaPropagate124f,
	(FP) rmaPropagate124r,
	(FP) rmaPropagate125,
	(FP) rmaPropagate125f,
	(FP) rmaPropagate125r,
	(FP) rmaPropagate130,
	(FP) rmaPropagate130f,
	(FP) rmaPropagate130r,
	(FP) rmaPropagate131,
	(FP) rmaPropagate131f,
	(FP) rmaPropagate131r,
	(FP) rmaPropagate132,
	(FP) rmaPropagate132f,
	(FP) rmaPropagate132r,
	(FP) rmaPropagate135,
	(FP) rmaPropagate135f,
	(FP) rmaPropagate135r,
	(FP) rmaPropagate139,
	(FP) rmaPropagate140,
	(FP) rmaPropagate142,
	(FP) rmaPropagate153,
	(FP) rmaPropagate153f,
	(FP) rmaPropagate153r,
	(FP) rmaPropagate156,
	(FP) rmaPropagate156f,
	(FP) rmaPropagate156r,
	(FP) rmaPropagate157,
	(FP) rmaPropagate157f,
	(FP) rmaPropagate157r,
	(FP) rmaPropagate158,
	(FP) rmaPropagate158f,
	(FP) rmaPropagate158r,
	(FP) rmaPropagate158t0
};

#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
