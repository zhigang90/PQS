c===============================================================
c For IROUTE=2 :
c
c According to the new blocking criterions six arrays
c  abnia(nbls1,mmax), cdnia(nbls1,mmax),
c             and
c  rhoapb(nbls1), rhocpd(nbls1)
c             and
c    abcd(nbls1), habcd(nbls1,3,*)
c
c are now different. The first dimension is ALWAYS one.
c Thus, now we have :
c  abnia(mmax) and cdnia(mmax)
c  rhoapb , rhocpd
c  abcd   , habcd(3,*)
c===============================================================
      subroutine trobsa(bl,nbls1,l11,l12,mem2,immax,kmmax,lobsa)
      implicit real*8 (a-h,o-z)
      character*11 scftype
      character*4 where
c
      common /route/ iroute
c
      common /runtype/ scftype,where
c
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,mmax,
     * nqi,nqj,nqk,nql,nsij,nskl,
     * nqij,nqij1,nsij1,nqkl,nqkl1,nskl1,ijbeg,klbeg
c
      common /memor4/ iwt0,iwt1,iwt2,ibuf,ibuf2,
     * ibfij1,ibfij2,ibfkl1,ibfkl2,
     * ibf2l1,ibf2l2,ibf2l3,ibf2l4,ibfij3,ibfkl3,
     * ibf3l,issss,
     * ix2l1,ix2l2,ix2l3,ix2l4,ix3l1,ix3l2,ix3l3,ix3l4,
     * ixij,iyij,izij, iwij,ivij,iuij,isij
c
      common /memor5b/ irppq,
     * irho,irr1,irys,irhoapb,irhocpd,iconst,ixwp,ixwq,ip1234,
     * idx1,idx2,indx
c
      common /memor5c/ itxab,itxcd,iabcd,ihabcd
      common /memor5d/ iabnix,icdnix,ixpnx,ixqnx,ihabcdx
c
      dimension bl(*)
C*************************************************************
c PARAMETERS
c-----------
c Input
c
c 1. bl(*)    storage for everything (common big in DRIVER)
c 2. nbls1 - reduced block-size
c
c 3. l11 = mmax total ang.mom. +1  (i+j+k+l+1)
c 4. l12 = lensm(mmax) total number of function up to mmax (see Iobara)
c 5. mem2 - dimension for wt2(nbls1,mem2) used in Trac12, Trac34
c    l11,l12,mem2 are setup in ithe Memo4a routine and give dimensions
c        wt1(nbls1,l11,l12), wt2(nbls1,mem2) ;
c
c 6. immax -  mmax-2 for nsij>=nskl and nsij-2 otherwise
c 7. kmmax -  nskl-2 for nsij>=nskl and mmax-2 otherwise
c 8. lobsa - lable to select one out of four cases concerning L-shell
c
c    immax,kmmax,lobsa are setup in Erinteg :
c
c     if(nsij.ge.nskl) then
c        immax=mmax-2
c        kmmax=nskl-2
c        lobsa=2
c        if(lshelij.gt.0) lobsa=1
c     else
c        immax=nsij-2
c        kmmax=mmax-2
c        lobsa=4
c        if(lshelkl.gt.0) lobsa=3
c     endif
c
c Output
c
c wt0(nbls1,lnij,lnkl) - containing (i+j,s|k+l,s) integrals
c                        This is located in bl(*) from bl(iwt0)
c
C*************************************************************
c     For the set of NBLS1 quartets of primitive shells I,J,K,L
c  (where NBLS1 is already reduced after some integrals have
c  been neglected) two-electron integrals of the type (i+j,s|k+l,s)
c  are calculated according to the TRacy and OBara-SAika methods.
c     This subroutine is called when the total angular momentum
c  (+1)  mmax = i+j+k+l +1  is GT.2  /for mmax.le.2 a specail code
c  is used/
c
c     As a first step the (s,s|s,s)(m) , m=1,mmax integrals
c  are calculated in the SSSM subroutine using the FM routine.
c  All necessary data for FM are sent by the common block RYS.
c  These integrals are stored in the wt1(nbls1,mmax,l12) matrix
c  and then used as a input for OBASAI routine which is called
c  from here. Part of (ss|ss)(m) itegrals, namely these with
c  m=1, are stored in the wt0(nbls1,l01,l02) matrix where all
c  final primitive integrals are kept for futher contraction.

c     As a second step integrals of the form (i+j+k+l,s|s,s)(m)
c  or (s,s|i+j+k+l,s)(m) are calculated in the OBASAI subroutine.
c  The first type of integrals is calculacted if the total angular
c  momentum of the first pair ij is greater than the second pair kl
c  / nsij >= nskl /. Otherwise, integrals in the second form are
c  constructed. Moreover, one considers also the presence of L-shells
c  in the first and second pair positions. Overall, there are 4 cases
c  for which the OBASAI subroutine is called with different set of
c  parameters. These cases are setup in the BLOCKINT subroutine.
c
c     As a last step the final (i+j,s|k+l,s) integrals are calculated
c  from the previous ones by shifting angular momenta from position
c  1 to 3 or 3 to 1. This is performed in the TRAC12 or TRAC34
c  routines.
c
c     Final primitive integrals (i+j,s|k+l,s) return in the wt0
c  matrix and then they are contracted in the ASSEMBLX routine.
c
C*************************************************************
c
         mmax1 =mmax
         immax1=immax
         kmmax1=kmmax
c
c nmr/giao derivatives:
         if(where.eq.'shif') then
           mmax1 = mmax-1
           immax1=immax-1
c          kmmax1=kmmax-1
           if(immax1.le.0) immax1=1
           if(kmmax1.le.0) kmmax1=1
         endif
c grad. derivatives:
         if(where.eq.'forc') then
           mmax1 = mmax-1
           immax1=immax-1    ! that's ok
           kmmax1=kmmax-1    ! try this ?
           if(immax1.le.0) immax1=1
           if(kmmax1.le.0) kmmax1=1
         endif
