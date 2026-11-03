// Use the real Android backend and the existing fake JNI/SDL shell.
#define NV_ASS_LIBASS 1
#define mkv_faixas testMkvRead
#define main previousAndroidResumeMain
#include "video_android_retomada.c"
#undef main
#undef mkv_faixas
#include <unistd.h>
static pthread_mutex_t testLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t testCond = PTHREAD_COND_INITIALIZER;
static int testReads, testRelease, testFinished;
int testMkvRead(const char *url, MkvFaixa *fx, int max) {
  (void)url; assert(max >= 3);
  pthread_mutex_lock(&testLock); testReads++;
  while (!testRelease) pthread_cond_wait(&testCond, &testLock);
  pthread_mutex_unlock(&testLock);
  memset(fx, 0, 3 * sizeof *fx);
  fx[0].tipo=1; fx[0].numero=1;
  fx[1].tipo=17; fx[1].numero=5; strcpy(fx[1].codec,"S_HDMV/PGS");
  fx[2].tipo=17; fx[2].numero=20; strcpy(fx[2].codec,"S_TEXT/ASS");
  pthread_mutex_lock(&testLock); testFinished++; pthread_mutex_unlock(&testLock);
  return 3;
}
static void waitFinished(int count) {
  for (int i=0;i<500;i++) {
    pthread_mutex_lock(&testLock); int done=testFinished>=count; pthread_mutex_unlock(&testLock);
    if (done) return;
    usleep(1000);
  }
  assert(!"MKV reader did not finish");
}
int main(void) {
  nLeg=1; faixaLeg[0]=(VideoFaixa){.numero=0,.ordinalMkv=-1};
  strcpy(urlAtual,"https://example.invalid/test.mkv");
  strcpy(faixaLeg[0].codec,"S_TEXT/UTF8");
  androidMkvZerar(0);
  assert(video_mkv_sondado()==2 && testReads==0); // no Range for SRT
  strcpy(faixaLeg[0].codec,"S_TEXT/ASS"); mkvIds[0]=20;
  assert(video_mkv_sondado()==0);
  // Stop/source change while probe is in flight: never publish the old title.
  androidMkvZerar(1);
  pthread_mutex_lock(&testLock); testRelease=1; pthread_cond_broadcast(&testCond); pthread_mutex_unlock(&testLock);
  waitFinished(1);
  assert(video_mkv_sondado()==2 && mkvN==0);
  androidMkvZerar(0);
  assert(video_mkv_sondado()==0);
  waitFinished(2);
  int state=0;
  for(int i=0;i<500 && !state;i++) { state=video_mkv_sondado(); if(!state) usleep(1000); }
  assert(state==1 && video_legenda_ordinal_mkv(0)==1);
  assert(!strcmp(faixaLeg[0].codec,"S_TEXT/ASS"));
  mkvIds[0]=99; faixaLeg[0].ordinalMkv=-1;
  assert(video_mkv_sondado()==1 && video_legenda_ordinal_mkv(0)==-1);
  puts("PASS: Android ASS probe, no SRT network overhead, stale-session discard, exact track mapping");
}
