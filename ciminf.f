      subroutine cimx(runtyp)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      COMMON /RUNOPT/ RUNTYP2,EXETYP,NEVALS,NGLEVL,NHLEVL
      COMMON /IOFILE/ IR,IW,IP,IS,IPK,IDAF,NAV,IODA(950)
      COMMON /WFNOPT/ SCFTYP,VBTYP,DFTYPE,TDDFTYP,CITYP,CCTYP,
     *                MPLEVL,MPCTYP
      data ccd,ccsd,ccsdt,crccl,rimp2
     *     /8HCCD     ,8HCCSD    ,8HCCSD(T) ,8HCR-CCL  ,8HRIMP2   /
      LOGICAL GOPARR,DSKWRK,MASWRK 
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      COMMON /CIMINF/ ICIM,ICIF,MOTYP,NCA,NCB,NFRG
C     common /CIMFULL/ cimrun,cimcont,irest2
C     logical cimrun,cimcont
      DATA CIMFINAL/8HCIMFINAL/
      DATA CIMSUB /8HCIMSUB  /
      data check  /8HCHECK   /
      parameter (mxatm=2000)
      LOGICAL MOSORT,ORTHO,SUBRHF,FCORE,restrt,runsub
      common /CIMPAR/ bufdst,cconv,mrgsub,submtd,
     *                subtyp,mosort,atmmlk,ortho,subrhf,
     *                eta,zeta,zeta1,zeta2,cimtyp,enrgml,
     *                fcore,mtdatm(mxatm),runsub,restrt,MOFIX,
     *                CIMORB,DISLMO,HDIS,CONVIR,TWOBDY
C
C two hidden runtypes are dealt with here: cimsub and cimfinal
C cimsub is only for subsystem correlation energy inputs
C        these are highly specialized input files whose
C        only purpose is to run wfnmp2 and wfncc
C cimfinal is run when mtdcim=2 and the runtyp is set after
C          the input is read.  This is really a restart option
C          if the user decided to run subsystem correlation
C          input files(runtyp=cimsub) manually, otherwise
C          cimf is called from runcimsub.
C
      if(runtyp.eq.cimsub) then
         if(goparr) then
            if(maswrk) then
               write(iw,*)
               write(iw,*) 'CIM SUBSYSTEMS CANNOT BE RUN IN PARALLEL'
               write(iw,*)
               call abrt
            endif
         endif
         CALL TSECND(T0)
C        A fully automated cim run will have already opened the
C        file since the name is derived (not an enviroment variable)
         if(.not.runsub)
     *      CALL SEQOPN(ICIF,'CIMFILE', 'NEW',.FALSE., 'FORMATTED')
         CALL SYMOFF
         call oneei
         call guesmo(guess)
         call jandk
C read the subsystem fock matrix and orbitals
         CALL CIMINI
C        ICIM is used in the cc and mp2 routines in cimsub.src
C        and nowhere else
         icim=2
         if (mplevl.eq.2) then
            write(iw,*) "call wfnmp2"
            call wfnmp2
         endif
         if(mplevl.eq.2) call TIMSTP('MP2     ')
         if(cctyp.eq.ccsd
     *     .or.cctyp.eq.ccd
     *     .or.cctyp.eq.ccsdt
     *     .or.cctyp.eq.crccl) call wfncc
         if (cctyp.eq.ccsdt.or.cctyp.eq.crccl) call TIMSTP(cctyp)
         CALL TIMCIM(T0,'SUBSYSTEM   ')
         icim=0
         return
      else if(runtyp.eq.cimfinal) then
         if(maswrk) call cimi_help(iw)
         if(goparr) then
            if(maswrk) write(iw,*) 'RESTARTING CIM ONLY WORKS IN SERIAL'
            if(maswrk) write(iw,*)
            call abrt
         endif
         if(exetyp.eq.check) then
            write(iw,*) 'CIMF NOT AVAILABLE FOR CHECK'
         else
            call cimf(finalenergy,.true.)
         endif
         return
      else
         if(maswrk) write(iw,*)
         if(maswrk) write(iw,*) 'There is a problem with CIM'
         if(maswrk) write(iw,*) 'RUNTYP=',runtyp, ' was not expected'
         call abrt
      endif

      end
C
C*MODULE CIMSUB  *DECK CIMINI
      SUBROUTINE CIMINI
C
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
C
      LOGICAL GOPARR,DSKWRK,MASWRK
C
      PARAMETER (MXRT=100, MXATM=2000, MXAO=8192)
C
      COMMON /CCPAR / AMPTSH,METHCC,NCCTOT,NCCOCC,NCCFZC,NCCFZV,
     *                MXCCIT,MXRLEIT,MWRDCC,ICCCNV,ICCRST,IDSKCC
      COMMON /EOMPAR/ CVGCI,CVGEOM,GRPEOM,NSTEOM(8),NOACT,NUACT,
     *                MOACTCC(MXAO),MTHTRIP,MTHCI,MTHEOM,MTHINIT,
     *                MAXCI,MAXEOM,MICCI,MICEOM,IROOTCC(2),
     *                IPROPCC,IPROPCCE
      COMMON /FMCOM / XX(1)
      COMMON /INFOA / NAT,ICH,MUL,NUM,NQMT,NE,NA,NB,
     *                ZAN(MXATM),C(3,MXATM),IAN(MXATM)
      COMMON /IOFILE/ IR,IW,IP,IS,IPK,IDAF,NAV,IODA(950)
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      COMMON /RUNOPT/ RUNTYP,EXETYP,NEVALS,NGLEVL,NHLEVL
      COMMON /WFNOPT/ SCFTYP,VBTYP,DFTYPE,TDDFTYP,CITYP,CCTYP,
     *                MPLEVL,MPCTYP
      COMMON /CIMINF/ ICIM,ICIF,MOTYP,NCA,NCB,NFRG
C     common /CIMFULL/ cimrun,cimcont,irest2
C     logical cimrun,cimcont
      LOGICAL MOSORT,ORTHO,SUBRHF,FCORE,restrt,runsub
      common /CIMPAR/ bufdst,cconv,mrgsub,submtd,
     *                subtyp,mosort,atmmlk,ortho,subrhf,
     *                eta,zeta,zeta1,zeta2,cimtyp,enrgml,
     *                fcore,mtdatm(mxatm),runsub,restrt,MOFIX,
     *                CIMORB,DISLMO,HDIS,CONVIR,TWOBDY
      COMMON /CIMIDX/ MOCEN(MXAO),ICENA(MXAO),ICENB(MXAO),MOOCC(MXAO),
     *                MOFG(MXAO)
      double precision motype
      COMMON /ENRGYS/ ENUCR,EELCT,ETOT2,SZ2,SZZ2,ECORE,ESCF,EERD,E1,E2,
     *                VEN,VEE,EPOT,EKIN,ESTATE(MXRT),STATN,EDFT(2)
C
C     DEF. STATEMENTS FROM WFNMP2
C
      COMMON /MP2PAR/ OSPT,CODEMP,SCSPT,TOL,METHOD,NWDMP2,MEMPRI,MPPROP,
     *                NACORE,NBCORE,NOA,NOB,NORB,NBF,NOMIT,MOCPHF,MAXITC
C
      data rohf /8HROHF    /
      DATA RNONE/8HNONE    /
      DATA rlmo /8HLMO     /
      DATA QCMO /8HQCMO    /
C     $INFO group (special for cim)
      PARAMETER (NNAM=18)
      DIMENSION QNAM(NNAM),KQNAM(NNAM)
      DATA QNAM/8HNSYS    ,8HSCFTYP  ,8HMPLEVL  ,8HCCTYP   ,
     *          8HICONV   ,8HMOTYP   ,8HSYS     ,8HNAT     ,
     *          8HICH     ,8HMUL     ,8HNE      ,8HNA      ,
     *          8HNB      ,8HNUM     ,8HNMO     ,8HNCA     ,
     *          8HNCB     ,8HNFRG    /
      DATA KQNAM/1,5,1,5,  1,5,1,1, 1,1,1,1, 1,1,1,1, 1,1/
      DATA GROUP/8HINFO    /
      DATA CRCCL  /8HCR-CCL  /
      data check  /8HCHECK   /
      DATA CIMSUB /8HCIMSUB  /
      parameter (zero=0.d0)
C
C Initialize subsystem correlation calculations
C this subroutine reads $INFO, $MO-CEN, $EIGVAL, $VEC,
C $AO-FOCK-[A/B] and $TRMX-[A/B] which will have been generated by
C CIMI.
C
C        SET UP S,P,D,F,G TRANSFORMATION MATRICES
C
      CALL TRMAT
C A fully automatic run will preserve the total system dictionary
      if(runsub) idaf=194
C First, set energies.  The SCF energy is not actually 
C required at this step
      ETOT = ZERO
      EN=ENUC(NAT,ZAN,C)
      SZ = ZERO
      S2 = ZERO
      ENUCR = EN
      eelct = zero
      ETOT2 = ETOT
      SZ2   = SZ
      SZZ2  = S2
      ECORE = ZERO
      ESCF  = ETOT
      CALL DAWRIT(IDAF,IODA,ENUCR,MXRT+15,2,0)

C
C     ---- WRITE OLD PARAMETERS ----
C
      IF(MASWRK) THEN
         WRITE(IW,*)'      NAtom  NBasi  NOrbt  NElec  NAlph  NBeta'
         WRITE(IW,'('' Old:'',6i7)') NAT,NUM,NQMT,NE,NA,NB
      END IF

C read $INFO
C but don't overwrite everything
C some of this is also in $CONTRL
      nsys=0
      scftyp2=rnone
      mplevl2=0
      cctyp2=rnone
      iconv=0
      motype=rnone
      isys=0
      nat2=0
      ich=0
      mul=0
      ne2=0
      na2=0
      nb2=0
      num2=0
      nqmt=0
      nca=0
      ncb=0
      nfrg=0
      CALL NAMEIO(IR,JRET,GROUP,NNAM,QNAM,KQNAM,
     *            nsys,scftyp2,mplevl2,cctyp2,
     *            iconv,motype,isys,nat2,
     *            ich,mul,ne2,na2,
     *            nb2,num2,nqmt2,nca,
     *            ncb,nfrg,
     *            0,0,0,0,0,0,0,0,0,
     *            0,0,0,0,0,0,0,0,0,0,
     *            0,0,0,0,0,0,0,0,0,0,
     *            0,0,0,0,0,0,0,0,0,0,
     *            0,0,0,0,0,0,0)
         IF (MOTYPE.EQ.rlmo) THEN
            MOTYP=1
         ELSE IF(MOTYPE.EQ.qcmo) THEN
            MOTYP=2
         ELSE
            MOTYP=0
         END IF