c hess. derivatives:
         if(where.eq.'hess') then
           mmax1 = mmax-2
           immax1=immax-2
           kmmax1=kmmax-2
           if(immax1.le.0) immax1=1
           if(kmmax1.le.0) kmmax1=1
         endif
c
         call ssssm(nbls1,bl(irys),bl(iconst),mmax1,
     *              bl(iwt1),l11,l12,bl(iwt0),lnij,lnkl)
cccc
c*  if an ang.mom. of ij >= ang. mom. kl then go to 10 or 20
c*           it goes to 10 only if there is L-shell(s) on i or j
c
c*  if an ang.mom. of ij  < ang. mom. kl then go to 30 or 40
c*           it goes to 30 only if there is L-shell(s) on k or l
cccc
c
      go to (10,20,30,40) lobsa
c
   10 continue
c    (s,s|k+l,s)
       IF( iroute.eq.1 ) THEN
         call obasai_1(bl(irhocpd),bl(icdnix),bl(ixqnx),bl(ixwq),
     *                  mmax1,kmmax1,bl(iwt1),l11,l12,nbls1)
       ELSE
         call obasai_2(bl(irhocpd),bl(icdnix),bl(ixqnx),bl(ixwq),
     *                  mmax1,kmmax1,bl(iwt1),l11,l12,nbls1)
       ENDIF
         call wt0wt1(bl(iwt0),lnij,lnkl,nbls1,bl(iwt1),l11,l12,
     *               nsij,nskl,2)
c
   20 continue
c    (i+j+k+l,s|s,s)
       IF( iroute.eq.1 ) THEN
         call obasai_1(bl(irhoapb),bl(iabnix),bl(ixpnx),bl(ixwp),
     *                  mmax1,immax1,bl(iwt1),l11,l12,nbls1)
       ELSE
         call obasai_2(bl(irhoapb),bl(iabnix),bl(ixpnx),bl(ixwp),
     *                  mmax1,immax1,bl(iwt1),l11,l12,nbls1)
       ENDIF
         call wt0wt1(bl(iwt0),lnij,lnkl,nbls1,bl(iwt1),l11,l12,
     *               nsij,nskl,1)
       if(nskl.gt.1) then
         call wt2wt1(bl(iwt2),mem2,nbls1,bl(iwt1),l11,l12,mmax1)
         IF( iroute.eq.1 ) THEN
            call trac12_1(bl(iwt0),lnij,lnkl,nbls1,bl(iwt2),mem2,
     *                    bl(ip1234),bl(iabcd),bl(ihabcdx) )
         ELSE
            call trac12_2(bl(iwt0),lnij,lnkl,nbls1,bl(iwt2),mem2,
     *                    bl(ip1234),bl(iabcd),bl(ihabcdx) )
         ENDIF
       endif
       return
   30 continue
c    (i+j,s|s,s)
       IF( iroute.eq.1 ) THEN
         call obasai_1(bl(irhoapb),bl(iabnix),bl(ixpnx),bl(ixwp),
     *                  mmax1,immax1,bl(iwt1),l11,l12,nbls1)
       ELSE
         call obasai_2(bl(irhoapb),bl(iabnix),bl(ixpnx),bl(ixwp),
     *                  mmax1,immax1,bl(iwt1),l11,l12,nbls1)
       ENDIF
         call wt0wt1(bl(iwt0),lnij,lnkl,nbls1,bl(iwt1),l11,l12,
     *               nsij,nskl,1)
   40 continue
c    (s,s|i+j+k+l,s)
       IF( iroute.eq.1 ) THEN
         call obasai_1(bl(irhocpd),bl(icdnix),bl(ixqnx),bl(ixwq),
     *                  mmax1,kmmax1,bl(iwt1),l11,l12,nbls1)
       ELSE
         call obasai_2(bl(irhocpd),bl(icdnix),bl(ixqnx),bl(ixwq),
     *                  mmax1,kmmax1,bl(iwt1),l11,l12,nbls1)
       ENDIF
         call wt0wt1(bl(iwt0),lnij,lnkl,nbls1,bl(iwt1),l11,l12,
     *               nsij,nskl,2)
       if(nsij.gt.1) then
         call wt2wt1(bl(iwt2),mem2,nbls1,bl(iwt1),l11,l12,mmax1)
         IF( iroute.eq.1 ) THEN
            call trac34_1(bl(iwt0),lnij,lnkl,nbls1,bl(iwt2),mem2,
     *                    bl(ip1234),bl(iabcd),bl(ihabcdx) )
         ELSE
            call trac34_2(bl(iwt0),lnij,lnkl,nbls1,bl(iwt2),mem2,
     *                    bl(ip1234),bl(iabcd),bl(ihabcdx) )
         ENDIF
       endif
c
      return
      end
c********
      subroutine ssssm(nbls,rysx,const,mmax,wt1,l11,l12,wt0,l01,l02)
      implicit real*8 (a-h,o-z)
      common /flops/ iflop(20)
      dimension const(*),rysx(*)
      dimension wt0(nbls,l01,l02),wt1(nbls,l11,l12)
      dimension f0m(0:30)
c--------------------------------------------------------------------
c This subroutine calculates (s,s|s,s)(m) integrals with m=1,MMAX
c where MMAX is the total angular momentum (+1). These integrals are
c needed in the Obara-Saika method.
c
c INPUT:
c
c NBLS     - reduced block-size /number of quartets of primitive shells/
c RYSX(nbls) - (P-Q)**2*(a+b)*(c+d)/(a+b+c+d) an parameter for Fm
c CONST(nbls)- see PREC4NEG and PRECAL2A
c              CONST=PI3*SABCD/(PQ*SQRT(PPQ)) for all int.
c MMAX     - total ang. mom. +1
c l11,l12 - dimensions for wt1
c l01,l02 - dimensions for wt0
c
c OUTPUT:
c
c wt1(ijkl,m,1) - integrals (s,s|s,s)(m=1,mmax)
c wt0(ijkl,1,1) - integrals (s,s|s,s)(m=1)
c
c--------------------------------------------------------------------
C**********************************************************
C**  CALCULATE (SS,SS)(M)  M=1,MMAX
C**    S ORBITALS ARE NORMALIZED
C**
c
         do 410 i=1,nbls
         xrys=rysx(i)
         call fm(xrys,mmax-1,f0m)
         do 410 m=1,mmax
         wt1(i,m,1)=const(i)*f0m(m-1)
  410  CONTINUE
