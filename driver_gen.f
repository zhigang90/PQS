      subroutine firstfil(inpname)
c  this routine defines the first set of files and copies
c  the input to a temporary file
c  it also gets the environmental variables PQS_ROOT, PQS_SCRDIR
c  and PQS_BASDIR  and stores them

      use sysdef
      use messages

      character*256 scrdir,basdir,jobname,fname,fname1,hname,inpname
      character*256 pqs_root,uname
      character*1 aa
      character*26 datestr,timestr
      character*120 command
      character*1 yes
      logical isthere
      character*3 extn2(29)
      common /tape/inp,inp2,iout,ipun,iarc,icond,itest,npl(9)
      data extn2(1),extn2(2),extn2(3),extn2(4),extn2(5),extn2(6)
     1  /'.11','.12','.13','.14','.15','.16'/
c
c  set pqs_root
c     
      call set_pqs_root
c
c  set basdir
c
      call getchval('pqs_root',pqs_root)
      call rmblan(pqs_root,256,len)
      basdir=''
      call get_environment_variable('PQS_BASDIR',basdir)
      call rmblan(basdir,256,len1)
      if(len1.eq.0) then
         basdir=pqs_root(1:len)//DIR_SEP//'BASDIR'
         len1=len+7
      endif
      if(basdir(len1:len1).ne.DIR_SEP) basdir(len1+1:len1+1)=DIR_SEP
      call setchval('BASDIR',basdir)
c
c  set scrdir
c
      call set_scrdir
c
      call getchval('scrdir',scrdir)
      call rmblan(scrdir,256,len)
c
c  get the jobname
c
      call getchval('jobname',jobname)
      call rmblan2(jobname,256,lenJ)
c
c  check if the jobname contains a path, in which case the path
C  part will be eliminated from the scratch file name.
C  This is done so that it is possible to run the program
c  with an input file not in the current working directory.
c  In previous version of the program this would fail because the
c  program would attemp to open the scratch files in a subdirectory
c  of the main scratch directory. fname is used for temporary storage
c
      call blankit(fname,256)
      fname=jobname(1:lenj)
      call findrootd(fname,lenJ)
      call rmblan2(fname,256,lens)
      lens=lens+1