C
C
      IF (MASWRK) THEN
         WRITE(IW,'('' New:'',6i7)') NAT2,NUM2,NQMT2,NE2,NA2,NB2
      END IF
C
C     ---- ASSIGN NEW PARAMETERS ----
      NA=NA2
      NB=NB2
      NE=NE2
      NQMT=NQMT2
C
C     ---- UPDATE FOR MP2 ----
C
      IF (MPLEVL.NE.0) THEN
         NACORE=0
         NBCORE=0
         NOA=NA
         NOB=NB
      END IF
C
C     ---- UPDATE FOR CC ----
C     NCCOCC IS THE NUMBER OF OCCUPIED MOS, INCLUDING CORE.
C     NCCFZV IS THE NUMBER OF FROZEN EXTERNAL ORBITALS OMITTED.
C
      IF (CCTYP.NE.RNONE) THEN
         NCCOCC=NA
         NCCFZC=0
         IF (SCFTYP.EQ.ROHF) IPROPCC=1
         IF (CCTYP.EQ.CRCCL) MAXEOM=100
      END IF
C
      L1=NUM
      L2=L1*(L1+1)/2
      L3=L1*L1
C
      CALL VALFM(LOADFM)
      LFAO = LOADFM+1
      LFHH = LFAO + L2
      LVEC = LFHH + L1
      LTX  = LVEC + L3   !LTX  !-WL- 12/3/2007 ADD
      LWRK = LTX  + NA*NA
      LAST = LWRK + L1
      NEED = LAST-LOADFM-1
      if(runtyp.eq.check) then
         write(iw,"('CIMINI REQUIRES ',I16,' WORDS')") need
      endif
      CALL GETFM(NEED)
      CALL VCLR(XX(LFAO),1,L2)
      CALL VCLR(XX(LVEC),1,L3)
      CALL VCLR(XX(LTX), 1,NA*NA)   !-WL- 12/3/2007 ADD
C
C     ---- READ MORE INFORMATION FOR CIM ----
C
      if(maswrk) then
         CALL iread8(ir, '$MO-OCC',     NA, MOOCC(1))
         CALL iread8(ir, '$MO-CEN',     NA, MOCEN(1))       
         CALL iread8(ir, '$MO-FRG',     NA, MOFG(1))       

C
      CALL VICLR(ICENA(1),1,NA)   !-WL- 2009/09/21 NOA-> NA
      CALL VICLR(ICENB(1),1,NB)   !-WL- 2009/09/21 NOA-> NA
      KK=0
      DO 300 K=1,NA
         IF (MOCEN(K).NE.1 .AND. MOCEN(K).NE.2) GO TO 300
         KK=KK+1
         ICENA(KK)=K
 300  END DO
      KK=0
      DO 310 K=1,NB
         IF (MOCEN(K).NE.-1 .AND. MOCEN(K).NE.2) GO TO 310
         KK=KK+1
         ICENB(KK)=K
 310  END DO
C
      call rread8(ir, '$EIGVAL',     L1, XX(LFHH))  ! FOR RHF-CR-CCL
      CALL DAWRIT(IDAF,IODA,XX(LFHH),L1,17,0)    
C
      call rread8(ir, '$VEC',  L1*NQMT,  XX(LVEC))
      CALL DAWRIT(IDAF,IODA,XX(LVEC),L3,15,0)
C
C     Print the subsystem orbitals if you wish
C     This is not generally a good idea for mtdcim=0 since
C     these orbitals are not in the total system basis
C     WRITE(IW,9170)
C     CALL PREV(XX(LVEC),XX(LFHH),NQMT,L1,L1)
C     write(iw,*) '... END OF SUBSYSTEM ORBITALS ...'
C
      call rread8(ir, '$AO-FOCK-A',  L2, XX(LFAO))
      CALL DAWRIT(IDAF,IODA,XX(LFAO),L2,14,0)
C
      call rread8(ir, '$TRMX-A',  NA*NA, XX(LTX))
      CALL DAWRIT(IDAF,IODA,XX(LTX),NA*NA,359,0)
C
      IF (SCFTYP.EQ.ROHF) THEN
         call rread8(ir, '$AO-FOCK-B',  L2, XX(LFAO))
         CALL DAWRIT(IDAF,IODA,XX(LFAO),L2,18,0)   
C
         call rread8(ir, '$TRMX-B',  NB*NB, XX(LTX))
         CALL DAWRIT(IDAF,IODA,XX(LTX),NB*NB,360,0)
      ENDIF
      endif
      CALL RETFM(NEED) 
C
C     ---- END OF CIM INFO ----
C
C9170 FORMAT(/10X,18(1H-)/10X,18HSUBSYSTEM ORBITALS/10X,18(1H-))
      END
C
      subroutine cimprint

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      PARAMETER (MXSH=5000, MXGTOT=20000, MXATM=2000,
     *           ONE = 1.0D0,MXRT=100,MXAO=8192,
     *           UNITS = ONE/0.52917724924D+00,
     *           TWO=2.D0)
      logical MASWRK,dskwrk,goparr
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      COMMON /RUNLAB/ TITLE(10),A(MXATM),B(MXATM),BFLAB(MXAO)
      COMMON /INFOA / NAT,ICH,MUL,NUM,NQMT,NE,NA,NB,
     *                ZAN(MXATM),C(3,MXATM),IAN(MXATM)
      COMMON /IOFILE/ IR,IW,IP,IS,IPK,IDAF,NAV,IODA(950)
      COMMON /WFNOPT/ SCFTYP,VBTYP,DFTYPE,TDDFTYP,CITYP,CCTYP,
     *                MPLEVL,MPCTYP
      COMMON /NEOSHL/ NGAUSS,NGAUSE,NGAUSN,NTSHEL,NNUCSH
      COMMON /NSHEL / EX(MXGTOT),CS(MXGTOT),CP(MXGTOT),CD(MXGTOT),
     *                CF(MXGTOT),CG(MXGTOT),CH(MXGTOT),CI(MXGTOT),
     *                KSTART(MXSH),KATOM(MXSH),KTYPE(MXSH),KNG(MXSH),
     *                KLOC(MXSH),KMIN(MXSH),KMAX(MXSH),NSHELL
      COMMON /BASSPH/ QMATOL,NSPHER
      COMMON /ENRGYS/ ENUCR,EELCT,ETOT,SZ,SZZ,ECORE,ESCF,EERD,E1,E2,
     *                VEN,VEE,EPOT,EKIN,ESTATE(MXRT),STATN,EDFT(2)
      COMMON /ECP2  / CLP(400),ZLP(400),NLP(400),KFIRST(MXATM,6),
     *                KLAST(MXATM,6),LMAX(MXATM),LPSKIP(MXATM),
     *                IZCORE(MXATM)
      LOGICAL MOSORT,ORTHO,SUBRHF,FCORE,restrt,runsub
      common /CIMPAR/ bufdst,cconv,mrgsub,submtd,
     *                subtyp,mosort,atmmlk,ortho,subrhf,
     *                eta,zeta,zeta1,zeta2,cimtyp,enrgml,
     *                fcore,mtdatm(mxatm),runsub,restrt,MOFIX,
     *                CIMORB,DISLMO,HDIS,CONVIR,TWOBDY
      COMMON /FMCOM / X(1)
      CHARACTER*10 METHOD
      character*80 cimfrg
      COMMON /CIMINF/ ICIM,ICIF,MOTYP,NCA,NCB,NFRG
      DATA rMP2   /8HMP2     /
      DATA CRCCL  /8HCR-CCL  /
      DATA CCSD   /8HCCSD    /
      DATA CCD    /8HCCD     /
      DATA CCSDPT /8HCCSD(T) /
      DATA RHF    /8HRHF     /
      DATA ROHF   /8HROHF    /
      DATA UHF    /8HUHF     /
      DATA RIMP2  /8HRIMP2   /
      DOUBLE PRECISION LABEL(6), NUMCOR(103)
      dimension nbsa(mxatm),lbsa(mxsh),atmmtd(mxatm)
      DATA LABEL/8HS       ,8HP       ,8HD       ,8HF       ,
     *           8HG       ,8HL       /
      DATA NUMCOR/2*0,
     *            2*1,                  6*1,
     *            2*5,                  6*5,
     *            2*9,          10*9,   6*14,
     *            2*18,         10*18,  6*23,
     *            2*27,  14*27, 10*34,  6*39,
     *            2*43,  14*43,    50/

C Generate the CIMFILE.  Right now, CIMI will read this file
C instead of directly accessing the common blocks or DAF records.
C
      CALL SEQOPN(ICIF,'CIMFILE', 'UNKNOWN',.FALSE., 'FORMATTED')

      L1 = NUM
      L2 = (L1*(L1+1))/2
      if(maswrk) write(icif,*) '$DATA'
      if(maswrk) WRITE(icif,'(10A8)') TITLE
      if(maswrk) WRITE(icif,'(A8,I5)') 'C1      ',0
      mcore=0
      N = 0
      LASTAT=0
      DO 120 II = 1,NSHELL
         IAT = KATOM(II)
         J = INT(ZAN(IAT))
         I1 = KSTART(II)
         I2 = I1+KNG(II)-1
         NBFS = KMAX(II) - KMIN(II) + 1
         IF (NBFS.EQ.1)  ITYP = 1
         IF (NBFS.EQ.3)  ITYP = 2
         IF (NBFS.EQ.6)  ITYP = 3
         IF (NBFS.EQ.10) ITYP = 4
         IF (NBFS.EQ.15) ITYP = 5
         IF (NBFS.EQ.4)  ITYP = 6
         IF (LASTAT.NE.IAT) THEN
            IF (MASWRK  .AND.  IAT.NE.1) WRITE(icif,*) ' '
            ZNUC = ZAN(IAT)
            IZ = INT(ZAN(IAT)) + IZCORE(IAT)
            IF (MCORE.GT.0) ZNUC = ZNUC - TWO*NUMCOR(IZ)
            IF(MASWRK) WRITE(icif,9000) A(IAT),znuc,
     *                                (C(J,IAT)/UNITS,J=1,3)
         END IF
         IF(MASWRK) WRITE(icif,9050) LABEL(ITYP),(I2-I1+1)
         kk=0
         DO 110 IG = I1,I2
            kk=kk+1
            N = N+1
            IF(ITYP.EQ.1) C1 = CS(IG)
            IF(ITYP.EQ.2) C1 = CP(IG)
            IF(ITYP.EQ.3) C1 = CD(IG)
            IF(ITYP.EQ.4) C1 = CF(IG)
            IF(ITYP.EQ.5) C1 = CG(IG)
            IF(ITYP.EQ.6) C1 = CS(IG)
            IF(ITYP.EQ.6) C2 = CP(IG)
            IF(MASWRK.AND.ITYP.LE.5) WRITE(icif,9100) kk,EX(IG),C1
            IF(MASWRK.AND.ITYP.EQ.6) WRITE(icif,9100) kk,EX(IG),C1,C2
  110    CONTINUE
         LASTAT=IAT
  120 CONTINUE
      IF(MASWRK) THEN
         WRITE(icif,*) ' '
         write(icif,*) '$END'
      END IF
      if(maswrk) write(icif,1010)
     *            BUFDST,CCONV,MOFIX,mrgsub,SUBMTD,
     *            subtyp,MOSORT,atmmlk,
     *            ORTHO,SUBRHF,ETA,ZETA,ZETA1,ZETA2,
     *            CIMTYP,enrgml,fcore,CIMORB,DISLMO,
     *            HDIS,CONVIR,TWOBDY