cflops
cxxxxx   iflop(10)=iflop(10)+mmax*nbls
C*
         do 420 i=1,nbls
         wt0(i,1,1)=wt1(i,1,1)
  420    continue
cxx   call dcopy(nbls,wt1(1,1,1),1,wt0(1,1,1),1)
c
      return
      end
c***************
      subroutine wt0wt1(wt0,l01,l02,nbls,wt1,l11,l12,nsij,nskl,lab)
      implicit real*8 (a-h,o-z)
      common /logic4/ nfu(1)
      dimension wt0(nbls,l01,l02),wt1(nbls,l11,l12)
c
      go to (10,20) lab
c
   10 continue
      do 100 inp=2,nfu(nsij +1)
         do 100 i=1,nbls
         wt0(i,inp,1)=wt1(i,1,inp)
c--->    call dcopy(nbls,wt1(1,1,inp),1,wt0(1,inp,1),1)
  100 continue
c
      return
c
   20 continue
      do 200 knp=2,nfu(nskl +1)
         do 200 i=1,nbls
         wt0(i,1,knp)=wt1(i,1,knp)
c--->    call dcopy(nbls,wt1(1,1,knp),1,wt0(1,1,knp),1)
  200 continue
c
      return
      end
c=================================================================
c obasai subroutines :
c----------------------------------------------------------------
c PARAMETERS
c-----------
c
c Input :
c 1. RHOAPB(nbls1) -  (c+d)/(a+b+c+d) - exponents
c 2. ABNIA(nbls1,*) -   L*( 0.5/(a+b) )  with L=1,2,...MMAX-1
c 3. XPA(nbls1,3)   -  (P-A) coordinates
c 4. XWP(nbls1,3)   -  (W-P) coordinates
c 5. MMAX         - total ang. mom. +1
c 6. IMMAX        - see Trobsa
c 7. XT(nbls1,l11,l12) - integrals (s,s|s,s)(m)
c 8. NBLS - reduced block-size (nbls1)
c
c Output
c
c 1. XT(nbls1,l11,l12) - integrals (i+j+k+l,s|s,s)(m)
c                        only integrals with m=1 are used later
c----------------------------------------------------------------
c     This is the OBARA-SAIKA recursive method to generate integrals
c  with all angular momenta placed in the position 1 /(i+j+k+l,s|s,s)/
c  or in the position 2 /(s,s|i+j+k+l,s)/. This subroutine is called
c  for both cases with different set of parameters from OBSA1-OBSA4
c  routines. It is accesable from any place.
c     As a input, integrals (s,s|s,s)(m) from SSSSM routine are used
c  /in xt(nbls,mmax,1)/. Integrals (i+j+k+l,s|s,s)(m) return also in
c  the array xt(nbls,mmax,l12) with l12=nfu(mmax+1)
c----------------------------------------------------------------
c========================
      subroutine obasai_1(rhoapb,abnia,xpa,xwp,mmax,immax,xt,
     *                    l11,l12,nbls)
      implicit real*8 (a-h,o-z)
      common /logic4/ nfu(1)
      common /logic5/ icoor(1)
      common /logic7/ ifrst(1)
      common /logic9/ nia(3,1)
      common /logic10/ nmxyz(3,1)
      common /logic11/ npxyz(3,1)
      common /flops/ iflop(20)
      dimension xt(nbls,l11,l12)
      dimension abnia(nbls,*),rhoapb(*)
      dimension xpa(nbls,3),xwp(nbls,3)
c---------------------------------------
       MMM=MMAX-1
       do 100 inp=2,4
       in0=ifrst(inp)
       icr=icoor(inp)
          call recur1(nbls,l11,mmm,xt(1,1,inp),xt(1,1,in0),
     *                xpa(1,icr),xwp(1,icr))
  100  continue
cflops
cxxx   nrec1=3*mmm
cxxx   nrec2=0
c*
       mmm=mmax-2
c
       do 105 im=1,immax
          do 110 inm=nfu(im)+1,nfu(im+1)
          icrm=icoor(inm)
             do 115 ixyz=icrm,3
             in0=npxyz(ixyz,inm)
                 do 120 jxyz=ixyz,3
                 inp=npxyz(jxyz,in0)
                 call recur1(nbls,l11,mmm,xt(1,1,inp),xt(1,1,in0),
     *                       xpa(1,jxyz),xwp(1,jxyz))
  120            continue
             inpa=npxyz(ixyz,in0)
             nia0= nia(ixyz,in0)
             call recur2_1(nbls,l11,mmm,
     *                   xt(1,1,inpa),xt(1,1,inm),abnia(1,nia0),rhoapb)
  115        continue
  110     continue
       mmm=mmm-1
  105  continue
cflops
cxx    iflop(1)=iflop(1)+nrec1*nbls
cxx    iflop(2)=iflop(2)+nrec2*nbls
      return
      end
c========================
      subroutine obasai_2(rhoapb,abnia,xpa,xwp,mmax,immax,xt,
     *                    l11,l12,nbls)
      implicit real*8 (a-h,o-z)
      common /logic4/ nfu(1)
      common /logic5/ icoor(1)
      common /logic7/ ifrst(1)
      common /logic9/ nia(3,1)
      common /logic10/ nmxyz(3,1)
      common /logic11/ npxyz(3,1)
      common /flops/ iflop(20)
c
      dimension xt(nbls,l11,l12)
      dimension xpa(nbls,3),xwp(nbls,3)
ccccc dimension abnia(nbls,*),rhoapb(*)
      dimension abnia(*)
c--------------------------------------
       MMM=MMAX-1
       do 100 inp=2,4
       in0=ifrst(inp)
       icr=icoor(inp)
          call recur1(nbls,l11,mmm,xt(1,1,inp),xt(1,1,in0),
     *                xpa(1,icr),xwp(1,icr))
  100  continue
