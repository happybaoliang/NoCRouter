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
void  rmaPropagate3(UB  * pcode, scalar  val);
void  rmaPropagate6(UB  * pcode, scalar  val);
void  rmaPropagate6f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate6r(UB  * pcode);
void  rmaPropagate25(UB  * pcode, scalar  val);
void  rmaPropagate25f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate25r(UB  * pcode);
void  rmaPropagate25t0(UB  * pcode, UB  val);
void  rmaPropagate26(UB  * pcode, scalar  val);
void  rmaPropagate26f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate26r(UB  * pcode);
void  rmaPropagate26t0(UB  * pcode, UB  val);
void  rmaPropagate27(UB  * pcode, scalar  val);
void  rmaPropagate27f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate27r(UB  * pcode);
void  rmaPropagate30(UB  * pcode, scalar  val);
void  rmaPropagate30f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate30r(UB  * pcode);
void  rmaPropagate30t0(UB  * pcode, UB  val);
void  rmaPropagate31(UB  * pcode, scalar  val);
void  rmaPropagate31f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate31r(UB  * pcode);
void  rmaPropagate32(UB  * pcode, scalar  val);
void  rmaPropagate32f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate32r(UB  * pcode);
void  rmaPropagate37(UB  * pcode, scalar  val);
void  rmaPropagate37f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate37r(UB  * pcode);
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
void  rmaPropagate42(UB  * pcode, scalar  val);
void  rmaPropagate42f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate42r(UB  * pcode);
void  rmaPropagate64(UB  * pcode, scalar  val);
void  rmaPropagate64f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate64r(UB  * pcode);
void  rmaPropagate65(UB  * pcode, scalar  val);
void  rmaPropagate65f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate65r(UB  * pcode);
void  rmaPropagate70(UB  * pcode, scalar  val);
void  rmaPropagate70f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate70r(UB  * pcode);
void  rmaPropagate71(UB  * pcode, scalar  val);
void  rmaPropagate71f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate71r(UB  * pcode);
void  rmaPropagate72(UB  * pcode, scalar  val);
void  rmaPropagate72f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate72r(UB  * pcode);
void  rmaPropagate72t0(UB  * pcode, UB  val);
void  rmaPropagate73(UB  * pcode, scalar  val);
void  rmaPropagate73f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate73r(UB  * pcode);
void  rmaPropagate73t0(UB  * pcode, UB  val);
void  rmaPropagate82(UB  * pcode, scalar  val);
void  rmaPropagate82f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate82r(UB  * pcode);
void  rmaPropagate84(UB  * pcode, scalar  val);
void  rmaPropagate84f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate84r(UB  * pcode);
void  rmaPropagate85(UB  * pcode, scalar  val);
void  rmaPropagate85f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate85r(UB  * pcode);
void  rmaPropagate91(UB  * pcode, scalar  val);
void  rmaPropagate91f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate91r(UB  * pcode);
void  rmaPropagate92(UB  * pcode, scalar  val);
void  rmaPropagate92f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate92r(UB  * pcode);
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
	(FP) rmaPropagate3,
	(FP) rmaPropagate6,
	(FP) rmaPropagate6f,
	(FP) rmaPropagate6r,
	(FP) rmaPropagate25,
	(FP) rmaPropagate25f,
	(FP) rmaPropagate25r,
	(FP) rmaPropagate25t0,
	(FP) rmaPropagate26,
	(FP) rmaPropagate26f,
	(FP) rmaPropagate26r,
	(FP) rmaPropagate26t0,
	(FP) rmaPropagate27,
	(FP) rmaPropagate27f,
	(FP) rmaPropagate27r,
	(FP) rmaPropagate30,
	(FP) rmaPropagate30f,
	(FP) rmaPropagate30r,
	(FP) rmaPropagate30t0,
	(FP) rmaPropagate31,
	(FP) rmaPropagate31f,
	(FP) rmaPropagate31r,
	(FP) rmaPropagate32,
	(FP) rmaPropagate32f,
	(FP) rmaPropagate32r,
	(FP) rmaPropagate37,
	(FP) rmaPropagate37f,
	(FP) rmaPropagate37r,
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
	(FP) rmaPropagate42,
	(FP) rmaPropagate42f,
	(FP) rmaPropagate42r,
	(FP) rmaPropagate64,
	(FP) rmaPropagate64f,
	(FP) rmaPropagate64r,
	(FP) rmaPropagate65,
	(FP) rmaPropagate65f,
	(FP) rmaPropagate65r,
	(FP) rmaPropagate70,
	(FP) rmaPropagate70f,
	(FP) rmaPropagate70r,
	(FP) rmaPropagate71,
	(FP) rmaPropagate71f,
	(FP) rmaPropagate71r,
	(FP) rmaPropagate72,
	(FP) rmaPropagate72f,
	(FP) rmaPropagate72r,
	(FP) rmaPropagate72t0,
	(FP) rmaPropagate73,
	(FP) rmaPropagate73f,
	(FP) rmaPropagate73r,
	(FP) rmaPropagate73t0,
	(FP) rmaPropagate82,
	(FP) rmaPropagate82f,
	(FP) rmaPropagate82r,
	(FP) rmaPropagate84,
	(FP) rmaPropagate84f,
	(FP) rmaPropagate84r,
	(FP) rmaPropagate85,
	(FP) rmaPropagate85f,
	(FP) rmaPropagate85r,
	(FP) rmaPropagate91,
	(FP) rmaPropagate91f,
	(FP) rmaPropagate91r,
	(FP) rmaPropagate92,
	(FP) rmaPropagate92f,
	(FP) rmaPropagate92r
};

#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