C Save the total system information to CIMFILE
      if(maswrk) then
         WRITE(icif,*) '$INFO'
         WRITE(icif,'(a8,a,i8)')     'NAT     ', '=', NAT
         WRITE(icif,'(a8,a,i8)')     'ICH     ', '=', ICH
         WRITE(icif,'(a8,a,i8)')     'MUL     ', '=', MUL
         WRITE(icif,'(a8,a,i8)')     'NE      ', '=', NE
         WRITE(icif,'(a8,a,i8)')     'NA      ', '=', NA
         WRITE(icif,'(a8,a,i8)')     'NB      ', '=', NB
         WRITE(icif,'(a8,a,i8)')     'NUM     ', '=', NUM
         WRITE(icif,'(a8,a,i8)')     'NSHELL  ', '=', NSHELL
         WRITE(icif,'(a8,a,i8)')     'NGAUSS  ', '=', NGAUSS
         WRITE(icif,'(a8,a,f20.10)') 'ENUCR   ', '=', ENUCR
         WRITE(icif,'(a8,a,i8)')     'ISPHER  ', '=', nspher
         WRITE(icif,*) '$END'
      endif
      
      call seqrew(ir)
      CALL FNDGRP(IR,' $CIMFRG ',IEOF)
      IF(IEOF.EQ.0.and.maswrk) THEN
         write(icif,*) '$CIMFRG'
         call opncrd(ir,-icif)
         read (ir,"(a80)") cimfrg
  100 continue
         if(cimfrg.eq.' $end' .or. cimfrg.eq.' $END') then
            write(icif,*) '$END'
            goto 101
         endif
         write(icif,"(a80)") cimfrg
         read (ir,"(a80)") cimfrg
         goto 100
      endif
  101 continue

      do i=1,nat
         if(mtdatm(i).eq.-1) then
            if(maswrk) write(iw,*) '$CIMATM HAS NOT BEEN READ PROPERLY'
            call abrt
         endif
         if(mtdatm(i).eq.0) then
            if(scftyp.eq.rhf)  atmmtd(i)=rhf
            if(scftyp.eq.rohf) atmmtd(i)=rohf
         endif
         if(mtdatm(i).eq.1) atmmtd(i)=rimp2
         if(mtdatm(i).eq.2) atmmtd(i)=rmp2
         if(mtdatm(i).eq.3) atmmtd(i)=ccd
         if(mtdatm(i).eq.4) atmmtd(i)=ccsd
         if(mtdatm(i).eq.5) atmmtd(i)=ccsdpt
         if(mtdatm(i).eq.6) atmmtd(i)=crccl
      enddo
      if(maswrk) call cwrit(icif,'$CIMATM', nat, atmmtd)
C
      DO I = 1,MXATM
         NBSA(I) = 0
      END DO
      DO I = 1,MXSH
         LBSA(I) = 0
      END DO
      L = 0
      DO I = 1,NSHELL
         J = KATOM(I)
         DO K = L+1, L+KMAX(I)-KMIN(I)+1
            LBSA(K)=J
         END DO
         L = L+KMAX(I)-KMIN(I)+1
         NBSA(J)=NBSA(J)+KMAX(I)-KMIN(I)+1
      ENDDO
      if(maswrk) call iwrit(icif,'$ATOM-NBASIS', NAT, NBSA)
      if(maswrk) call iwrit(icif,'$BASIS-ATOMS', NUM, LBSA)


      CALL VALFM(LOADFM)
      LH1  = LOADFM + 1
      LS   = LH1    + L2
      LFAO = LS     + L2
      LD   = LFAO   + L2
      LEIG = LD     + L2
      LVEC = LEIG   + NQMT
      LTRI = LVEC   + L1*L1
      IF (SCFTYP.EQ.RHF) THEN
         LAST = LTRI   + L2
      ELSE IF (SCFTYP.EQ.ROHF) THEN
         LFB  = LTRI   + L2
         LDB  = LFB    + L2
         LAST = LDB    + L2
      END IF
      NEED = LAST-LOADFM-1
C     write(iw,"('CIMPRINT REQUIRES ',I16,' WORDS')") need
      CALL GETFM(NEED)

      CALL DAREAD(IDAF,IODA,x(lH1),L2,11,0)
      CALL DAREAD(IDAF,IODA,x(lS),L2,12,0)
      call daread(idaf,ioda,x(lfao),l2,14,0)
      call daread(idaf,ioda,x(ld),l2,16,0)
      IF (SCFTYP.EQ.ROHF) THEN
         CALL DAREAD(IDAF,IODA,X(LFB),L2,18,0)
         CALL DAREAD(IDAF,IODA,X(LDB),L2,20,0)
      END IF
      call daread(idaf,ioda,x(lvec),l1*l1,15,0)
      call daread(idaf,ioda,x(leig),nqmt,17,0)

      if(maswrk) then
         call rwrit(icif,'$HCORE',   L2, x(lH1))
         call rwrit(icif,'$OVERLAP', L2, x(lS))
         WRITE(icif,*) '$INFO'
         WRITE(icif,'(a8,a,i8)') 'NMO     ', '=', NQMT
         WRITE(icif,*) '$END'
      endif
C
      METHOD='RHF       '
      IF(SCFTYP.EQ.UHF) THEN
         METHOD='UHF       '
      else if(scftyp.eq.rohf) then
         METHOD='ROHF      '
      endif
      LENMTH = LSTRNG(METHOD,10)
      if(maswrk) then
      WRITE(icif,*) '$ENERGY'
      WRITE(icif,'(''E('',A,'')='',F20.10)') METHOD(1:LENMTH),ETOT
      WRITE(icif,'(''E(NUC)='',F16.10)') ENUCR
      WRITE(icif,*) '$END'
      endif
C
      IF (SCFTYP.EQ.RHF.and.maswrk) THEN
         call rwrit(icif,'$AO-FOCK',L2, X(LFAO))
         call rwrit(icif,'$DEN-MTX',L2, X(LD))
      ELSE IF (SCFTYP.EQ.ROHF.and.maswrk) THEN
         call rwrit(icif,'$AO-FOCK-A',L2, X(LFAO))
         call rwrit(icif,'$AO-FOCK-B',L2, X(LFB))
         call rwrit(icif,'$DEN-MTX-A',L2, X(LD))
         call rwrit(icif,'$DEN-MTX-B',L2, X(LDB))
      ENDIF
      if(maswrk) call rwrit(icif,'$EIGVAL', NQMT, X(LEIG))
      if(maswrk) call rwrit(icif,'$VEC', L1*NQMT, X(LVEC))
C
      CALL CALCOM(XP,YP,ZP)
      CALL DIPINT(XP,YP,ZP,.false.)
      CALL DAREAD(IDAF,IODA,X(LTRI),L2,95,0)
      if(maswrk) call rwrit(icif,'$AO-DIPOLE-X', L2, X(LTRI))
      CALL DAREAD(IDAF,IODA,X(LTRI),L2,96,0)
      if(maswrk) call rwrit(icif,'$AO-DIPOLE-Y', L2, X(LTRI))
      CALL DAREAD(IDAF,IODA,X(LTRI),L2,97,0)
      if(maswrk) call rwrit(icif,'$AO-DIPOLE-Z', L2, X(LTRI))
      call flshbf(icif)
      call retfm(need)