cflops
cxxx   nrec1=3*mmm
cxxx   nrec2=0
c*
       mmm=mmax-2
c
       do 105 im=1,immax
          do 110 inm=nfu(im)+1,nfu(im+1)
          icrm=icoor(inm)
             do 115 ixyz=icrm,3
             in0=npxyz(ixyz,inm)
                 do 120 jxyz=ixyz,3
                 inp=npxyz(jxyz,in0)
                 call recur1(nbls,l11,mmm,xt(1,1,inp),xt(1,1,in0),
     *                       xpa(1,jxyz),xwp(1,jxyz))
  120            continue
             inpa=npxyz(ixyz,in0)
             nia0= nia(ixyz,in0)
             call recur2_2(nbls,l11,mmm,
     *                   xt(1,1,inpa),xt(1,1,inm),abnia(nia0),rhoapb)
  115        continue
  110     continue
       mmm=mmm-1
  105  continue
cflops
cxx    iflop(1)=iflop(1)+nrec1*nbls
cxx    iflop(2)=iflop(2)+nrec2*nbls
      return
      end
c=================================================================
      subroutine recur1(nbls,l11,mmm,xtp,xt0,xpa,xwp)
      implicit real*8 (a-h,o-z)
      dimension xtp(nbls,l11),xt0(nbls,l11),xpa(nbls),xwp(nbls)
c
  150 continue
          do 1501 m=1,mmm
          m1=m+1
          do 1501 i=1,nbls
          xtp(i,m)=xpa(i)*xt0(i,m)+xwp(i)*xt0(i,m1)
 1501     continue
      return
      end
c=================================================================
c recur2 routines :
c
c========================
      subroutine recur2_1(nbls,l11,mmm,xtp,xtm,abnia,rhoapb)
      implicit real*8 (a-h,o-z)
      dimension xtp(nbls,l11),xtm(nbls,l11),abnia(nbls)
      dimension rhoapb(*)
c
           do 1501 m=1,mmm
           m1=m+1
           do 1501 i=1,nbls
           xtp(i,m)=xtp(i,m)+abnia(i)*(xtm(i,m) - xtm(i,m1)*rhoapb(i))
 1501      continue
      end
c========================
      subroutine recur2_2(nbls,l11,mmm,xtp,xtm,abnia,rhoapb)
      implicit real*8 (a-h,o-z)
      dimension xtp(nbls,l11),xtm(nbls,l11)
c
           do 1501 m=1,mmm
           m1=m+1
           do 1501 i=1,nbls
c OLD      xtp(i,m)=xtp(i,m)+abnia(i)*(xtm(i,m) - xtm(i,m1)*rhoapb(i))
           xtp(i,m)=xtp(i,m)+abnia   *(xtm(i,m) - xtm(i,m1)*rhoapb   )
 1501      continue
      end
c=================================================================
      subroutine wt2wt1(wt2,mem2,nbls,wt1,l11,l12,mmax)
      IMPLICIT REAL*8 (A-H,O-Z)
      common /logic4/ nfu(1)
      dimension wt1(nbls,l11,l12),wt2(nbls,mem2)
c
       do 145 inp=1,nfu(mmax+1)
          do 145 i=1,nbls
          wt2(i,inp)=wt1(i,1,inp)
c--->     call dcopy(nbls,wt1(1,1,inp),1,wt2(1,inp),1)
  145  continue
c
      return
      end
c=================================================================
c trac12 routines :
c
C*************************************************************
C***  This subroutine performs calculations for a block (nbls)
C***  of quartets of primitive shells. The integrals calculated
C***  here are of the type :
C***               (i+j,s | k+l,s)
C***  in the case when the angular momentum i+j .GE. k+l
C***  This subroutine is called from TROBSA.
C***
C***
C***     Calculations are performed according to the Tracy's
C***  recursive formula. It is made in the loop over an angular
C***  momentum increasing on the the center no. 3. For each such
C***  a recursive step the tracij routine is called with the wt0 and
C***  the wt2 matrix at three different locations. The wt2 matrix is
C***  two-domensional here but it is three-dim. in tracij. This
C***  to execute Tracy's recursives. At the very begining wt2
C***  contains wt1(1,nbls,l12)= (i+j+k+l,s|s,s) (m=1) integrals.
C***  Final intgrals (i+j,s|k+l,s) return from tracij in the wt0 matrix
C***  and nothing else is done with them here. They go back through
C***  the routine TROBSA from which OBSAIJ (OBSAKL) was called to
C***  the routine TWOE (where Trobsa is called) and then are
C***  contracted in the routine ASSEMBLE.
C***
C***  INPUT
C***  -------
C***
C***  information from the obarai common block
C***
C***   and precalculated quantities :
C***
C***  p1234 (nbls,3) - geometry stuff
C***
C***  OUTPUT
C***  -------
C***  wt0(nbls,l01,l02) - contains final (i+j,s|k+l,s) integrals
C***
C***  Locally in use - the wt2(nbls,mem2) matrix for tracij
C***
C*************************************************************
c========================
      subroutine trac12_1(wt0,l01,l02,nbls,wt2,mem2, p1234, abcd,habcd)
      IMPLICIT REAL*8 (A-H,O-Z)
cnmr
      character*11 scftype
      character*4 where
      common /runtype/ scftype,where
c
      common /tracy/ kbeg,kend,i0b,i0e,kp
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,MMAX,
     * NQI,NQJ,NQK,NQL,NSIJ,NSKL,
     * NQIJ,NQIJ1,NSIJ1,NQKL,NQKL1,NSKL1,ijbex,klbex
      common /logic4/ nfu(1)
C
      dimension wt0(nbls,l01,l02),wt2(nbls,mem2)
      dimension p1234(nbls,3)
      dimension abcd(nbls),habcd(nbls,3,*)
c---------------------------------------------------------------
c   calculate (i+j,s|k+l,s) integrals from (i+j+k+l,s|s,s) ones
c            according to the Tracy's recursive formula
c   All target classes needed for further shifts (A->B) are
c   constructed.
c     target classes :  from (i,s|k,s) to (i+j,s|k+l,s)
C
c   The target classes appear in last nskl-nqkl+1 recursive steps
c   total number of recursive steps is nrs=nskl-2+1
c---------------------------------------------------------------
cnmr
      mmax1=mmax