c
c  set the scratch file name. it can be redefined with the FILE command
c  note that this is the base name of the scratch file, w/o extension
c
      call setchval('scrf',scrdir(1:len)//'pqs_scr_'
     $                                 //jobname(lens:lenJ))
c
c   input file
c
      ix=5
      inp=30
      call rmblan2(inpname,256,LenIn)
      open(unit=30,file=inpname(1:LenIn),STATUS='OLD',err=150)
      ix=30
      go to 160
  150 ix=5
  160 continue
      open(unit=31,status='scratch',form='formatted')
      call rawcopy(ix,31)
      close(30,err=170)
  170 continue
      open(unit=30,status='scratch',form='formatted')
      rewind 31
c  copy the raw input to file 30
      call inpcopy(31,inp)
      rewind inp
      icond=8
      ipun=7
      iout=6
      iarc=9
      call setival('icond',icond)
      call setival('icon',icond)
c
c  icond is also OK
c
      call setival('ipun',ipun)
      call setival('iout',iout)
      call setival('iarc',iarc)
      call setival('inp',inp)
c
      if(lenJ.eq.6.and.jobname(1:6).eq.'pqsjob') then
        open(iout)
        open(unit=icond,file='pqsjob.log')
      else
        open(unit=iout,file=jobname(1:lenJ)//'.out')
        open(unit=icond,file=jobname(1:lenJ)//'.log')
      end if
c
c  open error file if requested
c
      call getival('stderr',istderr)
      if(istderr.ne.0)then
        close(0)
        open(unit=0,file=jobname(1:lenJ)//'.err')
      endif
c  check if it is a Pople-style input
      call gaussinp(inp)

c  get date, time, executable name
      call date1(datestr)
      call chartime(timestr)
c
c -- determine hostname and executable name
      call getchval('hostname',hname)
      call rmblan(hname,256,nhn)
c  use fname temporarily
      call getchval('progname',fname)
      call rmblan(fname,256,lprogn)
c  get operating system name
      uname=''
      call get_uname(uname)
c
c -- write start and copyright headers
      write(iout,100)
  100 format(72('='))
c
      write(iout,*)
     2 'PQS  Ab Initio Program Package running on '//hname(1:nhn)
      write(iout,*)
     3              'Date       : '//datestr(1:24)
      if(len_trim(uname).gt.0)then
        write(iout,*)'System     : '//uname(1:min(len_trim(uname),56))
      endif
      write(iout,*) 'Executable : ',fname(1:lprogn)
      call printexetype(fname(1:lprogn),iout)
      call printversion(iout)
      write(iout,100)
c
      write(icond,100)
      write(icond,*)
     2 '  PQS  Ab Initio Program Package running on '//hname(1:nhn)
      write(icond,*)
     3               'Date       : '//datestr(1:24)
      if(len_trim(uname).gt.0)then
        write(icond,*)'System     : '//uname(1:min(len_trim(uname),56))
      endif
      write(icond,*) 'Executable : ',fname(1:lprogn)
      call printexetype(fname(1:lprogn),icond)
      call printversion(icond)
      write(icond,100)
c
      write(iout,3300)
 3300 FORMAT(/,
     $  '  This program is Copyright 2013 by Parallel Quantum',
     $  ' Solutions.',/,
     $  '  PQS manufactures high-performance, low-cost parallel',
     $  ' supercomputers,',/,
     $  '  complete with software, for ab initio molecular modeling',//,
     $  '  Web: www.pqs-chem.com  Ph: (479) 521-5118',
     $  '  email: sales@pqs-chem.com',//,
     $  '  This software is provided under written license and may be',
     $  ' used,',/,
     $  '  copied, transmitted or stored only in accord with that',
     $  ' license.',//,
     $  '  Cite this work as:',
     $  '  PQS version 4.1,  Parallel Quantum Solutions,',/,
     $  '  P.O.Box 293,  Fayetteville,  Arkansas  72702-0293',/,
     $  '  URL: http://www.pqs-chem.com  Email:sales@pqs-chem.com',/)
c ............................................................................
c -- temporary warning message
cc      write(iout,3301)
cc 3301 FORMAT(/,70('*'),/
cc     $'*  WARNING: This program takes advantage of Large-File',
cc     $' Handling and  *',/,
cc     $'*  is capable of writing files of size in excess of 2 GB.',
cc     $'  Multiple  *',/,
cc     $'*  file capability  (formerly in the MP2 energy routines)',
cc     $'  has been  *',/,
cc     $'*  removed. If your operating system is out of date and',
cc     $' is limited   *',/,
cc     $'*  to files no bigger than 2 GB then you will be UNABLE',
cc     $' to run large *',/,
cc     $'*  MP2 energy or MP2 gradient calculations with this',
cc     $' executable.     *',/,
cc     $'*  You should either upgrade your O/S or use an earlier',
cc     $' version of   *',/,
cc     $'*  PQS (version 3.0 or lower) to run these jobs wherever',
cc     $' possible.   *',/,70('*'),/)
c ............................................................................
c
c  copy the parallel startup messages
c  (generated BEFORE the output file is formally defined)
      call print_buf(iout,'Parallel startup:')
c -- if parallel, write number of slaves to the LOG file
      call getival('nslv',nslv)
      if(nslv.gt.0) write(icond,3302) nslv
 3302 FORMAT(I4,' slaves working on your job')
c
c -- copy the input to the big output file
      rewind 31
c     write(iout,*)
c    1'=========================  PQS input  ========================'
      write(iout,101)
  101 format(
     *  '=============================  PQS input',
     *'  ==============================')
      call rawcopy(31,iout)
      write(iout,102)
  102 format(
     *  '========================== End of PQS input',
     *'  ===========================')
c -- and to the summary (log) file
      rewind 31
      write(icond,101)
      call rawcopy(31,icond)
      write(icond,102)
      call getchval('scrf',fname)
c  Before opening the scratch files, make sure that the directory exists
c     call getchval('scrdir',fname1)
      call rmblan(fname,256,len)
      open( unit = 93, file = fname(1:len)//'.z4S',
     $      status = 'unknown', iostat = ios )
      close( 93, status = 'delete' )
      if( ios .eq. 0 ) then
        nbin=6
        do 200 i=1,nbin
          i10=i+10
          inquire(unit=i10,exist=isthere)
          if (isthere) close(unit=i10,status='delete')
          call stringcat(fname,256,extn2(i),3,fname1,lfnam)
          open(unit=i10,file=fname1(1:lfnam),form='unformatted',
     1   status='unknown')
 200    continue
      end if
c  open Krzysztof's timing file
      call open_tim
      end
c======================================================================
c
      subroutine readmem(inp,lcore,incore,indisk)
      implicit real*8 (a-h,o-z)
      character*256 chopval
c  Reads the memory card (%MEM or MEM)
c  lcore will be the number of double words requested. (MEM= or %MEM=)
c  The incore and disk integral storage can be also be given (CORE= or DISK=)
c  The incore value can be defined either in MWords or words
c  If the quantity read is < 2000, it is assumed to be MW,
c  if it is >2000, it is words
c  The default indisk value is in MB
c  NEW:  The option of specifying a unit (MB or GB) has been added    ! JB 2011
c
      parameter (nopt=4)
      dimension ioptyp(nopt)
      dimension iopval(3,nopt),ropval(3,nopt),chopval(nopt),
     $          ifound(nopt)
      character*4 options(nopt)
      data options/'mem ','%mem','core','disk'/
      data ioptyp/21,21,21,21/
c
      call izeroit(iopval,3*nopt)
      call zeroit(ropval,3*nopt)
      call readop1(inp,    nopt,   options,ioptyp, iopval,
     $             ropval, chopval,ifound)
c
c -- mem and %mem options
      if(ifound(1).eq.1) lcore = memfunc(chopval(1))
      if(ifound(2).eq.1) lcore = memfunc(chopval(2))
      if(lcore.lt.2000) then
        lcore=lcore*1 000 000
      endif
c
c -- incore and disk storage options
      if(ifound(3).eq.1) incore = memfunc(chopval(3))
      if(incore.lt.2000) incore=incore*1 000 000
      if(ifound(4).eq.1) indisk = memfunc(chopval(4))
      If(indisk.ge.2000) indisk = indisk/125 000
c
c -- total allocatable memory is the sum of lcore & incore
      lcore = lcore + incore
c
      return
      end
c======================================================================
c
      INTEGER FUNCTION memfunc(char)
      IMPLICIT INTEGER(A-Z)
C
C  Interprets the memory or disk storage request
C  Input parameter is a character string which can either be an integer only
C  or an integer followed by a unit (MB or GB)
C  Returns a value in double (8-byte) words
C
      CHARACTER*256 char
      Character*1 num(10)
c
      DATA num /'0','1','2','3','4','5','6','7','8','9'/
c
      i = 0
 10   CONTINUE
      i = i+1
      do k=1,10
      If(char(i:i).eq.num(k)) go to 10
      enddo
c
c -- if here, numbers finished
c -- read in integer value
c
      READ(char(1:i-1),*) mem
c
c -- is there a unit?
c
      If(char(i:i).eq.'M'.or.char(i:i).eq.'m') then
        memfunc = mem*125 000         ! request in MB
      Else If(char(i:i).eq.'G'.or.char(i:i).eq.'g') then
        memfunc = mem*125 000 000     ! request in GB
      Else
        memfunc = mem                 ! no units given
      EndIf
C
      RETURN
      END
c======================================================================
c
      subroutine allocmem(nwords,ioffset)

      use memory

      implicit real*8 (a-h,o-z)
c     common /big/bl(0:0)
c
c -- allocate the memory
c     call falloc(BL(1),8*nwords,ioffset,IErr)
      call mem_alloc( nwords, ierr )
      If(IErr.LT.0) Then
        call nerror(1,'allocmem','Unable to allocate memory',nwords,0)
      EndIf
      ioffset = 0
      nwords = nwords + ioffset
c
c -- initialize floating-point and integer storage and the matrix system
      call retall(ioffset)
      call getmem(0,lastx)
      end
c======================================================================
c
      subroutine fileopen
c  this routine opens the log and scratch files if they are explicitly
c  defined with the FILE  SAVE=<savfile>  SCR=<scratchfile> command
      logical isthere
      character*256 fname,fname1
      character*4 extn1(3)
      character*3 extn2(29)
      data extn1/'.pun','.log','.ark'/
      data extn2(1),extn2(2),extn2(3),extn2(4),extn2(5),extn2(6)
     1  /'.11','.12','.13','.14','.15','.16'/

      call tstchval('savf',iexist)
c  The user explicitly defined a file name different from the
c   job name. Use this for all intermediate files, and also
c   for the output and log files
      if(iexist.ge.1) then
        call getchval('savf',fname)
        i=8
        inquire(unit=i,exist=isthere)
        if (isthere) Then
c -- copy existing log file to new filename
          open(unit=40,status='scratch',form='formatted')
          rewind i
          call rawcopy(i,40)
          close(unit=i,status='delete')
          call stringcat(fname,256,extn1(i-6),4,fname1,lfnam)
          open (unit=i,file=fname1(1:lfnam),form='formatted')
          rewind 40
          call rawcopy(40,i)
          close (unit=40)
        end if
      end if
      end
c======================================================================
c
      subroutine rawcopy(inp,iout)
      implicit none
      integer inp,iout
      integer, parameter:: linew=300
      character(len=linew) :: line
      integer len,i,ios

      do
        line=''
        read(inp,'(a)',end=200,iostat=ios)line
        len=len_trim(line)
        if(line(len:len).eq.char(13)) len=len-1 ! ignore end-of-line character
        do i=1,len
          if(line(i:i).eq.char(9)) line(i:i)=' '! replace tab by space
        end do
        write(iout,'(a)')line(1:len)
      enddo
 200  continue
      len=len_trim(line)
      if(len.gt.0)then
        if(line(len:len).eq.char(13)) len=len-1 ! ignore end-of-line character
        do i=1,len
          if(line(i:i).eq.char(9)) line(i:i)=' '! replace tab by space
        end do
        write(iout,'(a)')line(1:len)
      endif
      end
c======================================================================
c
      subroutine readfnam(inp)

      use sysdef

      real*8 ropval
      character*256 jobname,fname,fname1
      logical exists,isthere
      common /job/jobname,lenJ
c   this routine reads the 'file' card and resets the scratch directory,
c   filenames etc...
      parameter (nopt=5)
      character*4 options(nopt)
      character*256 chopval,scrdir
      character*3 extn2(6)
      dimension ioptyp(nopt)
      dimension iopval(3,nopt),ropval(3,nopt),chopval(nopt),
     1          ifound(nopt)
      data options/'save','chk ','scr ','keep','basd'/
      data extn2(1),extn2(2),extn2(3),extn2(4),extn2(5),extn2(6)
     1  /'.11','.12','.13','.14','.15','.16'/
c  the "21" type is character input
      data ioptyp/21,21,21,0,21/
c
ccccc
cc      write(6,*) ' On entrance to <readfnam>'
cc      call getchval('scrdir',fname)
cc      call rmblan2(fname,256,len)
cc      write(6,*) ' scratch directory is: ',fname(1:len)
cc      call getchval('scrf',fname)
cc      call rmblan2(fname,256,len)
cc      write(6,*) ' root scratch filename is: ',fname(1:len)
ccccc
      call readopt(inp,nopt,options,ioptyp,iopval,ropval,chopval,ifound)
      iout=igetival('iout')
      if (ifound(1).eq.1) then
         call setchval('savf',chopval(1))
         call setchval('jobname',chopval(1))
         jobname=chopval(1)
         call rmblan2(jobname,256,LenJ)
         write(iout,*)
     1    'Temporary files redefined by user and saved under ',
     1     jobname(1:LenJ)
      end if
      if(ifound(2).eq.1) then
c  check option
        call checkfile(chopval(2))
      end if
c  scratch option SCR
c -- changed to define different scratch DIRECTORY only     ! JB  March 2005
      if (ifound(3).eq.1) then
         call rmblan(chopval(3),256,len)
         If(chopval(3)(len:len).NE.DIR_SEP) Then
           len = len+1
           chopval(3)(len:len) = DIR_SEP
         EndIf
         call setchval('scrdir',chopval(3)(1:len))
         write(iout,*) 'Scratch directory redefined by user as: ',
     $                 chopval(3)(1:len)
c -- redefine root scratch filename
c    use fname1 as temporary storage
         call blankit(fname1,256)
         fname1=jobname(1:lenJ)
         call findrootd(fname1,lenJ)
         call rmblan2(fname1,256,lens)
         lens=lens+1
         fname = chopval(3)(1:len)//'pqs_scr_'//jobname(lens:LenJ)
         lens=len+(lenj-lens+1)+8
         call setchval('scrf',fname(1:lens))
      end if
c  test if the scratch directory specified really exists
      call getchval('scrf',fname)
      call rmblan(fname,256,lens)
      open( unit = 93, file = fname(1:lens)//'.z4S',
     $      status = 'unknown', iostat = ios )
      close( 93, status = 'delete' )
      if( ios .ne. 0 ) then
        call nerror(1,'readfnam',
     1  'The scratch directory assumed or explicitly specified:'
     2   //scrdir(1:len)//' does not exist',0,0)
      end if
c  close the old scratch files if they exist
      call getchval('scrf',fname)
      nbin=6
      do 200 i=1,nbin
        i10=i+10
        inquire(unit=i10,exist=isthere)
        if (isthere) close(unit=i10,status='delete')
        call stringcat(fname,256,extn2(i),3,fname1,lfnam)
        open(unit=i10,file=fname1(1:lfnam),form='unformatted',
     1   status='unknown')
 200  continue

c  keep option
      if (ifound(4).eq.1) then
         call setival('keep',1)
      end if
c  basdir option
      if (ifound(5).eq.1) then
        call rmblan2(chopval(5),256,len)
        if(chopval(5)(len:len).ne.DIR_SEP) then
             len=len+1
             chopval(5)(len:len)=DIR_SEP
        end if
        call setchval('BASDIR',chopval(5))
       end if
ccccc
cc      write(6,*) ' On exit from <readfnam>'
cc      call rmblan2(fname,256,len)
cc      write(6,*) ' scratch directory is: ',fname(1:len)
cc      call getchval('scrf',fname)
cc      call rmblan2(fname,256,len)
cc      write(6,*) ' root scratch filename is: ',fname(1:len)
ccccc
      end
c======================================================================
c
      subroutine jobparam(inp)
c  this routine reads the main job parameters
      implicit real*8 (a-h,o-z)
      parameter (nopt=5)
      character*4 options(nopt)
      character*4 methods(4),meth1
      character*256 chopval
      dimension ioptyp(nopt)
      dimension iopval(3,nopt),ropval(3,nopt),chopval(nopt),
     1 ifound(nopt)
      data options/'time','chec','meth','prec','dire'/
c  time is the max. job time in seconds, check is 1 if this is a
c  checkrun, method is either molm,abin,semi,or dft. the default is abin
      data methods/'abin','molm','semi','dft '/
      data ioptyp/11,0,21,1,1/

      call setchval('meth',methods(1))
      call readopt(inp,nopt,options,ioptyp,iopval,ropval,chopval,ifound)
      if(ifound(1).eq.1) then
        call setrval('time',ropval(1,1))
      end if
      if (ifound(2).eq.1) then
        call setival('chec',iopval(1,2))
      end if
      if (ifound(3).eq.1) then
        meth1=chopval(3)
        call lowerca2(meth1,4)
        do 100 k=1,4
          if(meth1.eq.methods(k)) then
            call setchval('meth',methods(k))
                go to 200
          end if
 100    continue
              call nerror(1,'jobparam','unknown option'//chopval(3),0,0)
      end if
 200  continue
      if (ifound(4).eq.1) call setival('prec',iopval(1,4))
      if(ifound(5).eq.1) call setival('dire',iopval(1,5))
      end
c======================================================================
c
      subroutine cpuset
      implicit real*8 (a-h,o-z)
c  this common is included for some older routines but the modern
c  way of accessing these data is through the setval - getval routines
      common /cpu/intsize,iacc,icache,memreal

      intsize =  64 / bit_size ( 0 )  ! how many default integers
                                      ! fit in a double precision
                                      ! word

      iacc = precision( 0.0d0 ) ! decimal precision 

           ! get cache size ( double precision words )
           ! the default values is 16384

c     call getcache( icache, ierr )
c     if ( ierr .ne. 0 ) then
        icache = 16384
c     endif

           ! get real memory size ( double precision words )
           ! the default values is 32 000 000 (256 MB)
           ! actually, this does not make too much sense
           ! anymore and should be taken out

c     call getmemreal(memreal,ierr)
c     if ( ierr .ne. 0 ) then
        memreal = 32000000
c     endif

      nslv=0   ! default number of slaves

           ! store values into the depository

      call setival('ints',intsize)
      call setival('double',8)
      call setival('accu',iacc)
      call setival('cach',icache)
      call setival('memr',memreal)
      call setival('nslv',nslv)
c
      end
c======================================================================
c
      subroutine cpuparm(inp)
      real*8 ropval
c  this routine allows the resetting of main cpu parameters
      parameter (nopt=5)
      character*4 options(nopt)
      character*256 chopval
      dimension ioptyp(nopt)
      dimension iopval(3,nopt),ropval(3,nopt),chopval(nopt),
     1 ifound(nopt)
      common /cpu/intsize,iacc,icache,memreal
      data options /'ints','accu','cach','memr','doub'/
      data ioptyp /1,1,1,1,1/

      call readopt(inp,nopt,options,ioptyp,iopval,ropval,chopval,ifound)
      if(ifound(1).eq.1) then
        call setival('ints',iopval(1,1))
      end if
      if (ifound(2).eq.1) then
        call setival('accu',iopval(1,2))
      end if
      if(ifound(3).eq.1) then
        call setival('cach',iopval(1,3))
        icache=iopval(1,3)
      end if
      if (ifound(4).eq.1) then
        memr=iopval(1,4)
        if(memr.lt.2000) memr=memr*1 000 000
        call setival('memr',memr)
      end if
      if(ifound(5).eq.1) then
        idouble=iopval(1,5)
        call setival('double',idouble)
      end if
      if(ifound(1).eq.1.and.ifound(5).eq.1) then
        intsize=idouble/iopval(1,1)
      else if(ifound(1).eq.1.and.ifound(5).ne.1) then
        intsize=8/iopval(1,1)
      else if(ifound(5).eq.1.and.ifound(1).ne.1) then
        intsize=idouble/4
      end if
      end
c======================================================================
c
      Subroutine jumpb(inp)
      IMPLICIT INTEGER(A-Z)
c
c  Simple routine that "jumps back" a number of lines
c  in the input file
c  The original version jumped back n cards. This still works.
c  However, the intended use is to jump back to the preceding
c "jump command" (e.g. OPTI) unless another JUMP card is encountered
c
      parameter (njumpc=9)
c
c  njumpc is the number of possible "jump targets". A "jump target"
c  is the destination of a jump-back
c
      character*80 card
      character*4 cmd,jumpc(njumpc)
      logical findp
      data jumpc/'opti','numh','dyna','scan','path','nump',
     *           'nume','numg','numc'/
c
c  get the number of cards to jump (if given)
c
      Read(inp,900) card
      jump=0
 900  Format(A80)
      Read(card(6:80),*,end=1000,err=1000) jump
      if(jump.le.0) go to 1000
      Do 10 I=1,jump+1
      Backspace inp
 10   Continue
c
      Return
c
 1000 continue
c  No number is given - this will be the default mode. The previous
c  section is only provided for backward compatibility, although the
c  code would work without it.
c
c -- number of cards jumped back - needed to prevent infinite loops
      nback=0
c -- jump back to the next preceding jump target if jumplevel becomes 0
      jumplevel=0
c -- has a PATH card been encountered?
      findp = .false.
c
 1100 continue
      backspace inp
      read(inp,'(a4)') cmd
      backspace inp
      call lowerca2(cmd,4)
c -- reading the original JUMP card sets jumplevel=1
      if(cmd.eq.'jump') jumplevel=jumplevel+1
      nback=nback+1
      do i=1,njumpc
        if(cmd.eq.jumpc(i))  go to 1200
      end do
      if(nback.gt.10000) go to 2000
      go to 1100
 1200 continue
c -- be careful if PATH (there are TWO PATH cards)
      If(cmd.eq.'path'.AND..NOT.findp) Then
        findp = .true.
      Else
        jumplevel=jumplevel-1
      EndIf
c
      If(jumplevel.eq.0)  Then
        Return
      Else
        go to 1100
      EndIf
c
 2000 continue
      call nerror(1,'Problem in main DRIVER',
     1 'Jump card has no associated jump target', nback,jump)
c
      End
c======================================================================
c
      Subroutine jumpc(inp,keywrd)
      IMPLICIT INTEGER(A-Z)
c
c  simple routine that "jumps back" to a line with a given
c  keyword in the input file
c
      Character*4 keywrd,card
c
c  read back until the keyword is found
c
      Backspace inp
c
  10  Backspace inp
      Read(inp,900,end=95,err=95) card
      call lowerca2(card,4)
      Backspace inp
      If(card.eq.keywrd) RETURN
      go to 10
c
 95   Continue
      Call nerror(3,'Problem in main DRIVER',
     $  'Unable to find matching keyword in input deck!',0,0)
c
 900  Format(A4)
c
      End
c======================================================================
c
      Subroutine jumpf(inp)
      IMPLICIT INTEGER(A-Z)
c
c  simple routine that "jumps forward" from the current position
c  to the matching JUMP line in the input file
c
ckw07 parameter (njumpc=6)
ckw08 parameter (njumpc=8)
      parameter (njumpc=9)
c  njumpc is the number of possible "jump targets". A "jump target"
c  is the destination card of a jump-back
c
      character*80 card
      character*4 cmd,jumpc(njumpc)
      logical findp
ckw07 data jumpc/'opti','numh','dyna','scan','path','nump'/
      data jumpc/'opti','numh','dyna','scan','path','nump',
     *           'nume','numg','numc'/
c
c -- jump back to the next preceding jump target if jumplevel becomes 0
      jumplevel=1
c -- has a PATH card been encountered?
      findp = .false.
c
c  read until you find a suitable jump
c
      icount = 0
 10   Read(inp,900,end=95) card
      icount = icount+1
      call lowerca2(card,4)
      cmd = card(1:4)
      If(cmd.EQ.'path'.AND..NOT.findp) Then
        findp = .true.
        go to 10
      EndIf
      do i=1,njumpc
        if(cmd.eq.jumpc(i))  jumplevel=jumplevel+1
      end do
      If(cmd.ne.'jump') Then
        go to 10
      Else
        jumplevel=jumplevel-1
        if(jumplevel.gt.0) go to 10
      EndIf
c
c  found a JUMP card
c
      call setival('isumscf',0)      ! reset SCF summary print flag
      Return
c
 95   Continue
      Call nerror(2,'Problem in main DRIVER',
     $  'Unable to find matching JUMP line in input deck!',0,0)
c
 900  Format(A80)
c
      End
c======================================================================
c
      subroutine cleanup(inp,optcyc)
c
c  cleans up (removes) old <opt> and <optchk> files
c  and (optionally) the <hess> file
c
      character*80 char
      integer optcyc
c
      parameter (IUnit=1)
      character*256 jobname
      Common /job/jobname,lenJ
c
      OPEN (UNIT=IUnit,FILE=jobname(1:lenJ)//'.opt',
     $      FORM='FORMATTED',STATUS='UNKNOWN')
      CLOSE (UNIT=IUnit,STATUS='DELETE')
      OPEN (UNIT=IUnit,FILE=jobname(1:lenJ)//'.optchk',
     $      FORM='FORMATTED',STATUS='UNKNOWN')
      CLOSE (UNIT=IUnit,STATUS='DELETE')
c
      read(inp,'(a9)') Char
      call lowerca2(Char,9)
      If(Char(7:9).eq.'all') Then
        OPEN (UNIT=IUnit,FILE=jobname(1:lenJ)//'.hess',
     $        FORM='FORMATTED',STATUS='UNKNOWN')
        CLOSE (UNIT=IUnit,STATUS='DELETE')
      EndIf
c
      optcyc = 0
c
      return
      end
c====================================================================
      subroutine CheckScratch
      character*256 scrdir,scrf
      logical isthere
      integer*4 ios
      call getchval('scrdir',scrdir)
      call rmblan(scrdir,256,len)
      call getchval('scrf',scrf)
      call rmblan(scrf,256,lenj)
      open( unit = 93, file = scrf(1:lenj)//'.z4S',
     $      status = 'unknown', iostat = ios )
      close( 93, status = 'delete' )
      if( ios .ne. 0 ) then
         write(6,*) 'Scratch directory' ,scrdir(1:len),' does not exist'
         call nerror(2,'CheckScratch',
     2  'Please create a scratch directory with write permission',0,0)
      end if
      end
c=====================================================================
      subroutine printversion(ichan)
c
c  prints the pqs version and revision
c
      implicit none
      integer ichan
      character*256 version, revision, restrict, archit
      integer lenver,lenrev,lenres,lenarc 

      version=''
      revision=''
      restrict=''
      archit=''
      call getchval('version',version)
      lenver = len_trim(version)
      call getchval('revision',revision)
      lenrev = len_trim(revision)
      call getchval('restrict',restrict)
      lenres = len_trim(restrict)
      call getchval('archit',archit)
      lenarc = len_trim(archit)
cc      if(lenrev.gt.0)then
      if(lenrev.ge.0)then
        write(ichan,*) 'PQS Version: ',version(1:lenver),
     $                           ' - ',revision(1:lenrev),
     $                           ' - ',restrict(1:lenres),
     $                           ' ',archit(1:lenarc)
      else
        write(ichan,*) 'PQS Version: ',version(1:lenver),
     $                           ' - Development Release',
     $                           ' - ',restrict(1:lenres),
     $                           ' ',archit(1:lenarc)
        write(ichan,100)
        if(ichan.eq.6)write(0,100) ! write to standard error
      endif

 100  FORMAT(/,70('*'),/
     $'*  WARNING: This is a development release. DO NOT DIST',
     $'RIBUTE!!!!!!!! *',/,70('*'),/)
      end
c=====================================================================
      subroutine parsearguments(progname,inpname)
c
c  parses the program arguments and returns the names of the program
c  running and of the input file
c
c  reconnized options:
c
c  option    value          meaning                   action
c
c  -np       nproc     number of processes    ignored (dealt with by parallel driver)
c
c  -f      hostfile       pvm hostfile                  ditto
c
c  -v        none      version information    print version number then stop
c  -version  
c  --version  
c
c  -h        none      usage information      print help message then stop
c  -help
c  --help
c
c  -c        none      license check          check license then stop    
c  -check   
c  --check   
c
c  -l        none      lockcode               generate lockcode then stop
c  -lockcode
c  --lockcode
c
c  -i       inpname     name of input         set output variable inpname
c  -input
c  --input
c           inpname                           (the name of the input can be
c                                              preceeded by one of the -i options
c                                              or not, in other words: the first 
c                                              argument not starting with a dash 
c                                              and not preceeded by one of the above 
c                                              options is assumed to be the input name)
c                                              NOTE: there can be only one input name
c                                              specification for a given run
c
c -err      none      error file              instruct the program to open a file 
c                                             jobname.err to store the standard error
c                                             channel (mostly useful for the Windows 
c                                             version
c                                             
c -tim      none      timing file             instruct the program to open a file 
c                                             jobname.tim to store Krzystof's
c                                             timing information for the integral
c                                             module. By default this file is sent 
c                                             to /dev/null (useful for debugging)
c                                             
      use messages
      implicit none
      character*256 progname,inpname,prodstr,hname
      character*256 arg,temp
      character*256 pqsroot,lockkey
      integer numarg, i, l, lpqsr
      integer*4 lic, chklicense
      logical dryrun,readname
      integer*4 lockcode,lockcode_file
      integer*4 lock
      integer*4 iresp

      call get_command_argument(0,progname) ! program name
      inpname='pqsjob.inp'
      numarg=command_argument_count()

      if(numarg.gt.0)then
        dryrun=.false.
        readname=.true.

        i=1
        do 
          arg=''
          call get_command_argument(i,arg)
          l=len_trim(arg)
          temp=arg
          call lowerca2(temp,l)
          if(temp.eq.'-np'.and.i.lt.numarg)then
            i=i+2
          else if(temp.eq.'-f'.and.i.lt.numarg)then
            i=i+2
          else if(temp.eq.'-v'.or.temp.eq.'-version'
     $                        .or.temp.eq.'--version')then
            call printversion(0)
            dryrun=.true.
            i=i+1
          else if(temp.eq.'-h'.or.temp.eq.'-help'
     $                        .or.temp.eq.'--help')then
            call para_printhelp(0)
            dryrun=.true.
            i=i+1
          else if(temp.eq.'-c'.or.temp.eq.'-check'
     $                        .or.temp.eq.'--check')then
            call getchval('prodstr',prodstr)  ! pqs license
            lic = chklicense(prodstr)
            if(lic.gt.0)then
              write(0,*)
              write(0,*)'*** PQS license is valid ***'
              write(0,*)
              if(lic.gt.1.and.lic.lt.9999)then
                write(0,'(a,1x,i0)')'Maximum number of processes:',lic
                write(0,*)
              else if(lic.eq.9999) then
                write(0,*)'Maximum number of processes: Unlimited'
                write(0,*)
              endif
            else
              write(0,*)
              write(0,*)'No valid PQS license was found.'
              write(0,*)
              write(0,*)'To obtain a license, please run the command ',
     $                   '''pqs.x -lockcode'' '
              write(0,*)'to generate a lockcode and contact PQS.'
              write(0,*)
            endif
            call getchval('nbostr',prodstr)  ! NBO license
            lic = chklicense(prodstr)
            if(lic.gt.0)then
              write(0,*)
              write(0,*)'*** NBO license is valid ***'
              write(0,*)
            else
              write(0,*)
              write(0,*)'No valid license for the optional NBO module ',
     $                  'was found.'
              write(0,*)
              write(0,*)'Please contact PQS if you wish to order NBO.'
              write(0,*)
            endif
            dryrun=.true.
            i=i+1
          else if(temp.eq.'-l'.or.temp.eq.'-lockcode'
     $                        .or.temp.eq.'--lockcode')then
            call getchval('lockkey',lockkey)  ! lockode key
            iresp=lockcode_file(lockkey)
            if(iresp.eq.0)then
               write(0,*)
               write(0,*)'A lockcode has been added to the file ',
     $                   'pqs_lockcode'
               write(0,*)
            else
               write(0,*)
               write(0,*)'Error: cannot open the lockcode file'
               write(0,*)
            endif
            dryrun=.true.
            i=i+1
          else if((temp.eq.'-i'.or.temp.eq.'-input'
     $      .or.temp.eq.'--input').and.(i.lt.numarg.and.readname))then
            arg=''
            call get_command_argument(i+1,arg)
            inpname=arg
            readname=.false.
            i=i+2
          else if(temp.eq.'-err') then
            call setival('stderr',1)
            i=i+1
          else if(temp.eq.'-tim') then
            call setival('tim',1)
            i=i+1
          else if(temp(1:1).ne.'-'.and.readname)then
            inpname=arg
            readname=.false.
            i=i+1
          else
c           write(0,*)'ERROR: ',arg(1:l),' is not a valid argument'
c           call para_printhelp(0)
c           dryrun=.true.
c           i=numarg+1
            i=i+1
          endif
          if(i.gt.numarg)exit
        enddo

        if(dryrun) then
          write(0,*)
          write(0,*)'The program is exiting.'
          write(0,*)
          call cat_channel(0,'PQS dry run message:') !pop up a windows message box
          stop
        endif
      endif

      end
