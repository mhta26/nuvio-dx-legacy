#include "streams.h"
#include "faixasmkv.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int evidence(const char *body) {
  char json[4096]; Stream *s = NULL;
  snprintf(json, sizeof json, "{\"streams\":[{\"url\":\"https://example.invalid/anime.mkv\",%s}]}", body);
  assert(stream_extrair(json, "AIOStreams Stable", &s) == 1);
  int found = s[0].assArabeEmbutida;
  assert(stream_prefere_ass_arabe(s, 1, "ar") == found);
  assert(stream_prefere_ass_arabe(s, 1, "ara") == found);
  assert(!stream_prefere_ass_arabe(s, 0, "ar"));
  assert(!stream_prefere_ass_arabe(s, 1, "en"));
  assert(!stream_prefere_ass_arabe(s, 1, "none"));
  free(s); return found;
}
int main(void) {
  assert(evidence("\"streamData\":{\"parsedFile\":{\"mediaInfoQuality\":\"probe\",\"subtitleTracks\":[{\"lang\":\"ara\",\"codec\":\"ass\"}]}}"));
  assert(evidence("\"clientResolve\":{\"stream\":{\"raw\":{\"parsed\":{\"mediaInfoQuality\":\"indexer\",\"subtitleTracks\":[{\"lang\":\"Arabic\",\"codec\":\"S_TEXT/SSA\"}]}}}}"));
  assert(!evidence("\"streamData\":{\"parsedFile\":{\"mediaInfoQuality\":\"probe\",\"subtitleTracks\":[{\"lang\":\"ar\",\"codec\":\"srt\"},{\"lang\":\"en\",\"codec\":\"ass\"}]}}"));
  assert(!evidence("\"streamData\":{\"parsedFile\":{\"languages\":[\"Arabic\"],\"subtitles\":[\"Arabic\"],\"container\":\"mkv\"}},\"name\":\"Arabic ASS MKV\""));
  assert(!evidence("\"subtitles\":[{\"lang\":\"ar\",\"codec\":\"ass\",\"url\":\"https://example.invalid/sub.ass\"}]"));
  assert(!evidence("\"streamData\":{\"parsedFile\":{\"mediaInfoQuality\":\"addon\",\"subtitleTracks\":[{\"lang\":\"ar\",\"codec\":\"ass\"}]}}"));
  assert(!evidence("\"streamData\":{\"parsedFile\":{\"subtitleTracks\":[{\"lang\":\"ar\",\"codec\":\"ass\"}]}}"));
  // Text indices do not equal file ordinals: an unsupported subtitle precedes ASS.
  MkvFaixa tracks[] = {{.numero=1,.tipo=1}, {.numero=5,.tipo=17,.codec="S_HDMV/PGS"},
    {.numero=9,.tipo=2}, {.numero=20,.tipo=17,.codec="S_TEXT/ASS"}, {.numero=28,.tipo=17,.codec="S_TEXT/SSA"}};
  VideoFaixa f = {.numero=0,.ordinalMkv=-1};
  assert(faixasmkv_por_numero(&f,20,tracks,5));
  assert(f.ordinalMkv==1 && !strcmp(f.codec,"S_TEXT/ASS") && f.numero==0);
  assert(faixasmkv_por_numero(&f,28,tracks,5) && f.ordinalMkv==2);
  f.ordinalMkv=-1; f.codec[0]=0;
  assert(!faixasmkv_por_numero(&f,9,tracks,5) && f.ordinalMkv==-1 && !f.codec[0]);
  assert(!faixasmkv_por_numero(&f,-1,tracks,5));
  puts("PASS: embedded Arabic ASS/SSA provenance, language/anime scope, exact Matroska track identity");
}