ckw   if(where.eq.'shif') then
      if(where.eq.'shif'.or. where.eq.'forc') then
          mmax1=mmax-1
      endif
      if(where.eq.'hess') then
          mmax1=mmax-2
      endif
cnmr
c
c  addressing in the wt2 matrix for recurcive in Tracy
c
      ia3=0
      k31=nfu(mmax+1)
c-??- k31=nfu(mmax1+1)
      k32=1
      ia2=ia3
      k21=k31
      k22=k32
cccccc
cccc  nrec=0
      do 2000 kp=2,nskl
      kbeg=nfu(kp)+1
      kend=nfu(kp+1)
cccc
       i0b=mmax1+1-kp
       i0e=nqij-nskl+kp
       if(i0e.le.0) i0e=1
cccc
cccc   nrec=nrec+1
cccc
      ia1=ia2+k21*k22
      k11=nfu(i0b+1)
      k12=nfu(kp+1)
cccc
      i11=ia1+1
      i21=ia2+1
      i31=ia3+1
      call tracij_1(wt2(1,i11),k11,k12,
     *              wt2(1,i21),k21,k22,
     *              wt2(1,i31),k31,k32,
     *              p1234,wt0,l01,l02,nbls,
     *              abcd,habcd)
      ia3=ia2
      ia2=ia1
      k31=k21
      k32=k22
      k21=k11
      k22=k12
 2000 continue
      RETURN
      END
c========================
      subroutine trac12_2(wt0,l01,l02,nbls,wt2,mem2, p1234, abcd,habcd)
      IMPLICIT REAL*8 (A-H,O-Z)
cnmr
      character*11 scftype
      character*4 where
      common /runtype/ scftype,where
cnmr
      common /tracy/ kbeg,kend,i0b,i0e,kp
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,MMAX,
     * NQI,NQJ,NQK,NQL,NSIJ,NSKL,
     * NQIJ,NQIJ1,NSIJ1,NQKL,NQKL1,NSKL1,ijbex,klbex
      common /logic4/ nfu(1)
      dimension wt0(nbls,l01,l02),wt2(nbls,mem2)
      dimension p1234(nbls,3)
ccccc dimension abcd(nbls),habcd(nbls,3,*)
      dimension habcd(3,*)
c-------------------------------------------------------
c   calculate (i+j,s|k+l,s) integrals from (i+j+k+l,s|s,s) ones
c            according to the Tracy's recursive formula
c   All target classes needed for further shifts (A->B) are
c   constructed.
c     target classes :  from (i,s|k,s) to (i+j,s|k+l,s)
C
c   The target classes appear in last nskl-nqkl+1 recursive steps
c   total number of recursive steps is nrs=nskl-2+1
c-------------------------------------------------------
cnmr
      mmax1=mmax
ckw   if(where.eq.'shif') then
      if(where.eq.'shif'.or. where.eq.'forc') then
          mmax1=mmax-1
      endif
      if(where.eq.'hess') then
          mmax1=mmax-2
      endif
cnmr
c
c  addressing in the wt2 matrix for recurcive in Tracy
c
      ia3=0
      k31=nfu(mmax+1)
c-??- k31=nfu(mmax1+1)
      k32=1
      ia2=ia3
      k21=k31
      k22=k32
cccccc
cccc  nrec=0
      do 2000 kp=2,nskl
      kbeg=nfu(kp)+1
      kend=nfu(kp+1)
cccc
c--->  i0b=mmax+1-kp
c--->  i0e=nqij-nskl+kp
       i0b=mmax1+1-kp
       i0e=nqij-nskl+kp
       if(i0e.le.0) i0e=1
cccc
cccc   nrec=nrec+1
cccc
      ia1=ia2+k21*k22
      k11=nfu(i0b+1)
      k12=nfu(kp+1)
cccc
      i11=ia1+1
      i21=ia2+1
      i31=ia3+1
      call tracij_2(wt2(1,i11),k11,k12,
     *              wt2(1,i21),k21,k22,
     *              wt2(1,i31),k31,k32,
     *              p1234,wt0,l01,l02,nbls,
     *              abcd,habcd)
      ia3=ia2
      ia2=ia1
      k31=k21
      k32=k22
      k21=k11
      k22=k12
 2000 continue
      RETURN
      END
c=================================================================
c trac34 routines :
C
C  This subroutine performs calculations for a block (nbls)
C  of quartets of primitive shells. The integrals calculated
C  here are of the type :  (i+j,s | k+l,s)
C  in the case when the angular momentum i+j .LT. k+l
C  This subroutine is called from TROBSA.
C  see description in TRAC12.
c========================
      subroutine trac34_1(wt0,l01,l02,nbls,wt2,mem2, p1234, abcd,habcd)
      IMPLICIT REAL*8 (A-H,O-Z)
      common /tracy/ ibeg,iend,k0b,k0e,ip
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,MMAX,
     * NQI,NQJ,NQK,NQL,NSIJ,NSKL,
     * NQIJ,NQIJ1,NSIJ1,NQKL,NQKL1,NSKL1,ijbex,klbex
      common /logic4/ nfu(1)
C
      dimension wt0(nbls,l01,l02),wt2(nbls,mem2)
      dimension p1234(nbls,3)
      dimension abcd(nbls),habcd(nbls,3,*)
c-----------------------------------------------------
c  addressing in the wt2 matrix for recursive in Tracy
c
      ia3=0
      k31=1
      k32=nfu(mmax+1)
      ia2=ia3
      k21=k31
      k22=k32
cccccc
cccc  nrec=0
      do 2000 ip=2,nsij
      ibeg=nfu(ip)+1
      iend=nfu(ip+1)
cccc
       k0b=mmax+1-ip
       k0e=nqkl-nsij+ip
       if(k0e.le.0) k0e=1