C
 1010 FORMAT(1X,'$CIMINP'/
     * 'BUFDST=',1P,E10.2/
     * 'CCONV =',1P,E10.2/
     * 'MOFIX =',I10/
     * 'MRGSUB=',I10/
     * 'SUBMTD=',A10/
     * 'SUBTYP=',A10/
     * 'MOSORT=',L10/
     * 'ATMMLK=',1P,E10.2/
     * 'ORTHO =',L10/
     * 'SUBRHF=',L10/
     * 'ETA   =',1P,E10.2/
     * 'ZETA  =',1P,E10.2/
     * 'ZETA1 =',1P,E10.2/
     * 'ZETA2 =',1P,E10.2/
     * 'CIMTYP=',A10/
     * 'ENRGML=',A10/
     * 'FCORE =',L10/
     * 'CIMORB=',A10/
     * 'DISLMO=',1P,E10.2/
     * 'HDIS  =',1P,E10.2/
     * 'CONVIR=',1P,E10.2/
     * 'TWOBDY=',1P,E10.2/
     * 1X,'$END',0P)
 9000 FORMAT(A10,f6.1,1x,3F15.10)
 9050 FORMAT(3X,A8,I4)
 9100 FORMAT(3X,I3,1X,F20.10,2F15.8)
      end

      subroutine ciminp
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      LOGICAL GOPARR,DSKWRK,MASWRK,OK
      LOGICAL CIMFRG
      logical cimatm
      PARAMETER (mxatm=2000)
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      COMMON /IOFILE/ IR,IW,IP,IJK,IJKT,IDAF,NAV,IODA(950)
      COMMON /CIMINF/ ICIM,ICIF,MOTYP2,NCA,NCB,NFRG
      LOGICAL MOSORT,ORTHO,SUBRHF,FCORE,restrt,runsub
      common /CIMPAR/ bufdst,cconv,mrgsub,submtd,
     *                subtyp,mosort,atmmlk,ortho,subrhf,
     *                eta,zeta,zeta1,zeta2,cimtyp,enrgml,
     *                fcore,mtdatm(mxatm),runsub,restrt,MOFIX,
     *                CIMORB,DISLMO,HDIS,CONVIR,TWOBDY
      COMMON /INFOA / NAT,ICH,MUL,NUM,NQMT,NE,NA,NB,
     *                ZAN(MXATM),C(3,MXATM),IAN(MXATM)
      COMMON /WFNOPT/ SCFTYP,VBTYP,DFTYPE,TDDFTYP,CITYP,CCTYP,
     *                MPLEVL,MPCTYP
      COMMON /FMCOM / X(1)
      PARAMETER (NNAM=23)
      DIMENSION QNAM(NNAM),KQNAM(NNAM)
      DATA QNAM/8HBUFDST  ,8HCCONV   ,8HMRGSUB  ,8HSUBMTD  ,
     *          8HSUBTYP  ,8HMOSORT  ,8HATMMLK  ,
     *          8HORTHO   ,8HSUBRHF  ,8HETA     ,8HZETA    ,
     *          8HZETA1   ,8HZETA2   ,8HCIMTYP  ,8HMTDCIM  ,
     *          8HENRGML  ,8HFCORE   ,8HMOFIX   ,8HCIMORB  ,
     *          8HDISLMO  ,8HHDIS    ,8HCONVIR  ,8HTWOBDY  /
      DATA KQNAM/3,3,1,5,  5,0,3, 0,0,3,3, 3,3,5,1, 5,0,1,5, 3,3,3,3/
      DATA GROUP/8HCIMINP  /
      DATA RNONE/8HNONE    /
      DATA QCMO /8HQCMO    /
      DATA PLMO /8HLMO     /
      DATA AVERAGE/8HAVERAGE /
      DATA HIGHER /8HHIGHER  /
      DATA SECIM  /8HSECIM   /
      DATA DECIM  /8HDECIM   /
      DATA GSECIM /8HGSECIM  /
C     These are the only methods available for use with CIM
      DATA EMPTY  /8HEMPTY   /
      DATA HF     /8HHF      /  !0 
      DATA RIMP2  /8HRIMP2   /  !1
      DATA rMP2   /8HMP2     /  !2
      DATA CCD    /8HCCD     /  !3
      DATA CCSD   /8HCCSD    /  !4
      DATA CCSDPT /8HCCSD(T) /  !5
      DATA CRCCL  /8HCR-CCL  /  !6
C
      COMMON /RUNOPT/ RUNTYP,EXETYP,NEVALS,NGLEVL,NHLEVL
      DATA CIMFINAL/8HCIMFINAL/
      DATA UHF    /8HUHF     /
      DATA HFLMO  /8HHFLMO   /
      DATA CHOLMO /8HCHOLMO  /
      DATA CHOLSK /8HCHOLSK  /

C     DEFAULTS
      bufdst=4.0d0
      cconv=1.0d-6
      mrgsub=1
      submtd=empty
      subtyp=qcmo
      mosort=.true.
      atmmlk=0.10d0
      ortho=.false.
      subrhf=.true.
C     --- Guoyang Modified --
C      eta=0.05d0
      eta=0.1d0
C     --- Guoyang Modified Over--
      zeta=0.003d0
      zeta1=0.01d0
      zeta2=0.05d0
      enrgml=average
      fcore=.true.
      mtdcim=0
      MOFIX=0
      CIMORB=HFLMO
      DISLMO=5.0D+00
      HDIS=3.5D+00
      CONVIR=0.05D+00
      TWOBDY=-1.0D+00

      do i=1,mxatm
         mtdatm(i)=-1
      enddo

      CALL NAMEIO(IR,JRET,GROUP,NNAM,QNAM,KQNAM,
     *            BUFDST,CCONV,MRGSUB,SUBMTD,
     *            subtyp,MOSORT,atmmlk,
     *            ORTHO,SUBRHF,ETA,ZETA,ZETA1,ZETA2,
     *            CIMTYP,mtdcim,enrgml,fcore,MOFIX,
     *            CIMORB,DISLMO,HDIS,CONVIR,TWOBDY,
     *            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     *            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     *            0,0,0,0,0,0,0)
      IF(JRET .EQ. 2) THEN
         IF (MASWRK) WRITE (IW,1000)
         CALL ABRT
      END IF
      NERR = 0
C
C Check spelling and sanity of SUBMTD
      ok=.false.
      if(submtd.eq.rnone)  ok=.true.
      if(submtd.eq.hf) then
         ok=.true.
         submtd=rnone
      endif
      if(submtd.eq.rimp2)  ok=.true.
      if(submtd.eq.rmp2)   ok=.true.
      if(submtd.eq.ccd)    ok=.true.
      if(submtd.eq.ccsd)   ok=.true.
      if(submtd.eq.ccsdpt) ok=.true.
      if(submtd.eq.crccl)  ok=.true.
      if(submtd.eq.empty)  ok=.false.
      IF(.NOT.OK) THEN
         NERR = NERR+1
         if(maswrk.and.nerr.eq.1) write(iw,1003)
         IF (MASWRK) WRITE(IW,1002) 'SUBMTD  ',submtd
         if(maswrk) write(iw,1004)
      END IF
      if(submtd.eq.rnone .and. cimtyp.eq.decim) then
         nerr=nerr+1
         if(maswrk) write(iw,*)
         if(maswrk) write(iw,*) 'SUBMTD IS REQUIRED FOR DECIM'
         if(maswrk) write(iw,*)
      endif
      ok=.false.
      if(subtyp.eq.qcmo) ok=.true.
      if(subtyp.eq.plmo) ok=.true.
      IF(.NOT.OK) THEN
         IF (MASWRK) WRITE(IW,1002) 'SUBTYP',subtyp
         if(maswrk) write(iw,1006)
         NERR = NERR+1
      END IF
C
      ok=.false.
      if(enrgml.eq.higher)  ok=.true.
      if(enrgml.eq.average) ok=.true.
      IF(.NOT.OK) THEN
         IF (MASWRK) WRITE(IW,1002) 'ENRGML  ',enrgml
         if(maswrk) write(iw,1009)
         NERR = NERR+1
      END IF
C
      if(mrgsub.ne.0 .and. mrgsub.ne.1. and. mrgsub.ne.2) then
         NERR = NERR+1
         if(maswrk.and.nerr.eq.1) write(iw,1003)
         IF (MASWRK) WRITE(IW,1007)
      endif
C
      if(MOFIX.ne.0 .and. MOFIX.ne.1 .and. MOFIX.ne.2 .and. 
     &                                            MOFIX.ne.3) then
         NERR = NERR+1
         if(maswrk.and.nerr.eq.1) write(iw,1003)
         IF (MASWRK) WRITE(IW,1010)
      endif
C
      if(subtyp.eq.plmo .and. submtd.ne.ccsd.and.submtd.ne.rnone) then
         NERR = NERR+1
         if(maswrk.and.nerr.eq.1) write(iw,1003)
         if(maswrk) write(iw,1008)
      endif
C
      if(SCFTYP.eq.UHF) then
         NERR = NERR+1
         if(maswrk) write(iw,1015)
      endif
C
      ok=.false.
      if(CIMORB.eq.HFLMO)  ok=.true.
      if(CIMORB.eq.CHOLMO) ok=.true.
      if(CIMORB.eq.CHOLSK) ok=.true.
      IF(.NOT.OK) THEN
         IF (MASWRK) WRITE(IW,1002) 'CIMORB  ',CIMORB
         if(maswrk) write(iw,1017)
         NERR = NERR+1
      END IF
C
      if (CIMORB.eq.CHOLMO .or. CIMORB.eq.CHOLSK) then
c        if (FCORE) then
c           NERR = NERR+1
c           if(maswrk) write(iw,1019)
         if (cimtyp.ne.SECIM.and.cimtyp.ne.GSECIM) then
            NERR = NERR+1
            if(maswrk) write(iw,1021)
         endif
         if(maswrk.and.nerr.eq.1) write(iw,1003)
      endif
C
C
C Find $CIMFRG for use with gsecim only
C
      ieof=0
      cimfrg=.false.
      call seqrew(ir)
      call fndgrp(ir,' $CIMFRG ',IEOF)
      if(ieof.eq.0) then
         cimfrg=.true.
      endif
      if(cimtyp.ne.gsecim .and. cimfrg) then
            nerr=nerr+1
            if(maswrk) write(iw,1012)
      else if(cimtyp.eq.gsecim .and. .not.cimfrg) then
            nerr=nerr+1
            if(maswrk) write(iw,1011)
      endif
C
C Find $CIMATM for use with multi-level SECIM only
C
      ieof=0
      cimatm=.false.
      call seqrew(ir)
      call fndgrp(ir,' $CIMATM ',IEOF)
      if(ieof.eq.0) then
         cimatm=.true.
      endif
      if(cimtyp.ne.secim .and. cimatm) then
         nerr=nerr+1
         if(maswrk) write(iw,1013)
      endif
      if(cimatm) then
         call valfm(loadfm)
         llevl = loadfm+1
         lgrp  = llevl + nat
         last  = lgrp  + nat*nat
         need  = last - loadfm - 1
         call getfm(need)
         call rdcimatm(nat,x(llevl),x(lgrp))
         call retfm(need)
      endif
      do i=1,nat
         if(mtdatm(i).eq.-1) then
            if(submtd.eq.rnone)  mtdatm(i)=0
            if(submtd.eq.rimp2)  mtdatm(i)=1
            if(submtd.eq.rmp2)   mtdatm(i)=2
            if(submtd.eq.ccd)    mtdatm(i)=3
            if(submtd.eq.ccsd)   mtdatm(i)=4
            if(submtd.eq.ccsdpt) mtdatm(i)=5
            if(submtd.eq.crccl)  mtdatm(i)=6
         endif
      enddo
