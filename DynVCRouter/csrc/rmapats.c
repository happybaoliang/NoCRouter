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
void  rmaPropagate7(UB  * pcode, scalar  val);
void  rmaPropagate7f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate7r(UB  * pcode);
void  rmaPropagate14(UB  * pcode, scalar  val);
void  rmaPropagate14f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate14r(UB  * pcode);
void  rmaPropagate14t0(UB  * pcode, UB  val);
void  rmaPropagate15(UB  * pcode, scalar  val);
void  rmaPropagate15f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate15r(UB  * pcode);
void  rmaPropagate15t0(UB  * pcode, UB  val);
void  rmaPropagate16(UB  * pcode, scalar  val);
void  rmaPropagate16f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate16r(UB  * pcode);
void  rmaPropagate35(UB  * pcode, scalar  val);
void  rmaPropagate35f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate35r(UB  * pcode);
void  rmaPropagate36(UB  * pcode, scalar  val);
void  rmaPropagate36f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate36r(UB  * pcode);
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
void  rmaPropagate43(UB  * pcode, scalar  val);
void  rmaPropagate43f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate43r(UB  * pcode);
void  rmaPropagate47(UB  * pcode, scalar  val);
void  rmaPropagate47f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate47r(UB  * pcode);
void  rmaPropagate47t0(UB  * pcode, UB  val);
void  rmaPropagate48(UB  * pcode, scalar  val);
void  rmaPropagate48f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate48r(UB  * pcode);
void  rmaPropagate48t0(UB  * pcode, UB  val);
void  rmaPropagate49(UB  * pcode, scalar  val);
void  rmaPropagate49f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate49r(UB  * pcode);
void  rmaPropagate50(UB  * pcode, scalar  val);
void  rmaPropagate50f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate50r(UB  * pcode);
void  rmaPropagate54(UB  * pcode, scalar  val);
void  rmaPropagate54f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate54r(UB  * pcode);
void  rmaPropagate54t0(UB  * pcode, UB  val);
void  rmaPropagate65(UB  * pcode, scalar  val);
void  rmaPropagate65f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate65r(UB  * pcode);
void  rmaPropagate66(UB  * pcode, scalar  val);
void  rmaPropagate66f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate66r(UB  * pcode);
void  rmaPropagate67(UB  * pcode, scalar  val);
void  rmaPropagate67f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate67r(UB  * pcode);
void  rmaPropagate68(UB  * pcode, scalar  val);
void  rmaPropagate68f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate68r(UB  * pcode);
void  rmaPropagate68t0(UB  * pcode, UB  val);
void  rmaPropagate81(UB  * pcode, scalar  val);
void  rmaPropagate81f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate81r(UB  * pcode);
void  rmaPropagate82(UB  * pcode, scalar  val);
void  rmaPropagate82f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate82r(UB  * pcode);
void  rmaPropagate107(UB  * pcode, scalar  val);
void  rmaPropagate107f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate107r(UB  * pcode);
void  rmaPropagate108(UB  * pcode, scalar  val);
void  rmaPropagate108f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate108r(UB  * pcode);
void  rmaPropagate110(UB  * pcode, scalar  val);
void  rmaPropagate110f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate110r(UB  * pcode);
void  rmaPropagate113(UB  * pcode, scalar  val);
void  rmaPropagate113f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate113r(UB  * pcode);
void  rmaPropagate116(UB  * pcode, scalar  val);
void  rmaPropagate116f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate116r(UB  * pcode);
void  rmaPropagate117(UB  * pcode, scalar  val);
void  rmaPropagate117f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate117r(UB  * pcode);
void  rmaPropagate118(UB  * pcode, scalar  val);
void  rmaPropagate118f(UB  * pcode, scalar  val, U  frhs, scalar  * prhs);
void  rmaPropagate118r(UB  * pcode);
void  rmaPropagate118t0(UB  * pcode, UB  val);
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
	(FP) rmaPropagate7,
	(FP) rmaPropagate7f,
	(FP) rmaPropagate7r,
	(FP) rmaPropagate14,
	(FP) rmaPropagate14f,
	(FP) rmaPropagate14r,
	(FP) rmaPropagate14t0,
	(FP) rmaPropagate15,
	(FP) rmaPropagate15f,
	(FP) rmaPropagate15r,
	(FP) rmaPropagate15t0,
	(FP) rmaPropagate16,
	(FP) rmaPropagate16f,
	(FP) rmaPropagate16r,
	(FP) rmaPropagate35,
	(FP) rmaPropagate35f,
	(FP) rmaPropagate35r,
	(FP) rmaPropagate36,
	(FP) rmaPropagate36f,
	(FP) rmaPropagate36r,
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
	(FP) rmaPropagate43,
	(FP) rmaPropagate43f,
	(FP) rmaPropagate43r,
	(FP) rmaPropagate47,
	(FP) rmaPropagate47f,
	(FP) rmaPropagate47r,
	(FP) rmaPropagate47t0,
	(FP) rmaPropagate48,
	(FP) rmaPropagate48f,
	(FP) rmaPropagate48r,
	(FP) rmaPropagate48t0,
	(FP) rmaPropagate49,
	(FP) rmaPropagate49f,
	(FP) rmaPropagate49r,
	(FP) rmaPropagate50,
	(FP) rmaPropagate50f,
	(FP) rmaPropagate50r,
	(FP) rmaPropagate54,
	(FP) rmaPropagate54f,
	(FP) rmaPropagate54r,
	(FP) rmaPropagate54t0,
	(FP) rmaPropagate65,
	(FP) rmaPropagate65f,
	(FP) rmaPropagate65r,
	(FP) rmaPropagate66,
	(FP) rmaPropagate66f,
	(FP) rmaPropagate66r,
	(FP) rmaPropagate67,
	(FP) rmaPropagate67f,
	(FP) rmaPropagate67r,
	(FP) rmaPropagate68,
	(FP) rmaPropagate68f,
	(FP) rmaPropagate68r,
	(FP) rmaPropagate68t0,
	(FP) rmaPropagate81,
	(FP) rmaPropagate81f,
	(FP) rmaPropagate81r,
	(FP) rmaPropagate82,
	(FP) rmaPropagate82f,
	(FP) rmaPropagate82r,
	(FP) rmaPropagate107,
	(FP) rmaPropagate107f,
	(FP) rmaPropagate107r,
	(FP) rmaPropagate108,
	(FP) rmaPropagate108f,
	(FP) rmaPropagate108r,
	(FP) rmaPropagate110,
	(FP) rmaPropagate110f,
	(FP) rmaPropagate110r,
	(FP) rmaPropagate113,
	(FP) rmaPropagate113f,
	(FP) rmaPropagate113r,
	(FP) rmaPropagate116,
	(FP) rmaPropagate116f,
	(FP) rmaPropagate116r,
	(FP) rmaPropagate117,
	(FP) rmaPropagate117f,
	(FP) rmaPropagate117r,
	(FP) rmaPropagate118,
	(FP) rmaPropagate118f,
	(FP) rmaPropagate118r,
	(FP) rmaPropagate118t0
};

#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