cccc
cccc   nrec=nrec+1
ccccccccccccccccccccccccccccccc
       ia1=ia2+k21*k22
       k11=nfu(ip+1)
       k12=nfu(k0b+1)
cccc
      i11=ia1+1
      i21=ia2+1
      i31=ia3+1
      call trackl_1(wt2(1,i11),k11,k12,
     *              wt2(1,i21),k21,k22,
     *              wt2(1,i31),k31,k32,
     *              p1234,wt0,l01,l02,nbls,
     *              abcd,habcd)
      ia3=ia2
      ia2=ia1
      k31=k21
      k32=k22
      k21=k11
      k22=k12
 2000 continue
      RETURN
      END
c========================
      subroutine trac34_2(wt0,l01,l02,nbls,wt2,mem2, p1234, abcd,habcd)
      IMPLICIT REAL*8 (A-H,O-Z)
      common /tracy/ ibeg,iend,k0b,k0e,ip
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,MMAX,
     * NQI,NQJ,NQK,NQL,NSIJ,NSKL,
     * NQIJ,NQIJ1,NSIJ1,NQKL,NQKL1,NSKL1,ijbex,klbex
      common /logic4/ nfu(1)
C
      dimension wt0(nbls,l01,l02),wt2(nbls,mem2)
      dimension p1234(nbls,3)
ccccc dimension abcd(nbls),habcd(nbls,3,*)
      dimension habcd(3,*)
c-----------------------------------------------------
c  addressing in the wt2 matrix for recursive in Tracy
c
      ia3=0
      k31=1
      k32=nfu(mmax+1)
      ia2=ia3
      k21=k31
      k22=k32
cccccc
cccc  nrec=0
      do 2000 ip=2,nsij
      ibeg=nfu(ip)+1
      iend=nfu(ip+1)
cccc
       k0b=mmax+1-ip
       k0e=nqkl-nsij+ip
       if(k0e.le.0) k0e=1
cccc
cccc   nrec=nrec+1
ccccccccccccccccccccccccccccccc
       ia1=ia2+k21*k22
       k11=nfu(ip+1)
       k12=nfu(k0b+1)
cccc
      i11=ia1+1
      i21=ia2+1
      i31=ia3+1
      call trackl_2(wt2(1,i11),k11,k12,
     *              wt2(1,i21),k21,k22,
     *              wt2(1,i31),k31,k32,
     *              p1234,wt0,l01,l02,nbls,
     *              abcd,habcd)
      ia3=ia2
      ia2=ia1
      k31=k21
      k32=k22
      k21=k11
      k22=k12
 2000 continue
      RETURN
      END
c=================================================================
Ckw 1998 :
c the if(inm.gt.0) condition has been eleiminted from tracij_2
c the if(knm.gt.0) condition has been eleiminted from trackl_2
c=================================================================
c The tracij_1 & _2  routines shift BY ONE an angular momentum from
C position 1 to 3 according to the recursive formula of Tracy.
C This is called ones from trobsa for every new type of orbitals
C constructed on the center 3 i.e.
C (i+j+k+l-1,s|p,s),then (= -2|d,s),(= -3,s|fs),..(i+j,s|k+l,s)
C The result is stored in the xt1 matrix and then used in next
C step as a xt2, xt2 as xt3 and new xt1 is calculated. At the
C end the final integrals are stored in the xt0 matrix. It is
C done since the current recursive step (nrec) approaches nqkl
C which is the first target class.
C
C The corresponding trackl_1 &_2 routines shift BY ONE an angular
C momentum from position 3 to 1 according to the Tracy's recursive.
C This is called ones from trobsa for every new type of orbitals
c constructed on the center 1 i.e.
C (p,s|i+j+k+l-1,s),then (d,s|=-2),...(i+j,s|k+l,s)
c=================================================================
c NOTE : tracij_ are called when NSIJ>=NSKL (ang.mom)
c        trackl_ are called when NSIJ <NSKL (ang.mom)
c=================================================================
C 1998 : the trackl_1 _2 routines are NOT analogues to tracij_1 &_2
C     Now both tracij_ & trackl_ have the same P1234() factors
C     regardless of nsij & nskl relation (it used to be different)
C     These p1234() factors are calculated in xwpq_ routines
C     Because of having the same factors in trackl_ there is
C     one more step involving multiplication of final
C     xt1(i,inp,kn0) integrals by abcd() .
c
c
c shifting from 1 to 3 goes like this:
c
c    x1(i0,kp)=      [-b*AB-d*CD]/(c+d)*x2(i0,k0)
c              -             (a+b)/c+d)*x2(ip,k0)
c              + 0.5*nia(coor,i0)/(c+d)*x2(im,k0)
c              + 0.5*nia(coor,k0)/(c+d)*x2(i0,km)
c
c and corresponding shifting from 3 to 1 :
c
c    x1(ip,k0)=      [-b*AB-d*CD]/(a+b)*x2(i0,k0)
c              -             (c+d)/a+b)*x2(i0,kp)
c              + 0.5*nia(coor,i0)/(a+b)*x2(im,k0)
c              + 0.5*nia(coor,k0)/(a+b)*x2(i0,km)
c
c Taking factor (c+d)/(a+b) at the front yields
c the expression for x1(ip,kn0)
c
c    x1(ip,k0)=(c+d)/(a+b)
c                   *{[-b*AB-d*CD]/(c+d)*x2(i0,k0)
c               -                        x2(i0,kp)
c               + 0.5*nia(coor,i0)/(c+d)*x2(im,k0)
c               + 0.5*nia(coor,k0)/(c+d)*x2(i0,km) }
c
c which has THE SAME internal multiplicative factors
c as the one for x1(i0,kp) .
c=================================================================
      subroutine tracij_1(xt1,l1b,l1e,xt2,l2b,l2e,xt3,l3b,l3e,
     *                    p1234,xt0,l01,l02,nbls,abcd,habcd)
      implicit real*8 (a-h,o-z)
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,mmax,
     * nqi,nqj,nqk,nql,nsij,nskl,
     * nqij,nqij1,nsij1,nqkl,nqkl1,nskl1,ijbex,klbex
      common /logic4/ nfu(1)
      common /logic5/ icoor(1)
      common /logic7/ ifrst(1)
      common /logic10/ nmxyz(3,1)
      common /logic11/ npxyz(3,1)
      common /tracy/ kbeg,kend,i0b,i0e,nrec