C
C     Make sure the user has actually asked to perform
C     a CIM calculation (at least one atom or group must
C     have a method)
C
      if(submtd.eq.rnone) then
         if(cimtyp.eq.gsecim.and..not.cimfrg) then
            nerr=nerr+1
            if(maswrk) write(iw,*)
            if(maswrk) write(iw,*) 'PLEASE SET SUBMTD OR ADD $CIMFRG'
            if(maswrk) write(iw,*)
         endif
         if(cimtyp.eq.secim.and..not.cimatm) then
            nerr=nerr+1
            if(maswrk) write(iw,*)
            if(maswrk) write(iw,*) 'PLEASE SET SUBMTD OR ADD $CIMATM'
            if(maswrk) write(iw,*)
         endif
      endif
C
      do i=1,nat
         if(mtdatm(i).eq.-1) then
            if(maswrk.and.cimatm)
     *         write(iw,*) '$CIMATM HAS NOT BEEN READ PROPERLY'
            if(maswrk.and.cimfrg)
     *         write(iw,*) '$CIMFRG HAS NOT BEEN READ PROPERLY'
            call abrt
         endif
      enddo
C
C     Restart is from complete Subsystem correlation
C     energies found in xx.Sys-[0-9].cim
C     If subsystems have not been made, you might as
C     well just read the $VEC and rerun the HF.
C
      if(mtdcim.eq.0) then
         runsub=.true.
         restrt=.false.
      else if(mtdcim.eq.1) then
         runsub=.false.
         restrt=.false.
      else if(mtdcim.eq.2) then
         runsub=.true.
         restrt=.true.
         runtyp=cimfinal
C        This runtyp is hidden and will not be accepted
C        if included in the input file
      else
         IF (MASWRK) WRITE(IW,1020) 'MTDCIM  ',mtdcim
         nerr=nerr+1
      endif
C
      IF(NERR.GT.0) THEN
C        IF (MASWRK) WRITE(IW,1003)
         CALL ABRT
      END IF
C
      if (TWOBDY.lt.-0.01D+00) TWOBDY=6.0D+00  !1.5D+00*DISLMO
C
      if(maswrk) then
         write(iw,1001)
     *            BUFDST,CCONV,mrgsub,SUBMTD,
     *            subtyp,MOFIX,MOSORT,atmmlk,
     *            ORTHO,SUBRHF,ETA,ZETA,ZETA1,ZETA2,
     *            CIMTYP,mtdcim,enrgml,fcore,CIMORB,
     *            DISLMO,HDIS,CONVIR,TWOBDY
      endif
C
C This is the unit number of the CIMFILE.
C
      icif=191
      return
 1000 FORMAT(1X,'TYPING ERROR IN $CIMINP INPUT - CHECK NEAR $ MARKER')
 1001 FORMAT(/5X,'$CIMINP OPTIONS'/5X,15(1H-)/
     * 1X,'BUFDST=',1P,E8.1,5X,'CCONV =',1P,E8.1,5X,
     * 'MRGSUB=',I8/
     * 1X,'SUBMTD=',   A8  ,5X,'SUBTYP=',A8,5X,
     * 'MOFIX=',I8/
     * 1X,'MOSORT=',   L8  ,5X,'ATMMLK=',1P,E8.1,5X,
     * 'ORTHO =',L8/
     * 1X,'SUBRHF=',   L8  ,5X,'ETA   =',1P,E8.1,5X,
     * 'ZETA  =',1P,E8.1/
     * 1X,'ZETA1 =',1P,E8.1,5X,'ZETA2 =',1P,E8.1/
     * 1X,'CIMTYP=',A8,5X,'MTDCIM=',I8,5x,'ENRGML=',A8/
     * 1X,'FCORE =',L8,5X,'CIMORB=',A8/
     * 1X,'DISLMO=',E8.1,5X,'HDIS=',E8.1/
     * 1x,'CONVIR=',E8.1,5X,'TWOBDY=',E8.1,0p)
 1002 FORMAT(/1X,'ERROR: $CIMINP KEYWORD ',A6,
     *          ' WAS GIVEN AN ILLEGAL VALUE ',A8,'.'/)
 1020 FORMAT(/1X,'ERROR: $CIMINP KEYWORD ',A6,
     *          ' WAS GIVEN AN ILLEGAL VALUE ',I8,'.'/)
 1003 FORMAT(/1X,'             *** ERROR(S) DETECTED ***'/
     *        1X,'YOUR $CIMINP INPUT HAS AT LEAST ONE SPELLING OR',
     *           ' LOGIC MISTAKE.'/
     *        1X,'PLEASE REVIEW THE REASON(S) JUST LISTED, AND TRY',
     *           ' YOUR RUN AGAIN.'/)
 1004 FORMAT(/1X,'SUBMTD   MAY BE NONE OR HF'/
     *        1X,'                RIMP2'/
     *        1X,'                MP2'/
     *        1X,'                CCD'/
     *        1X,'                CCSD'/
     *        1X,'                CCSD(T)'/
     *        1X,'                CR-CCL'/)
 1006 FORMAT(/1X,'SUBTYP   MAY BE QCMO'/
     *        1X,'                LMO'/)
 1009 FORMAT(/1X,'ENRGML   MAY BE AVERAGE'/
     *        1X,'                HIGHER'/)
 1007 FORMAT(/1X,'MRGSUB   MAY BE 0, 1, OR 2'/)
 1008 FORMAT(/1X,'SUBTYP=LMO CAN ONLY BE USED WITH CCSD METHOD'/)
 1010 FORMAT(/1X,'MOFIX   MAY BE 0, 1, 2 OR 3'/)
 1011 FORMAT(/1x,'WHEN CIMTYP=GSECIM $CIMFRG MUST BE SPECIFIED'/)
 1012 FORMAT(/1X,'WHEN $CIMFRG IS PRESENT CIMTYP CAN ONLY BE GSECIM'/)
 1013 FORMAT(/1X,'$CIMATM CANNOT BE SPECIFIED WHEN CIMTYP.NE.SECIM'/)
 1015 FORMAT(/1X,'SCF=UHF CAN NOT BE USED FOR CIM CALCULATION'/)
 1017 FORMAT(/1X,'CIMORB   MAY BE HFLMO'/
     *        1X,'                CHOLMO'/
     *        1X,'                CHOLSK'/)
 1019 FORMAT(/1X,'CIMORB=CHOLMO OR CHOLSK MUST BE COMBINED WITH',
     *           ' FCORE=.FALSE.'/)
 1021 FORMAT(/1X,'CIMORB=CHOLMO OR CHOLSK CAN NOT BE COMBINED WITH',
     *           ' CIMTYP=DECIM'/)
      end
C
      subroutine runcimsub(nsubsystems)
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      parameter (mxatm=2000,mxrt=100)
      LOGICAL MOSORT,ORTHO,SUBRHF,FCORE,restrt,runsub
      common /CIMPAR/ bufdst,cconv,mrgsub,submtd,
     *                subtyp,mosort,atmmlk,ortho,subrhf,
     *                eta,zeta,zeta1,zeta2,cimtyp,enrgml,
     *                fcore,mtdatm(mxatm),runsub,restrt,MOFIX,
     *                CIMORB,DISLMO,HDIS,CONVIR,TWOBDY
C     common /CIMFULL/ cimrun,cimcont,irest2
C     logical cimrun,cimcont
      logical exst
      COMMON /CIMINF/ ICIM,ICIF,MOTYP,NCA,NCB,NFRG
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      COMMON /OUTPUT/ NPRINT,ITOL,ICUT,NORMF,NORMP,NOPK
      LOGICAL GOPARR,DSKWRK,MASWRK
      COMMON /OPTSCF/ DIRSCF,FDIFF
      logical dirscf,fdiff
      COMMON /IOFILE/ IR,IW,IP,IS,IPK,IDAF,NAV,IODA(950)
      COMMON /ENRGYS/ ENUCR,EELCT,ETOT,SZ,SZZ,ECORE,ESCF,EERD,E1,E2,
     *                VEN,VEE,EPOT,EKIN,ESTATE(MXRT),STATN,EDFT(2)
      COMMON /FUNCT / E,EG(3,MXATM)
      COMMON /WFNOPT/ SCFTYP,VBTYP,DFTYPE,TDDFTYP,CITYP,CCTYP,
     *                MPLEVL,MPCTYP
      COMMON /RUNOPT/ RUNTYP,EXETYP,NEVALS,NGLEVL,NHLEVL
      data rnone /8HNONE    /
      character*100 gmsname,subname,inpname,cimname,punname
      character*500 line
C
C This is the automated calculation of subsystem correlation energies
C mtdcim=0 in $CIMINP (default)
C
      if(.not.runsub) then
         if(maswrk) then
            write(iw,*) 
            write(iw,*) 'Please run the subsystem inputs separately'
            write(iw,*)
         endif
         return
      endif
C
      if(maswrk) then
         write(iw,*)
         write(iw,'(10x,38(1h-))')
         write(iw,'(10x,"CIM SUBSYSTEM CORRELATION CALCULATIONS")')
         write(iw,'(10x,38(1h-))')
         write(iw,*)
      endif
      call flshbf(iw)
C Save the current state of the run
C It should always be energy
      runsav=runtyp
      nprintsav=nprint
      CALL DAWRIT(IDAF,IODA,ENUCR,MXRT+15,2,0)
C
      CALL GMS_GETENV('CIMINP',gmsname)
      call seqclo(icif,'keep')
      call seqclo(ir,'keep')
      if(.not.dirscf) then
         call seqclo(8,'keep')
      endif
C File 9 should not have been made since only SCF was required
C     call seqclo(9,'keep')
C
      do 1001 i=1,nsubsystems
         CALL GMS_GETENV('CIMINP',gmsname)
         call NJ_trim(gmsname,k1,k2)
         write(line,*) I
         call NJ_trim(line,k3,k4)
         subname=gmsname(k1:k2-3)//'Sys-'//line(k3:k4)
         inpname=subname(1:len_trim(subname))//'.inp'
         cimname=subname(1:len_trim(subname))//'.cim'
         punname=subname(1:len_trim(subname))//'.dat'
C Subsystems can write correlation output to a different file
C        outname=subname(1:len_trim(subname))//'.gamess'
C
C For now, just do what you can, if the .cim files is present, 
C perhaps it was run by hand.
         inquire(file=inpname,exist=exst)
         if(.not. exst) then
            if(maswrk)
     &      write(iw,"(' Subsystem ',i3,' does not exist.')") i
            goto 1001
         endif
         inquire(file=cimname,exist=exst)
         if(exst) then
            if(maswrk)
     &      write(iw,"(' Subsystem ',i3,' cim file exists.')") i
            goto 1001
         endif
