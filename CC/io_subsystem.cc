#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
namespace {
static inline void must_be_true(const bool condition, const char* const message)
{
if (condition) return;
printf(message);
fflush(stdout);
abort();
}
//============================================
const int MAX_OPEN_FILES=1000;
class file_info {
public:
  off_t position;
  size_t rec_len;
  char * filename;
  file_info() : position(0), rec_len(0), filename(0) {}
  ~file_info() {
    delete[] filename;
    }
};
file_info files[MAX_OPEN_FILES];
}
//============================================
extern "C" {
#ifdef UNDERSCORE2
void s_open__(const char * path,long * ndisk,const long * rec_len,int len) {
#else
void s_open_(const char * path,long * ndisk,const long * rec_len,int len) {
#endif
  char * path1=new char[len+1];
  for (int i=0;i<len;++i) path1[i]=path[i];
  path1[len]='\000';
  *ndisk=open(path1,O_RDWR|O_CREAT|O_TRUNC,00666);
  must_be_true(*ndisk>=0,"Opening file failed\n");
  must_be_true(*ndisk<MAX_OPEN_FILES,"Opening file failed\n");
  files[*ndisk].position=0;
  files[*ndisk].rec_len=*rec_len;
  files[*ndisk].filename=path1;
  }

//============================================

#ifdef UNDERSCORE2
void s_write__(const long * ndisk,const long * rec, const char * data) {
#else
void s_write_(const long * ndisk,const long * rec, const char * data) {
#endif
  size_t rec_len=files[*ndisk].rec_len;
  off_t asked_pos=(*rec-1)*rec_len;
  if (asked_pos!=files[*ndisk].position) {
    off_t c=lseek(*ndisk,asked_pos,SEEK_SET);
    must_be_true(c==asked_pos,"s_write: lseek failed\n");
    files[*ndisk].position=asked_pos;
    }
  ssize_t x=write(*ndisk,data,rec_len);
  must_be_true(x==rec_len,"Write in s_write failed\n");
  files[*ndisk].position+=rec_len;
  }

//============================================

#ifdef UNDERSCORE2
void s_write_pl__(const long * ndisk,const long * pos, const long * len, const char * data) {
#else
void s_write_pl_ (const long * ndisk,const long * pos, const long * len, const char * data) {
#endif
  size_t rec_len=*len;
  off_t asked_pos=*pos;
  if (asked_pos!=files[*ndisk].position) {
    off_t c=lseek(*ndisk,asked_pos,SEEK_SET);
    must_be_true(c==asked_pos,"s_write: lseek failed\n");
    files[*ndisk].position=asked_pos;
    }
  ssize_t x=write(*ndisk,data,rec_len);
  must_be_true(x==rec_len,"Write in s_write failed\n");
  files[*ndisk].position+=rec_len;
  }

//============================================

#ifdef UNDERSCORE2
void s_read__(const long * ndisk,const long * rec, char * data) {
#else
void s_read_(const long * ndisk,const long * rec, char * data) {
#endif
  size_t rec_len=files[*ndisk].rec_len;
  off_t asked_pos=(*rec-1)*rec_len;
  if (asked_pos!=files[*ndisk].position) {
    off_t c=lseek(*ndisk,asked_pos,SEEK_SET);
    must_be_true(c==asked_pos,"s_read: lseek failed\n");
    files[*ndisk].position=asked_pos;
    }
  ssize_t x=read(*ndisk,data,rec_len);
  must_be_true(x==rec_len,"Read in s_read failed\n");
  files[*ndisk].position+=rec_len;
  }

//============================================

#ifdef UNDERSCORE2
void s_read_pl__(const long * ndisk,const long * pos, const long * len, char * data) {
#else                                                                  
void s_read_pl_ (const long * ndisk,const long * pos, const long * len, char * data) {
#endif
  size_t rec_len=*len;
  off_t asked_pos=*pos;
  if (asked_pos!=files[*ndisk].position) {
    off_t c=lseek(*ndisk,asked_pos,SEEK_SET);
    must_be_true(c==asked_pos,"s_read: lseek failed\n");
    files[*ndisk].position=asked_pos;
    }
  ssize_t x=read(*ndisk,data,rec_len);
  must_be_true(x==rec_len,"Read in s_read failed\n");
  files[*ndisk].position+=rec_len;
  }

//============================================

#ifdef UNDERSCORE2
void s_close__(const long * ndisk) {
#else
void s_close_(const long * ndisk) {
#endif
  close(*ndisk);
  unlink(files[*ndisk].filename);
  delete[] files[*ndisk].filename;
  files[*ndisk].filename=0;
  }
#ifdef UNDERSCORE2
void s_close_keep__(const long * ndisk) {
#else
void s_close_keep_(const long * ndisk) {
#endif
  close(*ndisk);
  delete[] files[*ndisk].filename;
  files[*ndisk].filename=0;
  }
} // extern "C"