c
      dimension xt0(nbls,l01,l02),xt1(nbls,l1b,l1e),
     *                            xt2(nbls,l2b,l2e),
     *                            xt3(nbls,l3b,l3e)
      dimension p1234(nbls,3)
      dimension abcd(nbls),habcd(nbls,3,*)
c------------------------------------------------------
C  INPUT
C  ------
C  xt2, xt3 matrices    - contain integrals from the previous
C                         recursive step
C                         -b*(A-B) - d*(C-D)
C  p1234(nbls,3)        - --------------------
C                               c + d
C  abcd = (a+b)/(c+d)
c
c habcd = 1/2 * ang. mom. on ij or kl
C------------------------------------------------------
C  OUTPUT
C  -------
C  xt1 and xt0 matrices - xt0 contains at the end integrals
C                         of the type (i+j,s|k+l,s)
C ----------
C  Other important information needed here are sent by
C         common /tracy/ kbeg,kend,i0b,i0e,nrec
c------------------------------------------------------
c
          do 2005 knp=kbeg,kend
          kn0=ifrst(knp)
          kcr=icoor(knp)
          knm=nmxyz(kcr,kn0)
c
             do 1000 in0=nfu(i0e)+1,nfu(i0b+1)
             inp=npxyz(kcr,in0)
             inm=nmxyz(kcr,in0)
                do 1001 i=1,nbls
       xt1(i,in0,knp)=p1234(i,kcr)*xt2(i,in0,kn0)-abcd(i)*xt2(i,inp,kn0)
 1001           continue
      if(inm.gt.0) then
                do 1002 i=1,nbls
       xt1(i,in0,knp)=xt1(i,in0,knp)+habcd(i,kcr,in0)*xt2(i,inm,kn0)
 1002           continue
      endif
      if(knm.gt.0) then
                do 1003 i=1,nbls
       xt1(i,in0,knp)=xt1(i,in0,knp)+habcd(i,kcr,kn0)*xt3(i,in0,knm)
 1003           continue
      endif
c
 1000        continue
 2005     continue
c
      if(nrec.ge.nqkl) then
        do 150 knp=kbeg,kend
        do 150 in0=nfu(nqij)+1,nfu(nsij+1)
           do 150 i=1,nbls
           xt0(i,in0,knp)=xt1(i,in0,knp)
  150   continue
      endif
c
      end
c=================================================================
      subroutine tracij_2(xt1,l1b,l1e,xt2,l2b,l2e,xt3,l3b,l3e,
     *                    p1234,xt0,l01,l02,nbls,abcd,habcd)
      implicit real*8 (a-h,o-z)
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,MMAX,
     * NQI,NQJ,NQK,NQL,NSIJ,NSKL,
     * NQIJ,NQIJ1,NSIJ1,NQKL,NQKL1,NSKL1,ijbex,klbex
      common /logic4/ nfu(1)
      common /logic5/ icoor(1)
      common /logic7/ ifrst(1)
      common /logic10/ nmxyz(3,1)
      common /logic11/ npxyz(3,1)
      common /tracy/ kbeg,kend,i0b,i0e,nrec
c
      dimension xt0(nbls,l01,l02),xt1(nbls,l1b,l1e),
     *                            xt2(nbls,l2b,l2e),
     *                            xt3(nbls,l3b,l3e)
      dimension p1234(nbls,3)
cccc  dimension abcd(nbls),habcd(nbls,3,*)
      dimension habcd(3,*)
c------------------------------------------------------
c establish beginning & end for the loops over in0 & inm:
c
      if(i0e.gt.1) then
         inm_beg=nfu(i0e-1)+1
      else
         inm_beg= 1
      endif
c
      inm_end=nfu(i0b  )
c
      in0_beg=nfu(i0e)+1
      in0_end=nfu(i0b+1)
c------------------------------------------------------
      do knp=kbeg,kend
         kn0=ifrst(knp)
         kcr=icoor(knp)
         knm=nmxyz(kcr,kn0)
c
c do in0 & inp, do not do inm :
c
         if(knm.gt.0) then
            habcdkn0=habcd(kcr,kn0)
            do in0=in0_beg,in0_end
               inp=npxyz(kcr,in0)
               do i=1,nbls
                  xt1(i,in0,knp)=p1234(i,kcr)*xt2(i,in0,kn0)
     *                               -abcd   *xt2(i,inp,kn0)
     *                              +habcdkn0*xt3(i,in0,knm)
               enddo
            enddo
         else
            do in0=in0_beg,in0_end
               inp=npxyz(kcr,in0)
               do i=1,nbls
                  xt1(i,in0,knp)=p1234(i,kcr)*xt2(i,in0,kn0)
     *                               -abcd   *xt2(i,inp,kn0)
               enddo
            enddo
         endif      !      if(knm.gt.0) then
c
c do inm only :
c
         do inm=inm_beg,inm_end
            in0=npxyz(kcr,inm)
            habcdin0=habcd(kcr,in0)
            do i=1,nbls
               xt1(i,in0,knp)=xt1(i,in0,knp)+habcdin0*xt2(i,inm,kn0)
            enddo
         enddo
      enddo
c------------------------------------------------------
c------------ saving  target classes ------------------
      if(nrec.ge.nqkl) then
         in0=nfu(nqij)+1
         ldcopy=nbls*(nfu(nsij+1)-nfu(nqij))
         do knp=kbeg,kend
          call dcopy(ldcopy,xt1(1,in0,knp),1,xt0(1,in0,knp),1)
c            do in0=nfu(nqij)+1,nfu(nsij+1)
c               do i=1,nbls
c                  xt0(i,in0,knp)=xt1(i,in0,knp)
c               enddo
c            enddo
         enddo
      endif
c---------------- target classes ----------------------
c
      end