C
C        First, close all files that might have been used by
C        previous subsystems.
C        All work files for the subsystem are independent
C        of the original so I will now open new ones.
         ip=193
         idaf=194
         ir=195
         is=108
         ipk=109
         call seqclo(idaf,'delete')
         call seqclo(is,'delete')
         call seqclo(ipk,'delete')
         do j=70,99
            call seqclo(j,'delete')
         enddo
C
         call seqopn(is,'CIMAOI','UNKNOWN',.false.,'UNFORMATTED')
         call seqopn(ipk,'CIMMOI','UNKNOWN',.false.,'UNFORMATTED')
         open(icif,file=cimname,form='formatted')
         open(ir,file=inpname,form='formatted')
         open(ip,file=punname,form='formatted')
C 
         if(maswrk) then
            write(iw,'(1x,".... SUBSYSTEM ",i3," STARTED  ....")') i
            call flshbf(iw)
         endif
         call cimsubstart
C
         close(icif)
         close(ir)
         close(ip,status='DELETE')
         if(maswrk) then
            write(iw,'(1x,".... SUBSYSTEM ",i3," FINISHED ....")') i
            call flshbf(iw)
         endif
         
 1001 continue
C Set the unit numbers back to the full system
      ir=5
      ip=7
      is=8
      ipk=9
      idaf=10
C
C THE FINAL CIM ENERGY
C
      write(iw,*)
      call cimf(finalenergy,.true.)
      CALL daread(IDAF,IODA,ENUCR,MXRT+15,2,0)
      etot=finalenergy
      e=etot
      CALL DAWRIT(IDAF,IODA,ENUCR,MXRT+15,2,0)
C
C ALL DONE.  JUST MAKE SURE WE EXIT GRACEFULLY
C
      CALL SEQOPN(IR,'INPUT', 'OLD',.TRUE., 'FORMATTED')
      runtyp=runsav
C     cimrun=.false.
      nprint=nprintsav
      mplevl=0
      cctyp=rnone
C
      return
      end


      subroutine cimsubstart
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
C     common /CIMFULL/ cimrun,cimcont,irest2
C     logical cimrun,cimcont
      DATA CIMSUB/8HCIMSUB  /
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      LOGICAL GOPARR,DSKWRK,MASWRK
      COMMON /IOFILE/ IR,IW,IP,IS,IPK,IDAF,NAV,IODA(950)
C read cimsub input and run correlation method

C     cimrun=.true.
      CALL cimsubinp
C
      CALL VALFM(INITFM)
C
C     GET MEMORY FOR IN CORE 2E INTEGRALS
C
      CALL INT2EIC(0)
C
      call cimx(cimsub)
C
C     RETURN MEMORY FOR IN CORE 2E INTEGRALS
C
      CALL INT2EIC(1)
C
C        ----- ALL DONE -----
C
      CALL VALFM(LASTFM)
      IF(LASTFM.NE.INITFM  .AND.  MASWRK) WRITE(IW,9100) LASTFM-INITFM
