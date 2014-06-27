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
void  rmaPropagate34(UB  * pcode, scalar  val);
void  rmaPropagate34f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate34r(UB  * pcode);
void  rmaPropagate39(UB  * pcode, scalar  val);
void  rmaPropagate39f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate39r(UB  * pcode);
void  rmaPropagate39t0(UB  * pcode, UB  val);
void  rmaPropagate40(UB  * pcode, scalar  val);
void  rmaPropagate40f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate40r(UB  * pcode);
void  rmaPropagate40t0(UB  * pcode, UB  val);
void  rmaPropagate41(UB  * pcode, scalar  val);
void  rmaPropagate41f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate41r(UB  * pcode);
void  rmaPropagate42(UB  * pcode, scalar  val);
void  rmaPropagate42f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate42r(UB  * pcode);
void  rmaPropagate46(UB  * pcode, scalar  val);
void  rmaPropagate46f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate46r(UB  * pcode);
void  rmaPropagate46t0(UB  * pcode, UB  val);
void  rmaPropagate58(UB  * pcode, scalar  val);
void  rmaPropagate58f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate58r(UB  * pcode);
void  rmaPropagate59(UB  * pcode, scalar  val);
void  rmaPropagate59f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate59r(UB  * pcode);
void  rmaPropagate60(UB  * pcode, scalar  val);
void  rmaPropagate60f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate60r(UB  * pcode);
void  rmaPropagate61(UB  * pcode, scalar  val);
void  rmaPropagate61f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate61r(UB  * pcode);
void  rmaPropagate61t0(UB  * pcode, UB  val);
void  rmaPropagate72(UB  * pcode, scalar  val);
void  rmaPropagate72f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate72r(UB  * pcode);
void  rmaPropagate73(UB  * pcode, scalar  val);
void  rmaPropagate73f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate73r(UB  * pcode);
void  rmaPropagate76(UB  * pcode, scalar  val);
void  rmaPropagate76f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate76r(UB  * pcode);
void  rmaPropagate77(UB  * pcode, scalar  val);
void  rmaPropagate77f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate77r(UB  * pcode);
void  rmaPropagate78(UB  * pcode, scalar  val);
void  rmaPropagate78f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate78r(UB  * pcode);
void  rmaPropagate82(UB  * pcode, scalar  val);
void  rmaPropagate82f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate82r(UB  * pcode);
void  rmaPropagate92(UB  * pcode, scalar  val);
void  rmaPropagate92f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate92r(UB  * pcode);
void  rmaPropagate95(UB  * pcode, scalar  val);
void  rmaPropagate95f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate95r(UB  * pcode);
void  rmaPropagate98(UB  * pcode, scalar  val);
void  rmaPropagate117(UB  * pcode, scalar  val);
void  rmaPropagate117f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate117r(UB  * pcode);
void  rmaPropagate118(UB  * pcode, scalar  val);
void  rmaPropagate118f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate118r(UB  * pcode);
void  rmaPropagate120(UB  * pcode, scalar  val);
void  rmaPropagate120f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate120r(UB  * pcode);
void  rmaPropagate123(UB  * pcode, scalar  val);
void  rmaPropagate123f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate123r(UB  * pcode);
void  rmaPropagate140(UB  * pcode, scalar  val);
void  rmaPropagate140f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate140r(UB  * pcode);
void  rmaPropagate143(UB  * pcode, scalar  val);
void  rmaPropagate143f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate143r(UB  * pcode);
void  rmaPropagate144(UB  * pcode, scalar  val);
void  rmaPropagate144f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate144r(UB  * pcode);
void  rmaPropagate145(UB  * pcode, scalar  val);
void  rmaPropagate145f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate145r(UB  * pcode);
void  rmaPropagate145t0(UB  * pcode, UB  val);
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
	(FP) rmaPropagate34,
	(FP) rmaPropagate34f,
	(FP) rmaPropagate34r,
	(FP) rmaPropagate39,
	(FP) rmaPropagate39f,
	(FP) rmaPropagate39r,
	(FP) rmaPropagate39t0,
	(FP) rmaPropagate40,
	(FP) rmaPropagate40f,
	(FP) rmaPropagate40r,
	(FP) rmaPropagate40t0,
	(FP) rmaPropagate41,
	(FP) rmaPropagate41f,
	(FP) rmaPropagate41r,
	(FP) rmaPropagate42,
	(FP) rmaPropagate42f,
	(FP) rmaPropagate42r,
	(FP) rmaPropagate46,
	(FP) rmaPropagate46f,
	(FP) rmaPropagate46r,
	(FP) rmaPropagate46t0,
	(FP) rmaPropagate58,
	(FP) rmaPropagate58f,
	(FP) rmaPropagate58r,
	(FP) rmaPropagate59,
	(FP) rmaPropagate59f,
	(FP) rmaPropagate59r,
	(FP) rmaPropagate60,
	(FP) rmaPropagate60f,
	(FP) rmaPropagate60r,
	(FP) rmaPropagate61,
	(FP) rmaPropagate61f,
	(FP) rmaPropagate61r,
	(FP) rmaPropagate61t0,
	(FP) rmaPropagate72,
	(FP) rmaPropagate72f,
	(FP) rmaPropagate72r,
	(FP) rmaPropagate73,
	(FP) rmaPropagate73f,
	(FP) rmaPropagate73r,
	(FP) rmaPropagate76,
	(FP) rmaPropagate76f,
	(FP) rmaPropagate76r,
	(FP) rmaPropagate77,
	(FP) rmaPropagate77f,
	(FP) rmaPropagate77r,
	(FP) rmaPropagate78,
	(FP) rmaPropagate78f,
	(FP) rmaPropagate78r,
	(FP) rmaPropagate82,
	(FP) rmaPropagate82f,
	(FP) rmaPropagate82r,
	(FP) rmaPropagate92,
	(FP) rmaPropagate92f,
	(FP) rmaPropagate92r,
	(FP) rmaPropagate95,
	(FP) rmaPropagate95f,
	(FP) rmaPropagate95r,
	(FP) rmaPropagate98,
	(FP) rmaPropagate117,
	(FP) rmaPropagate117f,
	(FP) rmaPropagate117r,
	(FP) rmaPropagate118,
	(FP) rmaPropagate118f,
	(FP) rmaPropagate118r,
	(FP) rmaPropagate120,
	(FP) rmaPropagate120f,
	(FP) rmaPropagate120r,
	(FP) rmaPropagate123,
	(FP) rmaPropagate123f,
	(FP) rmaPropagate123r,
	(FP) rmaPropagate140,
	(FP) rmaPropagate140f,
	(FP) rmaPropagate140r,
	(FP) rmaPropagate143,
	(FP) rmaPropagate143f,
	(FP) rmaPropagate143r,
	(FP) rmaPropagate144,
	(FP) rmaPropagate144f,
	(FP) rmaPropagate144r,
	(FP) rmaPropagate145,
	(FP) rmaPropagate145f,
	(FP) rmaPropagate145r,
	(FP) rmaPropagate145t0
};

#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