c=================================================================
c trackl routines :
c
      subroutine trackl_1(xt1,l1b,l1e,xt2,l2b,l2e,xt3,l3b,l3e,
     *                    p1234,xt0,l01,l02,nbls, abcd,habcd)
      implicit real*8 (a-h,o-z)
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,mmax,
     * nqi,nqj,nqk,nql,nsij,nskl,
     * nqij,nqij1,nsij1,nqkl,nqkl1,nskl1,ijbex,klbex
      common /logic4/ nfu(1)
      common /logic5/ icoor(1)
      common /logic7/ ifrst(1)
      common /logic10/ nmxyz(3,1)
      common /logic11/ npxyz(3,1)
      common /tracy/ ibeg,iend,k0b,k0e,nrec
c
      dimension xt0(nbls,l01,l02),xt1(nbls,l1b,l1e),
     *                            xt2(nbls,l2b,l2e),
     *                            xt3(nbls,l3b,l3e)
      dimension p1234(nbls,3)
      dimension abcd(nbls),habcd(nbls,3,*)
c------------------------------------------------------
c
          do 2005 inp=ibeg,iend
          in0=ifrst(inp)
          icr=icoor(inp)
          inm=nmxyz(icr,in0)
c
              do 1000 kn0=nfu(k0e)+1,nfu(k0b+1)
              knp=npxyz(icr,kn0)
              knm=nmxyz(icr,kn0)
                 do 1001 i=1,nbls
      xt1(i,inp,kn0)=p1234(i,icr)*xt2(i,in0,kn0)-xt2(i,in0,knp)
 1001            continue
      if(knm.gt.0) then
                  do 1002 i=1,nbls
       xt1(i,inp,kn0)=xt1(i,inp,kn0)+habcd(i,icr,kn0)*xt2(i,in0,knm)
 1002             continue
      endif
      if(inm.gt.0) then
                  do 1003 i=1,nbls
       xt1(i,inp,kn0)=xt1(i,inp,kn0)+habcd(i,icr,in0)*xt3(i,inm,kn0)
 1003             continue
      endif
c
                  do i=1,nbls
                     xt1(i,inp,kn0)=xt1(i,inp,kn0)*abcd(i)
                  enddo
c
 1000        continue
 2005     continue
c
      if(nrec.ge.nqij) then
        do 150 kn0=nfu(nqkl)+1,nfu(nskl+1)
        do 150 inp=ibeg,iend
           do 150 i=1,nbls
           xt0(i,inp,kn0)=xt1(i,inp,kn0)
  150   continue
      endif
c
      end
c=================================================================
      subroutine trackl_2(xt1,l1b,l1e,xt2,l2b,l2e,xt3,l3b,l3e,
     *                    p1234,xt0,l01,l02,nbls, abcd,habcd)
      IMPLICIT REAL*8 (A-H,O-Z)
      common/obarai/
     * lni,lnj,lnk,lnl,lnij,lnkl,lnijkl,MMAX,
     * NQI,NQJ,NQK,NQL,NSIJ,NSKL,
     * NQIJ,NQIJ1,NSIJ1,NQKL,NQKL1,NSKL1,ijbex,klbex
      common /logic4/ nfu(1)
      common /logic5/ icoor(1)
      common /logic7/ ifrst(1)
      common /logic10/ nmxyz(3,1)
      common /logic11/ npxyz(3,1)
      common /tracy/ ibeg,iend,k0b,k0e,nrec
c
      dimension xt0(nbls,l01,l02),xt1(nbls,l1b,l1e),
     *                            xt2(nbls,l2b,l2e),
     *                            xt3(nbls,l3b,l3e)
      dimension p1234(nbls,3)
cccc  dimension abcd(nbls),habcd(nbls,3,*)
      dimension habcd(3,*)
c------------------------------------------------------
c establish beginning & end for the loops over kn0 & knm:
c
      if(k0e.gt.1) then
         knm_beg=nfu(k0e-1)+1
      else
         knm_beg= 1
      endif
c
      knm_end=nfu(k0b  )
c
      kn0_beg=nfu(k0e)+1
      kn0_end=nfu(k0b+1)
c------------------------------------------------------
      do inp=ibeg,iend
         in0=ifrst(inp)
         icr=icoor(inp)
         inm=nmxyz(icr,in0)
c
c do kn0 & knp, do not do knm :
c
         if(inm.gt.0) then
            habcdin0=habcd(icr,in0)
            do kn0=kn0_beg,kn0_end
               knp=npxyz(icr,kn0)
               do i=1,nbls
                  xt1(i,inp,kn0)=p1234(i,icr)*xt2(i,in0,kn0)
     *                                       -xt2(i,in0,knp)
     *                              +habcdin0*xt3(i,inm,kn0)
               enddo
            enddo
         else
            do kn0=kn0_beg,kn0_end
               knp=npxyz(icr,kn0)
               do i=1,nbls
                  xt1(i,inp,kn0)=p1234(i,icr)*xt2(i,in0,kn0)
     *                                       -xt2(i,in0,knp)
               enddo
            enddo
         endif            !  if(inm.gt.0) then
c
c do knm only :
c
         do knm=knm_beg,knm_end
            kn0=npxyz(icr,knm)
            habcdkn0=habcd(icr,kn0)
            do i=1,nbls
               xt1(i,inp,kn0)=xt1(i,inp,kn0)
     *              +habcdkn0*xt2(i,in0,knm)
            enddo
         enddo
c
c because of different formulation for trackl_ than for tracij_
c recursive multipy everything by abcd(=(c+d)/(a+b) )
c
         do kn0=kn0_beg,kn0_end
            do i=1,nbls
               xt1(i,inp,kn0)=xt1(i,inp,kn0)*abcd
            enddo
         enddo
c
      enddo               !  do inp=ibeg,iend
c
c------------ saving  target classes ------------------
      if(nrec.ge.nqij) then
         do kn0=nfu(nqkl)+1,nfu(nskl+1)
            do inp=ibeg,iend
               do i=1,nbls
                  xt0(i,inp,kn0)=xt1(i,inp,kn0)
               enddo
            enddo
         enddo
      endif
c---------------- target classes ----------------------
c
      end
c=================================================================