C     CALL BIGFM(MAXMEM)
      CALL TMDATE(TIMSTR)
      return
 9100 FORMAT(///'* * * * ERROR3 * * * *'/
     *      1X,'MEMORY LEAK DETECTED.',I10,
     *         ' WORDS ARE STILL ALLOCATED SOMEWHERE'///)
      end


      subroutine cimsubinp
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
      LOGICAL PACK2E,LINEAR,OK,GOPARR,DSKWRK,MASWRK,AIMPAC,PLTORB,
     *        MOLPLT,RPAC,MPTEST,
     *        NUMGRD,GRDTST
      PARAMETER (MXAO=8192, MXATM=2000)
      CHARACTER*4 ATM
      CHARACTER*8 CXBASIS
      DOUBLE PRECISION LCCD
      COMMON /BASSPH/ QMATOL,NSPHER
      COMMON /CXTHRM/ CXTHERM(11),CXZPE,METHCX,ICXBAS,CXBASIS
      COMMON /FF    / NFFLVL
      COMMON /GEOMOP/ GEOM
      COMMON /IJPAIR/ IA(MXAO)
      COMMON /INFO  / CDUM(MXATM,3),IZAN(MXATM),NATOMS,IUNTRD,ATM(MXATM)
      COMMON /INFOA / NAT,ICH,MUL,NUM,NQMT,NE,NA,NB,
     *                ZAN(MXATM),C(3,MXATM),IAN(MXATM)
      COMMON /INTFIL/ NINTMX,NHEX,NTUPL,PACK2E,INTTYP,IGRDTYP
      COMMON /INTOPT/ ISCHWZ,IECP,NECP,IEXTFLD
      COMMON /INTRFC/ FRIEND,AIMPAC,RPAC,PLTORB,MOLPLT
      COMMON /IOFILE/ IR,IW,IP,IS,IPK,IDAF,NAV,IODA(950)
      COMMON /MASSES/ ZMASS(MXATM)
      COMMON /OUTPUT/ NPRINT,ITOL,ICUT,NORMF,NORMP,NOPK
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      COMMON /PRPOPT/ ETOLLZ,ILOCAL
      COMMON /PSILVL/ IPSI,ISKPRP
      COMMON /RELWFN/ RMETHOD,QRQMT,CLIG,CLIG2,QRTOL,IQRORD,MODQR,NESOC,
     *                NRATOM,NUMU,NQMTR,NQRDAF,MORDA,NDARELB
      COMMON /RESTAR/ TIMLIM,IREST,NREC,INTLOC,IST,JST,KST,LST
      COMMON /RUNOPT/ RUNTYP,EXETYP,NEVALS,NGLEVL,NHLEVL
      COMMON /SCFOPT/ CONVHF,MAXIT,MCONV,NPUNCH,NPREO(4)
      COMMON /SOOPT / NOSO
      COMMON /WFNOPT/ SCFTYP,VBTYP,DFTYPE,TDDFTYP,CITYP,CCTYP,
     *                MPLEVL,MPCTYP
      COMMON /ZMAT  / NZMAT,NZVAR,NVAR,NSYMC,LINEAR
      COMMON /ZMTALT/ NZMAT2,NZVAR2,NVAR2,NZMTRD,ICOORD
C This is a copy and truncation of START for the purpose of 
C reading cim subsystem input files (runtyp=cimsub)
C
C      ----- SET UP NAMELIST $CONTRL TABLES -----
C
      PARAMETER (NNAM=41)
      DIMENSION QNAM(NNAM),KQNAM(NNAM)
      DATA CONTRL /8HCONTRL  /
      DATA QNAM/8HSCFTYP  ,8HRUNTYP  ,8HEXETYP  ,8HICHARG  ,
     *          8HMULT    ,8HUNITS   ,8HINTTYP  ,8HLOCAL   ,
     *          8HMAXIT   ,8HNPRINT  ,8HIREST   ,8HNORMF   ,
     *          8HNORMP   ,8HITOL    ,8HICUT    ,8HNZVAR   ,
     *          8HNOSYM   ,8HGEOM    ,8HMPLEVL  ,8HAIMPAC  ,
     *          8HPP      ,8HECP     ,8HPLTORB  ,8HMOLPLT  ,
     *          8HCOORD   ,8HFRIEND  ,8HNOSO    ,8HCITYP   ,
     *          8HCCTYP   ,8HISPHER  ,8HQMTTOL  ,8HRELWFN  ,
     *          8HNUMGRD  ,8HGRDTST  ,8HGRDTYP  ,8HVBTYP   ,
     *          8HDFTTYP  ,8HTDDFT   ,8HISKPRP  ,8HNFFLVL  ,
     *          8HETOLLZ  /
      DATA KQNAM /5,5,5,1,  1,5,5,5,  1,1,1,1,  1,1,1,1,
     *            1,5,1,0,  5,5,0,0,  5,5,1,5,  5,1,3,5,
     *            0,0,5,5,  5,5,1,1,  3/ 
C
      DATA BLANK/8H        /, RUN/8HRUN      /
C
      DATA NONE,RNONE/4HNONE,8HNONE    /
      DATA RHF,ROHF/8HRHF     ,8HROHF    /
      data ccd  /8HCCD     /
      data ccsd /8HCCSD    /
      data crccl/8HCR-CCL  /
      data lccd /8HLCCD    /
      data ccsdt/8HCCSD(T) /
      data rimp2/8HRIMP2   /
C
      DATA CIMSUB            /8HCIMSUB  /
C
      DATA HONDO,POPLE/8HHONDO   ,8HPOPLE   /
      DATA BEST,ROTAX,RYS,ERIC
     *      /8HBEST    ,8HROTAXIS ,8HRYSQUAD ,8HERIC    /
      DATA SCHLEGEL/8HSCHLEGEL/
      DATA ANGST,ANGS,BOHR/8HANGSTROM,8HANGS    ,8HBOHR    /
      data unique/8HUNIQUE  /
      DATA      RINPUT/8HINPUT   /
C
      call seqrew(ir)
C     ----- INITIALIZE VARIABLES FOR NAMELIST $CONTRL -----
C
      SCFTYP = BLANK
      RUNTYP = BLANK
      EXETYP = RUN
      ICHARG = 0
      MULT   = 1
      UNITS  = BLANK
      TYPINT = BEST
      GRDTYP = SCHLEGEL
      TLOCAL = BLANK
      MAXIT  = 30
      NPRINT2 = 7
      IREST = 0
      NORMF = 0
      NORMP = 0
      ITOL  = 20
      ICUT  = 9
      NZVAR = 0
      NOSYM = 0
      GEOM  = BLANK
      MPLEVL= 0
      PP    = BLANK
      ECP   = BLANK
      AIMPAC=.FALSE.
      PLTORB=.FALSE.
      MOLPLT=.FALSE.
      COORD = BLANK
      FRIEND= BLANK
      ISPHER= -1
      QMTTOL= 1.0D-06
      RMETHOD= RNONE
      RPAC  =.FALSE.  !   DEFUNCT OPTION
      NUMGRD=.FALSE.
      GRDTST=.FALSE.
C
C     INITIALIZE SOME WAVEFUNCTION INFORMATION
C
      CITYP   = rnone
      CCTYP   = RNONE
      MPCTYP  =  NONE
      VBTYP   = RNONE
      DFTYPE  = RNONE
      TDDFTYP = RNONE
      ISKPRP  = 0
      ETOLLZ  = -1.0D+00
C
C        ----- READ NAMELIST $CONTRL -----
C
      JRET = 0
      CALL NAMEIO(IR,JRET,CONTRL,NNAM,QNAM,KQNAM,
     *            SCFTYP,RUNTYP,EXETYP,ICHARG,MULT,UNITS,TYPINT,TLOCAL,
     *            MAXIT,NPRINT2,IREST,NORMF,NORMP,ITOL,ICUT,NZVAR,
     *            NOSYM,GEOM,MPLEVL,AIMPAC,PP,ECP,PLTORB,MOLPLT,
     *            COORD,FRIEND,NOSO,CITYP,CCTYP,ISPHER,QMTTOL,RMETHOD,
     *            NUMGRD,GRDTST,GRDTYP,VBTYP,DFTYPE,TDDFTYP,ISKPRP,
     *            NFFLVL,ETOLLZ,0,0,0,
     *   0,0,0,0,0,    0,0,0,0,0,   0,0,0,0,0,   0,0,0,0,0)
      IF(JRET .EQ. 2) THEN
         IF (MASWRK) WRITE (IW,9005)
         CALL ABRT
      END IF
      NERR = 0
C
C     TURN OFF USE OF SYMMETRY ORBITAL CODE FOR MOROKUMA ANALYSIS
C
      ICH = ICHARG
      MUL = MULT
      NSPHER = ISPHER
      QMATOL = QMTTOL
      IF(NORMF.NE.1) NORMF = 0
      IF(NORMP.NE.1) NORMP = 0
C
C         CHECK SPELLING ON VARIOUS OPTIONS
C
      OK = .FALSE.
      IF(SCFTYP.EQ.BLANK) SCFTYP = RHF
      IF(SCFTYP.EQ.RHF)   OK=.TRUE.
      IF(SCFTYP.EQ.ROHF)  OK=.TRUE.
      IF(.NOT.OK) THEN
         IF (MASWRK) WRITE(IW,9010) 'SCFTYP',SCFTYP
         NERR = NERR+1
      END IF
C
      OK = .FALSE.
      IF(RUNTYP.EQ.cimsub) ok=.true.
      if(.not.ok) then
         if(maswrk) then
            write(iw,*) 'SUBSYSTEM RUNTYP CAN ONLY BE CIMSUB'
         endif
         nerr=nerr+1
      endif
C
C          CHECK SPELLINGS, BUT ALSO SET THE OPTION FLAGS
C
C        PRE-2004 INPUT FILES ASKING FOR POPLE/HONDO INTEGRAL
C        PACKAGES ARE JUST PEOPLE WHO DON'T KNOW ANY BETTER.
C        WHY NOT GIVE THEM THE VERY BEST?
C
      INTTYP = 8
      IF(TYPINT.EQ.POPLE) TYPINT=BEST
      IF(TYPINT.EQ.HONDO) TYPINT=BEST
      IF(TYPINT.EQ.BEST)  INTTYP = 0
      IF(TYPINT.EQ.ROTAX) INTTYP = 1
      IF(TYPINT.EQ.ERIC)  INTTYP = 2
      IF(TYPINT.EQ.RYS)   INTTYP = 3
      IF(INTTYP.EQ.8) THEN
         IF (MASWRK) WRITE(IW,9010) 'INTTYP',TYPINT
         NERR = NERR+1
      END IF
C
C        BEST GRADIENT TYPE MEANS FASTEST, ALMOST AS ACCURATE, NAMELY
C        USE BERNY SCHLEGEL'S S,P,L SPECIAL ROTATED AXIS GRADIENT CODES,
C        BUT USE RYS QUADRATURE FOR EVERYTHING ELSE.
C        TRADITIONAL NAMES OF POPLE/HONDO ARE MAPPED TO BEST/RYSQUAD.
C        NEW NAME SCHLEGEL (FAR MORE CORRECT THAN POPLE!) MEANS BEST.
C
      IGRDTYP = 8
      IF(GRDTYP.EQ.POPLE)    GRDTYP = BEST
      IF(GRDTYP.EQ.SCHLEGEL) GRDTYP = BEST
      IF(GRDTYP.EQ.HONDO)    GRDTYP = RYS
      IF(GRDTYP.EQ.BEST) IGRDTYP = 0
      IF(GRDTYP.EQ.RYS)  IGRDTYP = 2
      IF(IGRDTYP.EQ.8) THEN
         IF (MASWRK) WRITE(IW,9010) 'GRDTYP',GRDTYP
         NERR = NERR+1
      END IF
C
C         CHECK COORDINATE UNITS
C
      IUNTRD = 8
      IF(UNITS.EQ.BLANK) UNITS=ANGS
      IF(UNITS.EQ.ANGS  .OR.  UNITS.EQ.ANGST) IUNTRD = 1
      IF(UNITS.EQ.BOHR)  IUNTRD = -1
      IF(IUNTRD.EQ.8) THEN
         IF (MASWRK) WRITE(IW,9010) 'UNITS ',UNITS
         NERR = NERR+1
      END IF
C
      GEOM=RINPUT
C
C        FOR PEDAGOGIC REASONS, KEYWORD PP= IS INPUT FOR ECP OR MCP
C        FOR HISTORICAL REASONS, NAMELY ECP CAME FIRST IN GAMESS,
C        THE VARIABLES USED STORE MCP TYPES INTO ECP-SOUNDING NAMES,
C        AND BOTH PP= AND ECP= ARE ACCEPTABLE INPUT KEYWORDS.
C        PPs have not been checked with CIM
C
      IECP=8
      IF(PP.NE.BLANK)   ECP = PP
      IF(ECP.EQ.BLANK)  ECP = RNONE
      IF(ECP.EQ.RNONE)  IECP=0
      IF(IECP.EQ.8) THEN
         IF (MASWRK) WRITE(IW,9010) 'PP/ECP',ECP
         NERR = NERR+1
      END IF
C
      ICOORD = 8
      IF(COORD.EQ.BLANK)    COORD=UNIQUE
      IF(COORD.EQ.UNIQUE)   ICOORD = -1
      IF(ICOORD.EQ.8) THEN
         IF (MASWRK) WRITE(IW,9010) 'COORD ',COORD
         NERR = NERR + 1
      END IF
C
C     CHECK THE COUPLED CLUSTERS JOB
C
      OK = .FALSE.
      IF(CCTYP.EQ.RNONE)   OK=.TRUE.
      IF(CCTYP.EQ.LCCD)    OK=.TRUE.
      IF(CCTYP.EQ.CCD)     OK=.TRUE.
      IF(CCTYP.EQ.CCSD)    OK=.TRUE.
      IF(CCTYP.EQ.CCSDT)   OK=.TRUE.
      IF(CCTYP.EQ.CRCCL)   OK=.TRUE.
      IF(.NOT.OK) THEN
         IF(MASWRK) WRITE(IW,9010) 'CCTYP',CCTYP
         NERR=NERR+1
      END IF
C
      IF(MPLEVL.NE.2  .AND.  MPLEVL.NE.0) THEN
         IF(MASWRK) WRITE(IW,9080)
         NERR=NERR+1
      END IF
C
C     ----- ONE OR MORE ERRORS DETECTED, BLOW THE SUBSYSTEM AWAY -----
C
      IF(NERR.GT.0) THEN
         IF (MASWRK) WRITE(IW,9200)
         CALL ABRT
      END IF
C
C     ----- OPEN THE DIRECT ACCESS FILE -----
C
      IREDO = IABS(IREST)
      call opendac(iredo)
C
C     ----- READ $BASIS IF ANY ----
C
      ICXBAS=0
      CALL BASISS
C
C     ----- READ MOLECULE AND BASIS SET - $DATA GROUP -----
C
C        READ THE MOLECULE AND ITS NORMAL BASIS SET, OR POSSIBLY,
C        READ THE FOLDY-WOUTHUYSEN TRANSFORMED BASIS FOR 2E INTEGRALS
C        THIS BASIS SET IS "NORMAL" AND IS TO BE NORMALISED
C
         CALL MOLE(' $DATA  ',IUNTRD,ICOORD,.TRUE.)
C
C
C     ----- SAVE TRUE NUCLEAR CHARGES ------
C     ECP, MCP, AND FMO MAY MANIPULATE THE -ZAN- ARRAY LATER
C
      DO IAT=1,NAT
         IAN(IAT) = INT(ZAN(IAT)+0.001D+00)
      ENDDO
C
C     ----- FILL ATOMIC MASS TABLE (REQUIRES MOLECULE READ IN) -----
C
      CALL RAMS(ZMASS,0)
C
C     ----- KILL IF OPEN SHELL, BUT RHF TYPE -----
C
      IF(NA.NE.NB  .AND.  SCFTYP.EQ.RHF) THEN
         WRITE (IW,9230) NA,NB
         CALL ABRT
      END IF
C
C        THE DEFAULT IS NO APPLIED EXTERNAL ELECTRIC FIELD
C
      IEXTFLD=0
C
C     INITIALIZE SOME ECP PARAMETERS (FOR ALL RUNS, NOT JUST ECP).
C     POSSIBLE READ MODEL CORE POTENTIAL PARAMETERS
C
      CALL ECPPAR
      IF (IECP.EQ.5)  CALL MMPCOR(0)
C
C     ----- READ INPUT FOR POSSIBLE SOLVATION TREATMENTS -----
C     Solvent models not checked for use with CIM
C     CHECK FOR EFFECTIVE FRAGMENT POTENTIALS ($EFRAG)
      CALL EFINP(IUNTRD,IEF)
C
C     MAKE SURE NO MORE THAN ONE SOLVENT MODEL IS REQUESTED,
C     EXCEPT FOR THE COMBINATION OF EFP+PCM
C
      NSOLV = 0
      IF(IEF.EQ.1)  NSOLV=NSOLV+1
      IF(NSOLV.GT.1) THEN
         IF(MASWRK) WRITE(IW,9240)
         CALL ABRT
      END IF
C
C     ----- SCF INPUT -----
C
C     IF(SCFTYP.NE.RMC) THEN
         CALL SCFIN
         CALL MIINP
C     END IF
C
C     ----- INTEGRAL TRANSFORMATION INPUT -----
C     (MUST BE READ AFTER $SCF)
C
      CALL TRFIN
C
C     ----- INTGRL INPUT -----
C     (MUST BE READ AFTER $SCF, $TRANS, AND $LOCAL, BUT BEFORE $MP2)
C
      CALL INTIN
C
C     ----- MP2 INPUT -----
C     (MUST BE READ AFTER ALL THESE: $SCF/$MCSCF, $INTGRL, AND $SCRF)
C     -MPTEST- IS FOR SKIPPING INPUT SENSIBILITY TESTS WHILE CODING
C
      MPTEST=.FALSE.
      IF(MPLEVL.EQ.2) THEN
            CALL MP2INP(MPTEST)
      END IF
C
C     --- COUPLED CLUSTER/EQUATION OF MOTION INPUT ---
C
      IF(CCTYP.NE.RNONE) CALL CCINP
      if(cctyp.eq.crccl) call eominp(cctyp)
C
C        AT MOST, ONE CORRELATION METHOD IS TO BE ALLOWED.
C
      MCORR=0
      IF(CCTYP.NE.RNONE)   MCORR=MCORR+1
      IF(MPLEVL.GT.0)      MCORR=MCORR+1
      IF(MCORR.GT.1) THEN
         IF (MASWRK) WRITE(IW,9250)
         CALL ABRT
      END IF
C
C     NOW, CRASH AND BURN ANY -H- OR -I- BASIS FUNCTION RUN!
C     WHILE THE CARTESIAN GAUSSIAN INTEGRALS ARE OK, THERE ARE
C     NO PROGRAMS FOR HANDLING THEIR SYMMETRY PROPERTIES YET.
C     SEE THE DETAILED NOTE JUST BELOW...
C
      CALL BASCHK(LMAX)
      IF(LMAX.GE.5) THEN
         IF(MASWRK) WRITE(IW,*) 'NO H OR I FUNCTIONS ALLOWED'
         CALL ABRT
      END IF
C
C     ----- SET UP TRIANGULAR INDEX MATRIX -----
C
      DO 900 I = 1,MXAO
        IA(I) = (I*I-I)/2
  900 CONTINUE
C
C     ----- PREPARE FOR ORBITAL SYMMETRY ASSIGNMENTS -----
C     AND RESTORE /SYMSPD/ CARTESIAN SPACE TRANSFORMATIONS, IF NEEDED.
C     THIS IS KEPT HERE, AS SOME RUNS, LIKE PCM, TURN SYMMETRY OFF
C     FMO WILL CALL -SYMORB- LATER USING GENUINE (NOT ZERO) COORDINATES
C
        call symorb
C     IF (ICOORD.NE.4) THEN
C        IF(NFG.EQ.0) CALL SYMORB
C        IF(ISPHER.GT.0) CALL SPDTR
C     END IF
C
      IF (MASWRK) WRITE(IW,9700)
      CALL TIMIT(1)
      RETURN
C
 9005 FORMAT(1X,'TYPING ERROR IN $CONTRL INPUT - CHECK NEAR $ MARKER')
 9010 FORMAT(/1X,'ERROR: $CONTRL KEYWORD ',A6,
     *          ' WAS GIVEN AN ILLEGAL VALUE ',A8,'.'/)
 9080 FORMAT(/1X,'ERROR: ONLY MPLEVL=2 IS POSSIBLE AT PRESENT.'/)
 9200 FORMAT(/1X,'             *** ERROR(S) DETECTED ***'/
     *        1X,'YOUR $CONTRL INPUT HAS AT LEAST ONE SPELLING OR',
     *           ' LOGIC MISTAKE.'/
     *        1X,'PLEASE REVIEW THE REASON(S) JUST LISTED, AND TRY',
     *           ' YOUR RUN AGAIN.'/)
C
 9230 FORMAT(/1X,'ERROR: AN ODD NUMBER OF ELECTRONS IS IMPOSSIBLE',
     *           ' WITH RHF.'/
     *        1X,'THIS RUN HAS',I4,' ALPHA AND',I4,' BETA ELECTRONS.'/
     *        1X,'PLEASE REVIEW YOUR SCFTYP,MULT,ICHARG INPUT VALUES,'/
     *        1X,'AND CHECK THE NUMBER OF ATOMS GENERATED IN $DATA'/)
 9240 FORMAT(/1X,'ERROR: MULTIPLE SOLVENT MODELS SELECTED.'/
     *        1X,'NO MORE THAN ONE OF THE SCRF/PCM/EFP/COSMO/SVP'/
     *        1X,'SOLVENT MODELS SHOULD BE CHOSEN.'/
     *        1X,'THE EXCEPTION IS EFP+PCM MAY BE SELECTED'/)
 9250 FORMAT(/1X,'ERROR: YOU MAY CHOOSE AT MOST ONE CORRELATION',
     *           ' METHOD FROM'/
     *        1X,'DFTTYP, CITYP, MPLEVL, OR CCTYP IN $CONTRL.'/)
 9700 FORMAT(/1X,'..... DONE SETTING UP THE SUBSYSTEM .....')
      end

      subroutine rdcimatm(nat,levl,group)
C AAD slightly adjusted version of rdgroup in cimi.src
      implicit double precision (a-h,o-z)
      PARAMETER (mxatm=2000)
      character(len=256) line,string
      LOGICAL MOSORT,ORTHO,SUBRHF,FCORE,restrt,runsub
      common /CIMPAR/ bufdst,cconv,mrgsub,submtd,
     *                subtyp,mosort,atmmlk,ortho,subrhf,
     *                eta,zeta,zeta1,zeta2,cimtyp,enrgml,
     *                fcore,mtdatm(mxatm),runsub,restrt,MOFIX,
     *                CIMORB,DISLMO,HDIS,CONVIR,TWOBDY
      COMMON /IOFILE/ IR,IW,IP,IJK,IJKT,IDAF,NAV,IODA(950)
      COMMON /PAR   / ME,MASTER,NPROC,IBTYP,IPTIM,GOPARR,DSKWRK,MASWRK
      logical goparr,dskwrk,maswrk
      INTEGER LEVL(NAT),GROUP(NAT,NAT)
      DATA PLMO /8HLMO     /
C
      ngroup=0
      do i=1,nat
         mtdatm(i)=-1
C        itmp(i)=0
         levl(i)=0
         do j=1,nat
            group(i,j)=0
         enddo
      enddo
C Only master will perform the next step, then
C the MTDATM array will be broadcast to other processes.
C Other arrays are only temporary.
      if(maswrk) then
C ngroup can never be greater nat
      do 100 i=1,nat
         read(ir,'(a)') line
         call NJ_upper(line)
         if (index(line,'$END').ne.0) goto 110
         ngroup=ngroup+1
C we found a group, search for an acceptable method
         k0=index(line,'HF')+index(line,'NONE')
         k1=index(line,'RIMP2')
         k2=index(line,'MP2')-index(line,'RIMP2')-2
         if (k2/=0) k2=index(line,'MP2')
         k3=index(line,'CCD')
         k4=index(line,'CCSD')-index(line,'CCSD(')-index(line,'CCSD[')
         k5=index(line,'CCSD(T)')
         k6=index(line,'CR-CCL')+index(line,'CR-CC(2,3)')
         if(k0.eq.0 .and.
     *      k1.eq.0 .and.
     *      k2.eq.0 .and.
     *      k3.eq.0 .and.
     *      k4.eq.0 .and.
     *      k5.eq.0 .and.
     *      k6.eq.0) then
            write(iw,*)
            write(iw,*) 'A METHOD MUST BE SUPPLIED FOR EACH GROUP',
     *                  ' IN $CIMATM'
            write(iw,*)
            call flshbf(iw)
            call abrt
         endif
C
         if(subtyp.eq.plmo .and. k1+k2+k4+k5+k6.ne.0) then
            write(iw,*)
            write(iw,*) 'SUBTYP=LMO CAN ONLY BE USED WITH CCSD METHOD'
            write(iw,*) 'PLEASE CHECK THE METHODS IN $CIMATM GROUP'
            write(iw,*)
            call flshbf(iw)
            call abrt
         endif
C Set this atom's (i) method (levl)
         if (k0.ne.0) then
            levl(i)=0  ! 0 - NONE/HF
            k=index(line(k0:256),' ')+k0-1
            line(k0:k)=' '
         endif
         if (k1.ne.0) then
            levl(i)=1  ! 1 - RIMP2
            k=index(line(k1:256),' ')+k1-1
            line(k1:k)=' '
         endif
         if (k2.ne.0) then
            levl(i)=2  ! 2 - MP2
            k=index(line(k2:256),' ')+k2-1
            line(k2:k)=' '
         endif
         if (k3.ne.0) then
            levl(i)=3  ! 3 - CCD
            k=index(line(k3:256),' ')+k3-1
            line(k3:k)=' '
         endif
         if (k4.ne.0) then
            levl(i)=4  ! 4 - CCSD
            k=index(line(k4:256),' ')+k4-1
            line(k4:k)=' '
         endif
         if (k5.ne.0) then
            levl(i)=5  ! 5 - CCSD(T)
            k=index(line(k5:256),' ')+k5-1
            line(k5:k)=' '
         endif
         if (k6.ne.0) then
            levl(i)=6  ! 5 - CR-CC(2,3)
            k=index(line(k6:256),' ')+k6-1
            line(k6:k)=' '
         endif
C Now parse the atom number string
         k1=index(line,'('); k2=index(line,')')
         if (k1.ne.0.and.k2.ne.0) then
            line(1:k1)=' '
            line(k2:k)=' '
         elseif ((k1.eq.0.and.k2.ne.0).or.(k1.ne.0.and.k2.eq.0)) then
            write(IW,*) 'ERROR: Missing ''('' or '')'' in $CIMATM group'
            write(IW,*) 'Also you can use ''atom-labels method'' format'
            call flshbf(IW)
            call abrt
         endif
         write(string,'(a)') line(1:k)
         call NJ_readlab(string,group(1,ngroup),nat)
         write(string,'(a)') line(k+1:256)
C
C Check for overspecification of atoms
C otherwise, set mtdatm(j)
C        do j=1,nat
         do 102 j=1,nat
            ic=group(j,ngroup)
            if (ic.eq.0) then
C              exit
               goto 100
            endif
            if(mtdatm(ic).ne.-1) then
               write(iw,"('Atom ',i4,' appears in two $CIMATM groups')")
     *         ic
               write(iw,*)
               call flshbf(iw)
               call abrt
            else
               mtdatm(ic)=levl(i)
            endif
 102     continue
 100  continue
C
 110  continue
      endif
      if(goparr) call ddi_bcast(101,'i',mtdatm,mxatm,master)
      return
      end
