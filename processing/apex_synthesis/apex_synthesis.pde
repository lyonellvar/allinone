/**
 * APEX 9.0 — SYMBIOSIS MUSEAL (ESTÁNDAR EXTRAORDINARIO)
 * Processing 4.3 | P2D | 1080x1080
 *
 * CONCEPTO: Un mar de bits (números) fluye alrededor de formas geométricas orgánicas
 * (amebas). La interacción entre ambos genera una danza armónica donde cada elemento
 * respeta al otro. La obra transforma lo invisible (fuerzas, recuerdos, relaciones)
 * en un sistema visual riguroso y poético.
 *
 * SISTEMA DE COLOR: un único acorde cromático por mutación (monocromático, análogo,
 * complementario, complementario dividido o triádico) gobierna TODA la obra —retícula,
 * bloques cinéticos, formas Hilma, glifos— en vez de bancos de paletas fijas conviviendo
 * sin relación entre sí.
 *
 * COMPOSICIÓN: cada mutación ancla el campo de ondas y las órbitas secundarias en uno
 * de los 4 cruces de proporción áurea del lienzo (no en el centro exacto), con 2-3
 * familias decorativas protagonistas por mutación (restraint curatorial) y muestreo
 * tipo blue-noise para las familias que se ubican al azar.
 *
 * CONTROLES:
 * [1/Q] : Mutación (nueva semilla y recomposición total)
 * [2]   : Ciclar paletas de color
 * [Y]   : Cambiar modo de onda espacial (5 modos)
 * [H]   : Toggle influencia de figuras (Hilma)
 * [K]   : Toggle motores KAL
 * [B]   : Toggle lluvia binaria
 * [P]   : Toggle partículas (nieve digital)
 * [G]   : Toggle grilla guía
 * [S]   : Guardar PNG (alta resolución)
 * [V]   : Toggle viñeteado
 * [M]   : Toggle Reloj Maestro (pausa/reanuda la evolución temporal)
 * [+/-] : Cambiar densidad de grilla (recalcula todo)
 * [Flechas] : Velocidad global
 * [Espacio] : Pausa
 */

import java.util.*;

// ============================================================
// 1. MOTOR DE COLOR ARMÓNICO (estético y funcional)
// ============================================================
// Toda la obra se tiñe a partir de UN solo acorde cromático por mutación:
// un hue base más un esquema de teoría del color clásica, generado en
// applyPatternPalette(). unifiedPalette, pairPalette, pal y accentPal son
// las cuatro "vistas" de ese mismo acorde que consume el resto del sketch;
// ninguna se elige de un banco de paletas ajeno entre sí.
color[] unifiedPalette;
color[] PALETTE;
float[] schemeHueDeg; // hues ancla del acorde activo

// Pares tinta/fondo de la retícula binaria (la mayoría de píxeles visibles
// de la pieza). Los valores de aquí abajo son solo el default de arranque;
// applyPatternPalette() los reemplaza por pares derivados de schemeHueDeg.
color[][] pairPalette = new color[][]{
  { rgb(0, 214, 198), rgb(255, 42, 161) },
  { rgb(43, 93, 255), rgb(255, 52, 90) },
  { rgb(0, 188, 255), rgb(255, 210, 0) },
  { rgb(255, 42, 161), rgb(0, 214, 198) },
  { rgb(40, 157, 77), rgb(255, 140, 0) },
  { rgb(103, 58, 183), rgb(255, 182, 193) }
};

// Reserva de "chispas" de acento: un único color de este set se elige UNA
// vez por mutación (buildAccentPalette) y se repite en toda la pieza — un
// solo punto de disonancia controlada y deliberada, no ruido de acentos.
color[] HACC = new color[]{
  rgb(46, 63, 147), rgb(255, 201, 20), rgb(225, 42, 42),
  rgb(40, 157, 77), rgb(103, 58, 183), rgb(255, 182, 193),
  rgb(255, 140, 0), rgb(255, 215, 0), rgb(192, 192, 192)
};

// Acentos activos: se reconstruyen en cada mutación a partir de `pal` +
// un único spark de HACC (formas Hilma, glifos CSym). Acentos sólidos
// (bloques M01-M08, MShape, DElem, Motion): 8 tonos claro→oscuro del mismo
// acorde. Los valores de aquí abajo son solo el default antes de componer.
color[] accentPal = HACC.clone();
color[] pal = HACC.clone();

// Peso curatorial por mutación de cada familia decorativa secundaria. En
// vez de instanciar las ~9 familias siempre a la misma densidad relativa
// —maximalismo parejo—, cada mutación elige 2-3 protagonistas y atenúa el
// resto, como haría un diseñador al decidir qué elemento lidera.
float[] sysEmphasis = new float[9];

final color BG = #FFFFFF;
int GRID = 110; // global

// ============================================================
// 2. SISTEMA DE ONDAS (el pulso del mar) + PUNTO FOCAL ÁUREO
// ============================================================
class WaveSystem {
  int mode = 0;
  float speedMultiplier = 1.0;
  float masterTime = 0;

  // Punto focal compositivo: uno de los 4 cruces de proporción áurea del
  // lienzo, recalculado en cada mutación (ver setFocal / composeAPEX).
  // Reemplaza el centro geométrico exacto como origen del campo de ondas y
  // de la profundidad, rompiendo la simetría radial tipo "mandala" por una
  // composición asimétrica con un punto de fuerza claro.
  PVector focal = new PVector();
  float focalMaxDist = 1;

  void setFocal(float fx, float fy) {
    focal.x = fx; focal.y = fy;
    focalMaxDist = max(
      max(dist(fx, fy, 0, 0), dist(fx, fy, width, 0)),
      max(dist(fx, fy, 0, height), dist(fx, fy, width, height))
    );
  }

  void update(float dt) { masterTime += dt * speedMultiplier; }

  void compute(float x, float y, float[] outScale, PVector outOffset) {
    float cx = x - focal.x;
    float cy = y - focal.y;
    float dist = sqrt(cx*cx + cy*cy);
    float maxDist = focalMaxDist;
    float normDist = constrain(dist / maxDist, 0, 1);

    float dMouse = dist(x, y, mouseX, mouseY);
    float mouseFactor = constrain(map(dMouse, 0, 350, 1.3, 0.0), 0, 1.3);

    float wave = 0;
    float radialShift = 0;
    float tangShift = 0;

    switch(mode) {
      case 0: {
        float phase = normDist * TWO_PI * 0.03 * maxDist - masterTime * 1.0;
        wave = (sin(phase) + 1.0) / 2.0;
        outScale[0] = max(0.35, 0.82 + wave * 1.0 + mouseFactor * 0.35);
        radialShift = wave * 8.0 * sin(masterTime * 1.5 + dist * 0.035) + mouseFactor * 8.0 * sin(dMouse * 0.035 - masterTime * 2.0);
        tangShift = wave * 4.5 * cos(masterTime * 1.0 + dist * 0.05);
      } break;
      case 1: {
        float diag = (x + y) * 0.0035 - masterTime * 1.5;
        wave = (sin(diag * TWO_PI) + 1.0) / 2.0;
        outScale[0] = max(0.35, 0.78 + wave * 1.1 + mouseFactor * 0.3);
        radialShift = sin(diag * 3.0) * 9.0 + mouseFactor * 7.0;
        tangShift = cos(masterTime + x * 0.007) * 8.0;
      } break;
      case 2: {
        float angle = atan2(cy, cx);
        float spiral = angle * 3.0 - masterTime * 1.3 + normDist * 3.0;
        wave = (sin(spiral) + 1.0) / 2.0;
        outScale[0] = max(0.35, 0.82 + wave * 1.0 + mouseFactor * 0.35);
        radialShift = cos(masterTime * 1.3 + normDist * 4.5) * 10.0 + mouseFactor * 8.0 * cos(dMouse * 0.03);
        tangShift = sin(angle * 3.0 - masterTime) * 8.0;
      } break;
      case 3: {
        float block = floor(x / 120) * 0.35 + floor(y / 120) * 0.35 - masterTime * 2.0;
        wave = abs(sin(block));
        outScale[0] = max(0.35, 0.85 + wave * 0.9 + mouseFactor * 0.3);
        radialShift = (wave - 0.5) * 10.0 + mouseFactor * 6.0;
        tangShift = sin(masterTime * 1.8 + y * 0.012) * 8.0;
      } break;
      case 4: {
        float noiseVal = noise(x * 0.002, y * 0.002, masterTime * 0.3);
        wave = noiseVal;
        outScale[0] = max(0.35, 0.8 + noiseVal * 1.1 + mouseFactor * 0.35);
        radialShift = (noiseVal - 0.5) * 12.0 + mouseFactor * 8.0;
        tangShift = cos(masterTime + noiseVal * 7.0) * 9.0;
      } break;
    }

    outOffset.x = cos(atan2(cy, cx)) * radialShift + sin(atan2(cy, cx)) * tangShift + (mouseX - width/2) * mouseFactor * 0.05;
    outOffset.y = sin(atan2(cy, cx)) * radialShift - cos(atan2(cy, cx)) * tangShift + (mouseY - height/2) * mouseFactor * 0.05;
  }

  PVector flow(float x, float y) {
    float cx = x - focal.x;
    float cy = y - focal.y;
    float r = sqrt(cx*cx + cy*cy);
    float ang = atan2(cy, cx);
    float speedMod = 1.0 + mode * 0.12;
    float waveAngle = ang + HALF_PI + sin(r * 0.015 - masterTime * 0.8 * speedMod) * 0.9 + cos(ang * 2.2 + masterTime * 0.6) * 0.5;
    float speed = (0.25 + 0.18 * sin(r * 0.01 - masterTime * 0.6)) * speedMod;
    return new PVector(cos(waveAngle) * speed, sin(waveAngle) * speed);
  }
}

// ============================================================
// 3. MOTOR HILMA (figuras ameba, con influencia)
// ============================================================
class HilmaEngine {
  final int MAX_FORMS = 10;
  int formCount = 8;
  int[] fType = new int[MAX_FORMS];
  float[] fX = new float[MAX_FORMS];
  float[] fY = new float[MAX_FORMS];
  float[] fS = new float[MAX_FORMS];
  float[] fRot = new float[MAX_FORMS];
  float[] fTh = new float[MAX_FORMS];
  float[] fK = new float[MAX_FORMS];
  color[] fCol = new color[MAX_FORMS];

  final int FCIRCLE = 0, FROSE = 1, FSPIRAL = 2, FBOX = 3, FVESICA = 4, FTRI = 5, FTEMPLE = 6, FCROSS = 7;
  long seed;

  HilmaEngine(long s) { seed = s; build(); }

  void build() {
    randomSeed(seed * 17 + 9);
    formCount = 7 + (int)random(2);
    for (int i = 0; i < formCount; i++) {
      fType[i] = (int)random(8);
      fS[i] = random(width * 0.10, width * 0.18);
      float gx = (int)random(3, GRID - 3);
      float gy = (int)random(3, GRID - 3);
      fX[i] = (gx + 0.5) * (width / float(GRID));
      fY[i] = (gy + 0.5) * (height / float(GRID));
      fRot[i] = random(TWO_PI);
      fTh[i] = random(0.03, 0.05);
      fK[i] = random(5, 10);
      fCol[i] = accentPal[(int)random(accentPal.length)];
    }
  }

  class HilmaHit {
    float edge=0, inside=0, influence=0;
    color col=0;
    int id=-1;
    float theta=0, r=0, k=6, tangent=0;
    float flowX=0, flowY=0;
  }

  HilmaHit check(float x, float y, float time) {
    HilmaHit out = new HilmaHit();
    float totalInfl = 0;
    float fx=0, fy=0;
    for (int i = 0; i < formCount; i++) {
      float dx = x - fX[i], dy = y - fY[i];
      float cr = cos(-fRot[i]), sr = sin(-fRot[i]);
      float lx = (dx*cr - dy*sr) / fS[i];
      float ly = (dx*sr + dy*cr) / fS[i];
      float rr = sqrt(lx*lx + ly*ly);
      float th = atan2(ly, lx);
      float dEdge = 999;
      boolean inside = false;
      float tangent = th + HALF_PI;
      float k = fK[i];
      int tp = fType[i];

      if (tp == FCIRCLE) { dEdge = abs(rr - 1.0); inside = (rr <= 1.0); }
      else if (tp == FROSE) { float target = 0.82 + 0.18 * sin(k * th); dEdge = abs(rr - target); inside = (rr <= target); tangent = th + HALF_PI; }
      else if (tp == FSPIRAL) { float th01 = (th < 0) ? (th + TWO_PI) : th; float target = 0.18 + 0.14 * th01; dEdge = abs(rr - target); inside = (rr <= target + 0.12); tangent = th + HALF_PI; k = 9.0; }
      else if (tp == FBOX) { float sdf = sdBox(lx, ly, 0.78, 0.55); dEdge = abs(sdf); inside = (sdf <= 0); tangent = th + HALF_PI; k = 5.0; }
      else if (tp == FVESICA) { float off = 0.36; float d1 = sqrt((lx+off)*(lx+off) + ly*ly); float d2 = sqrt((lx-off)*(lx-off) + ly*ly); inside = (d1 <= 0.78 && d2 <= 0.78); dEdge = min(abs(d1 - 0.78), abs(d2 - 0.78)); tangent = th + HALF_PI; k = 7.0; }
      else if (tp == FTRI) { dEdge = distToTri(lx, ly); inside = pointInTri(lx, ly); tangent = th + HALF_PI; k = 6.0; }
      else if (tp == FTEMPLE) { float rectS = abs(sdBox(lx, ly+0.10, 0.78, 0.42)); float arcD = abs(sdArc(lx, ly-0.12, 0.86, 0.56)); dEdge = min(rectS, arcD); inside = (sdBox(lx, ly+0.10, 0.78, 0.42) <= 0) || (insideArc(lx, ly-0.12, 0.86, 0.56)); tangent = th + HALF_PI; k = 8.0; }
      else if (tp == FCROSS) { float aW = 0.18, aL = 0.86; float dA = abs(sdBox(lx, ly, aL, aW)); float dB = abs(sdBox(lx, ly, aW, aL)); dEdge = min(dA, dB); inside = (sdBox(lx, ly, aL, aW) <= 0) || (sdBox(lx, ly, aW, aL) <= 0); tangent = th + HALF_PI; k = 4.0; }

      float thick = fTh[i];
      float edge = 1.0 - smoothstep(thick, thick * 2.2, dEdge);
      float ins = inside ? (0.2 + 0.7 * (1.0 - smoothstep(0.20, 0.85, rr))) : 0.0;
      float infl = max(edge * 1.5, ins * 0.9);

      if (infl > totalInfl) {
        totalInfl = infl;
        out.edge = edge;
        out.inside = ins;
        out.influence = infl;
        out.col = fCol[i];
        out.id = i;
        out.theta = th;
        out.r = rr;
        out.k = k;
        out.tangent = tangent;
        float rad = dist(x, y, fX[i], fY[i]);
        float angFig = atan2(y - fY[i], x - fX[i]);
        float flowMag = 0.2 + 0.5 * edge * sin(time * 1.5 + rad * 0.05);
        fx = cos(angFig + HALF_PI) * flowMag - sin(angFig + HALF_PI) * 0.3 * sin(time + rad * 0.1);
        fy = sin(angFig + HALF_PI) * flowMag + cos(angFig + HALF_PI) * 0.3 * sin(time + rad * 0.1);
        out.flowX = fx;
        out.flowY = fy;
      }
    }
    return out;
  }

  // Funciones de distancia (SDF)
  float smoothstep(float e0, float e1, float x) { float t = constrain((x - e0) / (e1 - e0), 0, 1); return t*t*(3-2*t); }
  float sdBox(float x, float y, float bx, float by) { float dx = abs(x) - bx; float dy = abs(y) - by; return sqrt(max(dx,0)*max(dx,0) + max(dy,0)*max(dy,0)) + min(max(dx, dy), 0); }
  float sdArc(float x, float y, float w, float h) { float rx = w*0.5, ry = h*0.5; return abs(sqrt((x*x)/(rx*rx) + (y*y)/(ry*ry)) - 1.0); }
  boolean insideArc(float x, float y, float w, float h) { float rx = w*0.5, ry = h*0.5; return (sqrt((x*x)/(rx*rx) + (y*y)/(ry*ry)) <= 1.0 && y <= 0.05); }
  boolean pointInTri(float x, float y) {
    float ax=-0.85, ay=0.65, bx=0.85, by=0.65, cx=0.0, cy=-0.95;
    float v0x = cx-ax, v0y = cy-ay, v1x = bx-ax, v1y = by-ay, v2x = x-ax, v2y = y-ay;
    float dot00 = v0x*v0x + v0y*v0y, dot01 = v0x*v1x + v0y*v1y, dot11 = v1x*v1x + v1y*v1y;
    float den = dot00 * dot11 - dot01 * dot01;
    if (abs(den) < 0.0001) return false;
    float invDen = 1.0 / den;
    float u = (dot11 * (v0x*v2x + v0y*v2y) - dot01 * (v1x*v2x + v1y*v2y)) * invDen;
    float v = (dot00 * (v1x*v2x + v1y*v2y) - dot01 * (v0x*v2x + v0y*v2y)) * invDen;
    return (u >= 0) && (v >= 0) && (u + v <= 1);
  }
  float distPointSeg(float px, float py, float ax, float ay, float bx, float by) {
    float vx = bx-ax, vy = by-ay;
    float wx = px-ax, wy = py-ay;
    float c1 = vx*wx + vy*wy;
    if (c1 <= 0) return dist(px, py, ax, ay);
    float c2 = vx*vx + vy*vy;
    if (c2 == 0) return dist(px, py, ax, ay);
    if (c2 <= c1) return dist(px, py, bx, by);
    float t = c1 / c2;
    return dist(px, py, ax + t*vx, ay + t*vy);
  }
  float distToTri(float x, float y) {
    return min(distPointSeg(x, y, -0.85, 0.65, 0.85, 0.65),
               min(distPointSeg(x, y, 0.85, 0.65, 0.0, -0.95),
                   distPointSeg(x, y, 0.0, -0.95, -0.85, 0.65)));
  }
}

// ============================================================
// 4. GESTOR DE RETÍCULA (CACHE + INFLUENCIA)
// ============================================================
class GridManager {
  float cellW, cellH;
  PFont font;

  char[][] bits;
  float[][] baseRots;
  color[][] inks;
  float[][] influenceMap;
  float[][] flowXMap, flowYMap;
  float[][] depthMap;
  HilmaEngine.HilmaHit[][] hitMap; // cache del hit-test Hilma: evita repetir check() dos veces por celda

  boolean hilmaActive = true;
  WaveSystem wave;
  HilmaEngine hilma;

  GridManager(WaveSystem w, HilmaEngine h) {
    wave = w; hilma = h;
    allocateMaps();
    recomputeGrid();
    refreshCache();
  }

  void allocateMaps() {
    bits = new char[GRID][GRID];
    baseRots = new float[GRID][GRID];
    inks = new color[GRID][GRID];
    influenceMap = new float[GRID][GRID];
    flowXMap = new float[GRID][GRID];
    flowYMap = new float[GRID][GRID];
    depthMap = new float[GRID][GRID];
    hitMap = new HilmaEngine.HilmaHit[GRID][GRID];
  }

  void recomputeGrid() {
    cellW = width / float(GRID); cellH = height / float(GRID);
    float target = min(cellW, cellH) * 1.45;
    int fs = (int)constrain(target, 10, 24);
    font = createFont("Courier", fs, true);
    textFont(font); textAlign(CENTER, CENTER);
  }

  void refreshCache() {
    // 1. Calcular influencia y flujo de las figuras (una sola vez por celda;
    // el hit-test se cachea en hitMap para que el paso 2 no lo repita).
    for (int gy = 0; gy < GRID; gy++) {
      for (int gx = 0; gx < GRID; gx++) {
        float cx = gx * cellW + cellW * 0.5;
        float cy = gy * cellH + cellH * 0.5;
        HilmaEngine.HilmaHit hit = null;
        float infl = 0, fx = 0, fy = 0;
        if (hilmaActive) {
          hit = hilma.check(cx, cy, wave.masterTime);
          infl = hit.influence;
          fx = hit.flowX;
          fy = hit.flowY;
        }
        hitMap[gy][gx] = hit;
        influenceMap[gy][gx] = constrain(infl, 0, 1);
        flowXMap[gy][gx] = fx;
        flowYMap[gy][gx] = fy;
        // profundidad (foco áureo → borde)
        float cx2 = cx - wave.focal.x;
        float cy2 = cy - wave.focal.y;
        depthMap[gy][gx] = constrain(sqrt(cx2*cx2 + cy2*cy2) / (width/1.5), 0, 1);
      }
    }

    // 2. Generar bits, rotaciones y colores con influencia
    for (int gy = 0; gy < GRID; gy++) {
      for (int gx = 0; gx < GRID; gx++) {
        float cx = gx * cellW + cellW * 0.5;
        float cy = gy * cellH + cellH * 0.5;
        float infl = influenceMap[gy][gx];

        int bi = constrain((int)(cx / (width / float(BLOCKS))), 0, BLOCKS-1);
        int bj = constrain((int)(cy / (height/ float(BLOCKS))), 0, BLOCKS-1);

        float ang  = bAng[bi][bj];
        float freq = bFreq[bi][bj];
        float bias = bBias[bi][bj];
        int   palI = bPal[bi][bj];

        color c0 = pairPalette[palI][0];
        color c1 = pairPalette[palI][1];

        // Modificar frecuencia y bias según influencia
        float freqMod = freq * (1.0 + 0.3 * (1.0 - infl));
        float biasMod = bias + 0.2 * infl;

        float ca = cos(ang), sa = sin(ang);
        float u = (cx*ca + cy*sa) * freqMod + bP1[bi][bj];
        float v = (-cx*sa + cy*ca) * (freqMod*1.15) + bP2[bi][bj];

        float base = 0.92 * sin(u + 0.65) + 0.62 * sin(v - 0.42) + 0.82 * (noise(u*0.1, v*0.1, 0.4) - 0.5);
        base += biasMod;
        bits[gy][gx] = (base > 0) ? '1' : '0';
        inks[gy][gx] = (bits[gy][gx] == '0') ? c0 : c1;

        float rot = ang + (noise(u*0.06, v*0.06, 0.5) - 0.5) * 0.85 + infl * 0.3 * sin(gy*0.1 + gx*0.1 + wave.masterTime);
        baseRots[gy][gx] = rot;

        // Mezcla con color de figura si hay influencia (reutiliza hitMap, sin recalcular)
        if (infl > 0.01) {
          HilmaEngine.HilmaHit hit = hitMap[gy][gx];
          if (hit.edge > 0.001 || hit.inside > 0.001) {
            float mixAmt = constrain(0.22 + 0.58 * hit.edge + 0.18 * hit.inside, 0, 0.90);
            inks[gy][gx] = lerpCol(inks[gy][gx], hit.col, mixAmt);
            if (hit.edge > 0.16) bits[gy][gx] = (((gx + gy + hit.id) & 1) == 0) ? '1' : '0';
            else if (hit.inside > 0.18) { float p = sin(hit.theta * hit.k + hit.r * 5.0 + 0.55); bits[gy][gx] = (p > 0) ? '1' : '0'; }
            float aL = 0.2 + 0.48 * hit.edge + 0.18 * hit.inside;
            baseRots[gy][gx] = lerpAngle(baseRots[gy][gx], hit.tangent, constrain(aL, 0, 0.85));
          }
        }
      }
    }
  }

  void display() {
    for (int gy = 0; gy < GRID; gy++) {
      for (int gx = 0; gx < GRID; gx++) {
        float cx = gx * cellW + cellW * 0.5;
        float cy = gy * cellH + cellH * 0.5;

        float[] scaleArr = new float[1];
        PVector offset = new PVector();
        wave.compute(cx, cy, scaleArr, offset);

        float rot = baseRots[gy][gx];
        char bit = bits[gy][gx];
        color ink = inks[gy][gx];

        float infl = influenceMap[gy][gx];
        float depth = depthMap[gy][gx];
        float pushX = infl * 10.0 * flowXMap[gy][gx];
        float pushY = infl * 10.0 * flowYMap[gy][gx];

        float jx = (noise(gx*0.13, gy*0.13, wave.masterTime*0.7) - 0.5) * 0.6 + pushX * 0.5;
        float jy = (noise(100+gx*0.13, 200+gy*0.13, wave.masterTime*0.7) - 0.5) * 0.6 + pushY * 0.5;

        float sizeFactor = map(depth, 0, 1, 1.5, 0.6);
        float ts = min(cellW, cellH) * 1.38 * scaleArr[0] * sizeFactor * (1.0 + 0.15 * infl);
        float alpha = 100 * (0.6 + 0.4 * (1.0 - depth)) * (0.8 + 0.2 * infl);
        color inkAlpha = color(red(ink), green(ink), blue(ink), alpha);

        pushMatrix();
        translate(cx + jx + offset.x, cy + jy + offset.y);
        rotate(rot);

        textFont(font);
        textSize(max(6, ts));
        textAlign(CENTER, CENTER);

        // Sombras que dan profundidad
        fill(0, 8 + 6 * (1.0 - depth) + 4 * infl);
        text(bit, -0.8, 0.8); text(bit, 0.8, -0.8); text(bit, -0.8, -0.8); text(bit, 0.8, 0.8);
        fill(0, 4 + 3 * (1.0 - depth));
        text(bit, -1.5, 0); text(bit, 1.5, 0); text(bit, 0, -1.5); text(bit, 0, 1.5);

        fill(inkAlpha);
        text(bit, 0, 0);
        popMatrix();
      }
    }
  }

  void resize(int newGrid) {
    GRID = constrain(newGrid, 60, 140);
    allocateMaps();
    recomputeGrid();
    refreshCache();
  }

  void toggleHilma() { hilmaActive = !hilmaActive; refreshCache(); }
}

// ============================================================
// 5. CAPA DE PARTÍCULAS (nieve digital, etérea)
// ============================================================
ArrayList<Particle> particles;
boolean showParticles = true;

class Particle {
  float x, y, vx, vy, size;
  color col;
  float alpha, phase;
  Particle() {
    x = random(width);
    y = random(height);
    vx = random(-0.3, 0.3);
    vy = random(-0.5, 0.2);
    size = random(1, 4);
    col = color(random(200, 255), random(200, 255), random(200, 255));
    alpha = random(80, 180);
    phase = random(TWO_PI);
  }
  void update() {
    x += vx * speedMultiplier;
    y += vy * speedMultiplier;
    PVector f = waveSys.flow(x, y);
    x += f.x * 0.2 * speedMultiplier;
    y += f.y * 0.2 * speedMultiplier;
    if (x < 0) x = width;
    if (x > width) x = 0;
    if (y < 0) y = height;
    if (y > height) y = 0;
    alpha = 100 + 80 * sin(waveSys.masterTime * 0.5 + phase);
  }
  void display() {
    noStroke();
    fill(col, alpha * 0.6);
    ellipse(x, y, size, size);
    fill(col, alpha * 0.2);
    ellipse(x, y, size * 3, size * 3);
  }
}

// ============================================================
// 6. VARIABLES GLOBALES
// ============================================================
WaveSystem waveSys;
HilmaEngine hilmaEng;
GridManager gridMgr;

final int BLOCKS = 11;
float[][] bAng = new float[BLOCKS][BLOCKS];
float[][] bFreq = new float[BLOCKS][BLOCKS];
float[][] bBias = new float[BLOCKS][BLOCKS];
int[][]   bPal  = new int[BLOCKS][BLOCKS];
float[][] bP1   = new float[BLOCKS][BLOCKS];
float[][] bP2   = new float[BLOCKS][BLOCKS];

// Listas de elementos cinéticos
ArrayList<Objct> objs;
ArrayList<MShape> mShapes;
ArrayList<DElem> dElems;
ArrayList<MKMotion> mkMotions;
ArrayList<Motion> motions;
ArrayList<Flower> flowers;
ArrayList<Connector> connectors;
ArrayList<CharacterSymbol> symbols;
ArrayList<BinaryRain> binaryRains;
ArrayList<VibrantShape> vibrantShapes;
ArrayList<ComplexGeometry> complexGeo;
ArrayList<OrbitingElement> orbiters;
ArrayList<OkazzFlower> okazzFlowers;
ArrayList<OkazzTrailShape> okazzTrails;
ArrayList<TextGhostTrail> textGhostTrails;
ArrayList<CSym> cSyms;
ArrayList<PVector> occupied; // puntos ya ocupados esta mutación (ver spreadPoint)

PImage noiseFilter;
PGraphics grain;
PGraphics vignette;
PGraphics glowLayer;

boolean MOTION = true;
boolean showKM = true;
boolean showBR = true;
boolean showGrid = false;
boolean paused = false;
float densityFactor = 0.26;
boolean vividMode = true;
boolean glowMode = false;
float speedMultiplier = 1.0;
float gSpd = 1.6;
int SEED = 12345;
int seedValue = 1337;
int compositionMode = 0;
boolean vignetteOn = true;

final int A_SOLID = 175;
final int A_TEXT = 150;
final float BORDER_WIDTH = 40;

int patternIndex = 0;

// ============================================================
// 7. SETUP Y DRAW (orquestación de capas)
// ============================================================
void settings() { size(1080, 1080, P2D); smooth(8); }

void setup() {
  colorMode(HSB, 360, 100, 100);
  rectMode(CENTER); ellipseMode(CENTER);
  frameRate(30);
  strokeCap(ROUND); strokeJoin(ROUND);
  textAlign(CENTER, CENTER);

  waveSys = new WaveSystem();
  waveSys.setFocal(width/2.0, height/2.0); // default sano hasta la primera composeAPEX()

  randomSeed(SEED); noiseSeed(SEED);
  applyPatternPalette();
  buildAccentPalette();
  buildBlocks(); // pairPalette y bAng deben existir ANTES de construir Hilma/GridManager

  hilmaEng = new HilmaEngine(SEED);
  gridMgr = new GridManager(waveSys, hilmaEng);

  // Inicializar listas
  objs = new ArrayList<Objct>(50);
  mShapes = new ArrayList<MShape>(20);
  dElems = new ArrayList<DElem>(40);
  mkMotions = new ArrayList<MKMotion>(30);
  motions = new ArrayList<Motion>(30);
  flowers = new ArrayList<Flower>(30);
  connectors = new ArrayList<Connector>(30);
  symbols = new ArrayList<CharacterSymbol>(50);
  binaryRains = new ArrayList<BinaryRain>(20);
  vibrantShapes = new ArrayList<VibrantShape>(30);
  complexGeo = new ArrayList<ComplexGeometry>(30);
  orbiters = new ArrayList<OrbitingElement>(20);
  okazzFlowers = new ArrayList<OkazzFlower>(30);
  okazzTrails = new ArrayList<OkazzTrailShape>(20);
  textGhostTrails = new ArrayList<TextGhostTrail>(50);
  cSyms = new ArrayList<CSym>(50);
  occupied = new ArrayList<PVector>();

  // Partículas
  particles = new ArrayList<Particle>();
  for (int i = 0; i < 400; i++) particles.add(new Particle());

  buildGrain();
  buildVignette();
  buildGlowLayer();
  noiseFilter = createNoiseFilter();

  initKineticMotifs();
  composeAPEX();
}

void draw() {
  background(BG);
  if (!paused && MOTION) waveSys.update(0.006);

  // Capa 1: grano de fondo
  if (grain != null) { tint(255, 60); image(grain, 0, 0); noTint(); }

  // Capa 2: mar de números (retícula)
  gridMgr.display();

  // Capa 3: elementos cinéticos de fondo
  if (showBR && binaryRains != null) for (BinaryRain br : binaryRains) br.run();
  if (connectors != null) for (Connector c : connectors) c.run();
  if (showKM) runKineticMotifs();
  if (flowers != null) for (Flower f : flowers) f.run();
  if (okazzFlowers != null) for (OkazzFlower of : okazzFlowers) of.run();
  if (okazzTrails != null) for (OkazzTrailShape ot : okazzTrails) ot.run();

  // Capa 4: formas brillantes (modo mezcla)
  if (glowMode) blendMode(SCREEN); else blendMode(BLEND);
  if (complexGeo != null) for (ComplexGeometry cg : complexGeo) if (cg.layerDepth <= 1) cg.run();
  if (orbiters != null) for (OrbitingElement oe : orbiters) oe.run();
  if (vibrantShapes != null) for (VibrantShape vs : vibrantShapes) vs.run();
  blendMode(BLEND);

  // Capa 5: motores y formas de relleno
  if (motions != null) for (Motion m : motions) m.run();
  dDBG();
  if (objs != null) for (Objct o : objs) o.run();
  if (mkMotions != null) for (MKMotion m : mkMotions) m.run();
  if (mShapes != null) for (MShape m : mShapes) m.display();
  if (complexGeo != null) for (ComplexGeometry cg : complexGeo) if (cg.layerDepth == 2) cg.run();
  dDFG();

  // Capa 6: fantasmas de texto y símbolos
  if (textGhostTrails != null) {
    for (int i = textGhostTrails.size() - 1; i >= 0; i--) {
      TextGhostTrail tgt = textGhostTrails.get(i);
      tgt.run();
      if (tgt.isDead()) textGhostTrails.remove(i);
    }
  }
  if (symbols != null) for (CharacterSymbol s : symbols) s.run();
  if (cSyms != null) for (CSym cs : cSyms) cs.run();

  // Capa 7: partículas (nieve digital) sobre todo
  if (showParticles && particles != null) {
    blendMode(ADD);
    for (Particle p : particles) { p.update(); p.display(); }
    blendMode(BLEND);
  }

  // Capa 8: brillo difuso
  if (glowLayer != null) { tint(255, 30); image(glowLayer, 0, 0); noTint(); }

  // Capa 9: viñeteado y filtro de ruido
  if (showGrid) drawGuideGrid();
  if (vignetteOn && vignette != null) image(vignette, 0, 0);
  image(noiseFilter, 0, 0);

  displayInfo();
}

// ============================================================
// 8. FUNCIONES DE CONSTRUCCIÓN (bloques, grano, viñeteado)
// ============================================================
void buildBlocks() {
  randomSeed(SEED);
  for (int i = 0; i < BLOCKS; i++) for (int j = 0; j < BLOCKS; j++) {
    bAng[i][j] = random(-PI, PI);
    bFreq[i][j] = random(0.016, 0.032);
    bBias[i][j] = random(-0.35, 0.35);
    bPal[i][j] = (int)random(pairPalette.length);
    bP1[i][j] = random(1000);
    bP2[i][j] = random(1000);
  }
}

void buildGrain() {
  grain = createGraphics(width, height);
  grain.beginDraw();
  grain.clear();
  grain.noStroke();
  randomSeed(SEED * 7 + 13);
  for (int i = 0; i < 4500; i++) {
    float x = random(width), y = random(height);
    float a = random(TWO_PI), len = random(6, 22), w = random(0.5, 1.3);
    int al = (int)random(3, 10);
    grain.fill(0, al);
    grain.pushMatrix(); grain.translate(x, y); grain.rotate(a);
    grain.rectMode(CENTER); grain.rect(0, 0, len, w);
    grain.popMatrix();
  }
  for (int i = 0; i < 12000; i++) {
    grain.fill(0, (int)random(2, 7));
    grain.ellipse(random(width), random(height), random(0.5, 1.3), random(0.5, 1.3));
  }
  grain.endDraw();
}

void buildVignette() {
  vignette = createGraphics(width, height);
  vignette.beginDraw();
  vignette.clear();
  vignette.noStroke();
  for (int i = 0; i < 6000; i++) {
    float x = random(width), y = random(height);
    float cx = width/2, cy = height/2;
    float d = dist(x, y, cx, cy);
    float alpha = map(d, 0, 700, 0, 55);
    vignette.fill(0, alpha);
    vignette.ellipse(x, y, 4, 4);
  }
  vignette.endDraw();
}

void buildGlowLayer() {
  glowLayer = createGraphics(width, height);
  glowLayer.beginDraw();
  glowLayer.clear();
  glowLayer.noStroke();
  for (int i = 0; i < 30; i++) {
    float x = random(width);
    float y = random(height);
    float r = random(80, 250);
    float alpha = random(10, 40);
    glowLayer.fill(255, alpha);
    glowLayer.ellipse(x, y, r, r);
    glowLayer.fill(200, 200, 255, alpha * 0.5);
    glowLayer.ellipse(x + random(-50, 50), y + random(-50, 50), r * 1.5, r * 1.5);
  }
  glowLayer.endDraw();
}

PImage createNoiseFilter() {
  PImage img = createImage(width, height, ARGB);
  img.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) img.pixels[i] = color(random(255), random(255), random(255), 4);
  img.updatePixels();
  return img;
}

// ============================================================
// 9. COMPOSICIÓN APEX (generación de todos los elementos)
// ============================================================
void composeAPEX() {
  long activeSeed = (long)seedValue + patternIndex * 99991L + compositionMode * 333333L;
  randomSeed(activeSeed); noiseSeed(activeSeed);
  applyPatternPalette();
  buildAccentPalette();
  buildEmphasis();

  // Punto focal áureo: uno de los 4 cruces de proporción áurea (~0.382 /
  // ~0.618 del lienzo) en vez del centro exacto.
  final float GR = 0.382;
  waveSys.setFocal(width * (random(1) < 0.5 ? GR : 1 - GR), height * (random(1) < 0.5 ? GR : 1 - GR));

  objs.clear(); mShapes.clear(); dElems.clear(); mkMotions.clear();
  motions.clear(); flowers.clear(); connectors.clear(); symbols.clear();
  binaryRains.clear(); vibrantShapes.clear(); complexGeo.clear();
  orbiters.clear(); okazzFlowers.clear(); okazzTrails.clear();
  textGhostTrails.clear(); cSyms.clear(); occupied.clear();

  buildMG(); buildMS(); buildDE(); buildMK();

  float d = densityFactor;
  PVector focal = waveSys.focal;

  int cellCount = max(2, int(2.2 * d));
  for (int i = 0; i < cellCount; i++) for (int j = 0; j < cellCount; j++) {
    if (random(1) < 0.38) {
      float tVal = (i + j + 1.0) / (cellCount * 1.5);
      float angle = TWO_PI * tVal * 1.618 + 0.15;
      float radius = width * 0.3 * tVal;
      float mx = focal.x + cos(angle)*radius, my = focal.y + sin(angle)*radius;
      motions.add(new Motion(mx, my, max(20, 44 * random(0.8, 1.2)), pal[0], pal[1], (i+j)%13, ((i+j)%2==0)?1:-1));
      occupied.add(new PVector(mx, my));
    }
  }

  // vibrantShapes reparte su ángulo de forma pareja (2π/n) — ya está bien
  // distribuido por construcción; solo se registra para las que muestrean
  // al azar más abajo.
  int vibrantCount = round(4 * d * sysEmphasis[0]);
  for (int i = 0; i < vibrantCount; i++) {
    float angle = TWO_PI / vibrantCount * i;
    float radius = random(width * 0.15, width * 0.32);
    float vx = focal.x + cos(angle)*radius, vy = focal.y + sin(angle)*radius;
    vibrantShapes.add(new VibrantShape(vx, vy, random(28, 50)));
    occupied.add(new PVector(vx, vy));
  }

  // okazzFlowers usa ángulo puramente al azar — propenso a amontonarse por
  // pura probabilidad, así que se ubica con spreadPoint (blue-noise).
  int okazzFlowerCount = round(3 * d * sysEmphasis[1]);
  for (int i = 0; i < okazzFlowerCount; i++) {
    PVector p = spreadPoint(focal.x, focal.y, width * 0.16, width * 0.3, 40);
    okazzFlowers.add(new OkazzFlower(p.x, p.y, random(22, 45)));
  }

  int trailCount = round(2 * d * sysEmphasis[8]);
  for (int i = 0; i < trailCount; i++) {
    okazzTrails.add(new OkazzTrailShape(random(width * 0.3, width * 0.7), random(height * 0.3, height * 0.7),
                                        random(28, 50), paletteColor(i * 31)));
  }

  int geoCount = round(3 * d * sysEmphasis[2]);
  for (int i = 0; i < geoCount; i++) {
    PVector p = spreadPoint(focal.x, focal.y, width * 0.15, width * 0.35, 48);
    complexGeo.add(new ComplexGeometry(p.x, p.y, random(32, 60), i%3));
  }

  // Ancla focal: una única pieza a mayor escala, exactamente en el punto
  // focal. Le da a la composición un centro de gravedad claro en vez de
  // una textura uniforme sin jerarquía.
  complexGeo.add(new ComplexGeometry(focal.x, focal.y, width * 0.14, 2));
  occupied.add(new PVector(focal.x, focal.y));

  // orbiters reparte su ángulo de forma pareja (2π/n) — ya está bien
  // distribuido por construcción; solo se registra para las que siguen.
  int orbitCount = round(2 * d * sysEmphasis[3]);
  for (int i = 0; i < orbitCount; i++) {
    float angle = TWO_PI / orbitCount * i;
    float ox = focal.x + cos(angle)*width*0.23, oy = focal.y + sin(angle)*width*0.23;
    orbiters.add(new OrbitingElement(ox, oy, random(28, 44)));
    occupied.add(new PVector(ox, oy));
  }

  // flowers usa ángulo puramente al azar — spreadPoint evita que se
  // amontonen entre sí o sobre lo que ya ocupan las familias anteriores.
  int flowerCount = round(3 * d * sysEmphasis[4]);
  for (int i = 0; i < flowerCount; i++) {
    PVector p = spreadPoint(focal.x, focal.y, 0, width * 0.2, 22);
    flowers.add(new Flower(p.x, p.y, random(14, 22), int(random(6, 9))));
  }

  int connectorCount = round(3 * d * sysEmphasis[5]);
  for (int i = 0; i < connectorCount; i++) {
    connectors.add(new Connector(random(width * 0.25, width * 0.75), random(height * 0.25, height * 0.75), random(10, 22)));
  }

  int rainCount = round(2 * d * sysEmphasis[6]);
  for (int i = 0; i < rainCount; i++) {
    binaryRains.add(new BinaryRain(width * 0.35 + (width * 0.3) * (i / max(1.0, (float)(rainCount - 1)))));
  }

  int cSymCount = round(5 * d * sysEmphasis[7]);
  for (int i = 0; i < cSymCount; i++) {
    cSyms.add(new CSym(random(width*0.25, width*0.75), random(height*0.25, height*0.75),
                       random(1)<0.65 ? (random(1)<0.5?'0':'1') : '#'));
  }

  // Reconstruir partículas con nuevos colores
  particles.clear();
  for (int i = 0; i < 400; i++) particles.add(new Particle());

  gridMgr.refreshCache();
}

// Elige un índice de hue 0..n-1 con un reparto 60/25/10/5 (dominante /
// secundario / terciario / cuarto) en vez de uniforme — el "60-30-10" que
// usa cualquier colorista para que un esquema de varios hues no se sienta
// repartido en partes iguales, sino con una voz dominante clara.
int pickHueIdx(Random r, int n) {
  if (n <= 1) return 0;
  float[] w = (n == 2) ? new float[]{0.65, 0.35}
            : (n == 3) ? new float[]{0.55, 0.28, 0.17}
                       : new float[]{0.5, 0.24, 0.16, 0.10};
  float roll = r.nextFloat();
  float acc = 0;
  for (int i = 0; i < min(n, w.length); i++) {
    acc += w[i];
    if (roll <= acc) return i;
  }
  return min(n, w.length) - 1;
}

void applyPatternPalette() {
  long colorSeed = (long)seedValue * 15485863L + patternIndex * 73856093L + compositionMode * 19349663L;
  Random colorRand = new Random(colorSeed);

  // 1. El acorde: un hue base y un esquema de teoría del color clásica.
  float h0 = colorRand.nextFloat() * 360.0;
  int scheme = colorRand.nextInt(5);
  float[] offsets;
  switch (scheme) {
    case 0:  offsets = new float[]{0};             break; // monocromático
    case 1:  offsets = new float[]{0, -30, 30};    break; // análogo
    case 2:  offsets = new float[]{0, 180};        break; // complementario
    case 3:  offsets = new float[]{0, 150, 210};   break; // complementario dividido
    default: offsets = new float[]{0, 120, 240};   break; // triádico
  }
  schemeHueDeg = new float[offsets.length];
  for (int i = 0; i < offsets.length; i++) schemeHueDeg[i] = (h0 + offsets[i] + 360) % 360;

  // 2. unifiedPalette: 256 tonos con estructura tonal real (tinta / papel /
  // cuerpo) en vez de saturación y brillo uniformemente aleatorios.
  unifiedPalette = new color[256];
  for (int i = 0; i < 256; i++) {
    float h = (schemeHueDeg[pickHueIdx(colorRand, schemeHueDeg.length)] + (colorRand.nextFloat() - 0.5) * 14 + 360) % 360;
    float roleRoll = colorRand.nextFloat();
    float s, b;
    if (roleRoll < 0.08) {                                 // tinta: oscura y saturada, ~8%
      s = 55 + colorRand.nextFloat() * 30;
      b = 14 + colorRand.nextFloat() * 16;
    } else if (roleRoll < 0.18) {                          // papel: casi neutra y clara, ~10%
      s = colorRand.nextFloat() * 10;
      b = 90 + colorRand.nextFloat() * 8;
    } else {                                                // cuerpo: el grueso tonal, ~82%
      s = 45 + colorRand.nextFloat() * 40;
      b = 45 + colorRand.nextFloat() * 40;
    }
    unifiedPalette[i] = color(h, s, b);
  }
  PALETTE = unifiedPalette.clone();

  // 3. pairPalette: los pares tinta/fondo de la retícula binaria, que
  // domina la mayoría de píxeles visibles de la pieza.
  pairPalette = new color[6][2];
  for (int i = 0; i < pairPalette.length; i++) {
    float hueA = schemeHueDeg[pickHueIdx(colorRand, schemeHueDeg.length)];
    float hueB = schemeHueDeg[pickHueIdx(colorRand, schemeHueDeg.length)];
    if (colorRand.nextFloat() < 0.55) {
      pairPalette[i][0] = color(hueA, 18 + colorRand.nextFloat() * 18, 88 + colorRand.nextFloat() * 8);
      pairPalette[i][1] = color(hueB, 55 + colorRand.nextFloat() * 30, 16 + colorRand.nextFloat() * 18);
    } else {
      pairPalette[i][0] = color(hueA, 55 + colorRand.nextFloat() * 30, 45 + colorRand.nextFloat() * 30);
      pairPalette[i][1] = color(hueB, 55 + colorRand.nextFloat() * 30, 45 + colorRand.nextFloat() * 30);
    }
  }

  // 4. pal: 8 acentos sólidos para los bloques cinéticos MB/M01-M08,
  // MShape, DElem y Motion — un degradado claro→oscuro sobre el mismo
  // acorde.
  pal = new color[8];
  for (int i = 0; i < pal.length; i++) {
    float t = i / float(pal.length - 1);
    float hue = schemeHueDeg[pickHueIdx(colorRand, schemeHueDeg.length)];
    float s = 58 + colorRand.nextFloat() * 32;
    float b = 40 + (1 - t) * 45 + colorRand.nextFloat() * 8;
    pal[i] = color(hue, s, b);
  }
}

void buildAccentPalette() {
  // Un único acento "chispa" por mutación (no uno distinto por forma o por
  // glifo), más el propio 'pal' de la mutación.
  color spark = HACC[(int)random(HACC.length)];
  accentPal = new color[pal.length + 2];
  for (int i = 0; i < pal.length; i++) accentPal[i] = pal[i];
  accentPal[pal.length] = spark;
  accentPal[pal.length + 1] = spark;
}

void buildEmphasis() {
  // 2-3 familias "protagonistas" por mutación (boost fuerte), el resto
  // atenuado — restraint curatorial en vez de maximalismo parejo cada vez.
  for (int i = 0; i < sysEmphasis.length; i++) sysEmphasis[i] = 0.45 + random(0.25);
  int leads = 2 + (int)random(2);
  for (int k = 0; k < leads; k++) {
    int idx = (int)random(sysEmphasis.length);
    sysEmphasis[idx] = 1.5 + random(0.6);
  }
}

// Muestreo tipo "blue-noise" por rechazo: en vez de un ángulo puramente al
// azar (que amontona puntos por pura probabilidad), prueba varios
// candidatos en el anillo [rMin,rMax] alrededor de (cx,cy) y se queda con
// el más alejado de lo ya ocupado esta mutación. Se degrada con elegancia:
// si ningún candidato cumple minDist, devuelve el mejor intento.
PVector spreadPoint(float cx, float cy, float rMin, float rMax, float minDist) {
  PVector best = null;
  float bestNearest = -1;
  for (int attempt = 0; attempt < 14; attempt++) {
    float a = random(TWO_PI);
    float r = random(rMin, rMax);
    float px = cx + cos(a) * r;
    float py = cy + sin(a) * r;
    float nearest = Float.MAX_VALUE;
    for (PVector o : occupied) nearest = min(nearest, dist(px, py, o.x, o.y));
    if (occupied.isEmpty() || nearest >= minDist) {
      best = new PVector(px, py);
      break;
    }
    if (nearest > bestNearest) { bestNearest = nearest; best = new PVector(px, py); }
  }
  occupied.add(best);
  return best;
}

color paletteColor(int index) { return unifiedPalette[((index % unifiedPalette.length) + unifiedPalette.length) % unifiedPalette.length]; }
color paletteColorFromPosition(float x, float y, int salt) {
  int ix = floor(x / 20.0), iy = floor(y / 20.0);
  int idx = abs(ix * 31 + iy * 47 + salt * 59 + patternIndex * 67 + compositionMode * 83 + seedValue) % unifiedPalette.length;
  return paletteColor(idx);
}
color rgb(int r, int g, int b) { return color(r, g, b); }
color lerpCol(color a, color b, float t) {
  // lerpColor(..., RGB) fuerza el espacio RGB explícitamente: colorMode()
  // está en HSB durante todo draw(), y red()/green()/blue() + color(r,g,b)
  // heredan ese modo, así que reconstruir el color a mano aquí interpretaría
  // los canales como H/S/B y produciría tintes incorrectos.
  return lerpColor(a, b, t, RGB);
}
float lerpAngle(float a, float b, float t) { float d = atan2(sin(b - a), cos(b - a)); return a + d * t; }
void dDBG() { int n = int(dElems.size() * 0.5); for (int i = 0; i < n; i++) dElems.get(i).display(); }
void dDFG() { int s = int(dElems.size() * 0.5); for (int i = s; i < dElems.size(); i++) dElems.get(i).display(); }

// ============================================================
// 10. CLASES DE ELEMENTOS VISUALES (cinéticos y estáticos)
// ============================================================
class MShape {
  float x, y, sz; int inn; color mc, ac;
  float wp, ws, br, bs, ra, rsp, tOff;
  MShape(float x, float y, float sz, int inn) {
    this.x=x; this.y=y; this.sz=max(15, sz); this.inn=inn;
    mc=pal[(int)random(pal.length)]; do{ac=pal[(int)random(pal.length)];}while(ac==mc);
    wp=random(TWO_PI); ws=random(0.01,0.03);
    br=random(TWO_PI); bs=random(0.008,0.025);
    ra=0; rsp=random(-0.005,0.005); tOff=random(100);
  }
  void display() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sc,off);
    float wx=sin(wp)*sz*0.06, wy=cos(wp*1.3)*sz*0.06, b=1.0+sin(br)*0.04;
    wp+=ws*gSpd; br+=bs*gSpd; ra+=rsp*gSpd; tOff+=0.03*gSpd;
    float cs=max(10, sz*b*sc[0]);
    pushMatrix(); translate(x+off.x+wx, y+off.y+wy); rotate(ra);
    fill(0,4); noStroke(); rect(2,2,cs,cs);
    fill(mc,A_SOLID); rect(0,0,cs,cs);
    dInn(cs); popMatrix();
  }
  void dInn(float sz) {
    fill(ac); stroke(ac); float hs=sz/2;
    switch(inn) {
      case 0: for(int i=4;i>=0;i--){fill(i%2==0?ac:mc);ellipse(0,0,max(2,sz*(0.15+i*0.15)),max(2,sz*(0.15+i*0.15)));} break;
      case 1: strokeWeight(max(1,sz*0.02));line(-hs*0.6,0,hs*0.6,0);line(0,-hs*0.6,0,hs*0.6);noStroke();fill(ac);ellipse(0,0,max(2,sz*0.09),max(2,sz*0.09)); break;
      case 2: strokeWeight(max(1,sz*0.018));for(int i=-3;i<=3;i++)line(-hs*0.52,i*sz*0.08,hs*0.52,i*sz*0.08);noStroke(); break;
      case 3: noStroke();for(int i=-2;i<=2;i++)for(int j=-2;j<=2;j++)ellipse(i*sz*0.13,j*sz*0.13,max(2,sz*0.04),max(2,sz*0.04)); break;
      case 4: noFill();strokeWeight(max(1,sz*0.02));for(int i=1;i<=4;i++)ellipse(0,0,max(2,i*hs*0.35),max(2,i*hs*0.35));noStroke();fill(ac);ellipse(0,0,max(2,sz*0.06),max(2,sz*0.06)); break;
      case 5: noStroke();float cs2=sz*0.15;for(int i=-2;i<=2;i++)for(int j=-2;j<=2;j++)if((i+j+4)%2==0)rect(i*cs2,j*cs2,cs2*0.85,cs2*0.85); break;
      case 6: strokeWeight(max(1,sz*0.012));for(int i=0;i<12;i++){float a=PI/6*i;line(0,0,cos(a)*hs*0.52,sin(a)*hs*0.52);}noStroke(); break;
      case 7: noFill();strokeWeight(max(1,sz*0.018));for(int w2=-2;w2<=2;w2++){beginShape();for(float px=-hs*0.52; px<=hs*0.52; px+=4)vertex(px,w2*sz*0.12+sin(px*0.1+tOff)*sz*0.04);endShape();}noStroke(); break;
    }
  }
}

class DElem {
  float x,y,sz; color c; float op; int tp; float an,rs,dx,dy,nT;
  DElem(float x,float y,float sz,color c,float op,int tp) {
    this.x=x;this.y=y;this.sz=max(5,sz);this.c=c;this.op=op*160;this.tp=tp;
    an=random(TWO_PI);rs=random(-0.02,0.02);dx=random(-0.12,0.12);dy=random(-0.12,0.12);nT=random(1000);
  }
  void display() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sc,off);
    an+=rs*gSpd; x+=(dx+(noise(nT)-0.5)*0.3)*gSpd; y+=(dy+(noise(nT+500)-0.5)*0.3)*gSpd; nT+=0.01*gSpd;
    pushMatrix(); translate(x+off.x, y+off.y); rotate(an); noStroke(); fill(c,op);
    if(sz>2) {
      switch(tp) {
        case 0:ellipse(0,0,sz,sz);break; case 1:rect(0,0,sz,sz);break; case 2:dPolyH(0,0,sz/2,3);break;
        case 3:dStarH(0,0,sz/2,sz/4,5);break; case 4:dPolyH(0,0,sz/2,6);break;
        case 5:rotate(PI/4);rect(0,0,sz*0.6,sz*0.6);break; case 6:rect(0,0,sz,sz/3);rect(0,0,sz/3,sz);break;
        case 7:for(int i=0;i<5;i++){pushMatrix();rotate(TWO_PI/5*i);ellipse(0,sz*0.24,max(2,sz*0.09),max(2,sz*0.16));popMatrix();}break;
      }
    }
    popMatrix();
  }
}

class MKMotion {
  float x, y, w, t; int mt; color c1, c2; float ps;
  MKMotion(float x, float y, float w, color c1, color c2, int mt) {
    this.x=x; this.y=y; this.w=max(15,w); this.c1=c1; this.c2=c2; this.mt=mt; t=random(TWO_PI); ps=random(0.8,1.2);
  }
  void run() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sc,off);
    float sp=gSpd*ps;
    pushMatrix(); translate(x+off.x, y+off.y); rotate(sin(waveSys.masterTime*2+t)*HALF_PI);
    noStroke(); fill(c1, vividMode?A_SOLID:120);
    switch(mt%13) {
      case 0: ellipse(0,0,w,w); fill(c2,A_SOLID); rect(0,0,w*0.5,w*0.5); break;
      case 1: triangle(-w*0.5,w*0.5,0,-w*0.5,w*0.5,w*0.5); fill(c2,A_SOLID); circle(0,0,w*0.3); break;
      case 2: rect(0,0,w*0.8,w*0.8); fill(c2,A_SOLID); ellipse(0,0,w*0.4,w*0.4); break;
      case 3: dPolyH(0,0,w*0.45,6); fill(c2,A_SOLID); dPolyH(0,0,w*0.25,6); break;
      case 4: dStarH(0,0,w*0.45,w*0.2,5); fill(c2,A_SOLID); circle(0,0,w*0.18); break;
      case 5: rect(0,0,w*0.75,w*0.25); rect(0,0,w*0.25,w*0.75); fill(c2,A_SOLID); circle(0,0,w*0.2); break;
      case 6: dPolyH(0,0,w*0.45,5); fill(c2,A_SOLID); dPolyH(0,0,w*0.25,5); break;
      case 7: dPolyH(0,0,w*0.42,8); fill(c2,A_SOLID); rect(0,0,w*0.3,w*0.3); break;
      case 8: quad(-w*0.35,0,0,-w*0.45,w*0.35,0,0,w*0.45); fill(c2,A_SOLID); circle(0,0,w*0.25); break;
      case 9: rotate(QUARTER_PI); rect(0,0,w*0.7,w*0.7); fill(c2,A_SOLID); ellipse(0,0,w*0.4,w*0.4); break;
      case 10: fill(c1,A_SOLID); dHeartH(w*0.55); fill(c2,A_SOLID); circle(0,0,w*0.14); break;
      case 11: fill(c1,A_SOLID); dPlusH(w*0.55); fill(c2,A_SOLID); circle(0,0,w*0.12); break;
      case 12: fill(c1,A_SOLID); dXCrossH(w*0.55); fill(c2,A_SOLID); rect(0,0,w*0.14,w*0.14,w*0.04); break;
    }
    popMatrix();
  }
}

class Motion {
  float ax, ay, baseW, phase;
  int motionType, gearDir;
  color clr1, clr2;
  Motion(float x, float y, float w, color c1, color c2, int mt, int gd) {
    ax=x; ay=y; baseW=max(15,w); clr1=c1; clr2=c2; motionType=mt; gearDir=gd; phase=random(TWO_PI);
  }
  void run() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(ax,ay,sc,off);
    float w=max(8, baseW*sc[0]*(0.8+0.22*sin(waveSys.masterTime*1.5+phase)));
    pushMatrix();
    translate(ax+off.x, ay+off.y);
    rotate(gearDir*(0.35+0.2*sin(waveSys.masterTime*1.5+phase))*sin(waveSys.masterTime+phase)+0.06*sin(waveSys.masterTime*2.2+phase));
    noStroke();
    fill(clr1, A_SOLID);
    int t=motionType%13;
    switch(t) {
      case 0: ellipse(0,0,w,w); fill(clr2,A_SOLID); rect(0,0,w*0.5,w*0.5); break;
      case 1: triangle(-w*0.5,w*0.5,0,-w*0.5,w*0.5,w*0.5); fill(clr2,A_SOLID); circle(0,0,w*0.3); break;
      case 2: rect(0,0,w*0.8,w*0.8); fill(clr2,A_SOLID); ellipse(0,0,w*0.4,w*0.4); break;
      case 3: dPolyH(0,0,w*0.45,6); fill(clr2,A_SOLID); dPolyH(0,0,w*0.25,6); break;
      case 4: dStarH(0,0,w*0.45,w*0.2,5); fill(clr2,A_SOLID); circle(0,0,w*0.18); break;
      case 5: rect(0,0,w*0.75,w*0.25); rect(0,0,w*0.25,w*0.75); fill(clr2,A_SOLID); circle(0,0,w*0.2); break;
      case 6: dPolyH(0,0,w*0.45,5); fill(clr2,A_SOLID); dPolyH(0,0,w*0.25,5); break;
      case 7: dPolyH(0,0,w*0.4,8); fill(clr2,A_SOLID); rect(0,0,w*0.3,w*0.3); break;
      case 8: quad(-w*0.35,0,0,-w*0.45,w*0.35,0,0,w*0.45); fill(clr2,A_SOLID); circle(0,0,w*0.25); break;
      case 9: rotate(QUARTER_PI); rect(0,0,w*0.7,w*0.7); fill(clr2,A_SOLID); ellipse(0,0,w*0.4,w*0.4); break;
      case 10: dHeartH(w*0.30); fill(clr2,A_SOLID); circle(0,w*0.08,w*0.12); break;
      case 11: dPlusH(w*0.75); fill(clr2,A_SOLID); circle(0,0,w*0.16); break;
      case 12: rectMode(CENTER); rect(0,0,w*0.6,w*0.6,w*0.1); fill(clr2,A_SOLID); rect(0,0,w*0.2,w*0.2,w*0.05); break;
    }
    popMatrix();
  }
}

class Flower {
  PVector p, v;
  float baseSize, phase;
  int petals;
  color clr;
  Flower(float x, float y, float size, int petals) {
    p=new PVector(x,y); v=new PVector(0,0); baseSize=max(10,size); this.petals=petals; phase=random(TWO_PI);
    clr=paletteColorFromPosition(x, y, petals);
  }
  void run() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(p.x,p.y,sc,off);
    float size=max(6, baseSize*sc[0]*(1.0+0.3*sin(waveSys.masterTime*1.8)));
    PVector f=waveSys.flow(p.x,p.y); f.mult(0.2); v.lerp(f,0.08); p.add(v);
    wrapXY(p,50);
    float pulse=0.85+0.15*sin(waveSys.masterTime*1.5+phase);
    float rot=phase+0.2*sin(waveSys.masterTime*0.8+phase);
    pushMatrix();
    translate(p.x+off.x,p.y+off.y); rotate(rot); noStroke(); fill(clr, vividMode?155:100);
    for(int i=0;i<petals;i++) {
      float a=TWO_PI/petals*i;
      ellipse(cos(a)*size*0.4, sin(a)*size*0.4, max(2,(size/2.2)*pulse), max(2,(size/3.5)*pulse));
    }
    fill(0, vividMode?155:100); ellipse(0,0,max(2,size*0.18),max(2,size*0.18));
    popMatrix();
  }
}

class Connector {
  PVector p, v;
  float baseSize, phase;
  color clr;
  Connector(float x, float y, float size) {
    p=new PVector(x,y); v=new PVector(0,0); baseSize=max(10,size); phase=random(TWO_PI);
    clr=random(1)<0.35?color(0):paletteColorFromPosition(x, y, int(size));
  }
  void run() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(p.x,p.y,sc,off);
    float size=max(6, baseSize*sc[0]*(0.7+0.2*sin(waveSys.masterTime*1.4+phase)));
    PVector f=waveSys.flow(p.x,p.y); f.mult(0.25); v.lerp(f,0.08); p.add(v);
    wrapXY(p,50);
    PVector dir=waveSys.flow(p.x,p.y);
    float ang=atan2(dir.y,dir.x)+0.15*sin(waveSys.masterTime*1.4+phase);
    pushMatrix();
    translate(p.x+off.x,p.y+off.y); rotate(ang); stroke(clr,vividMode?135:65); strokeWeight(1.6);
    line(-size/2,0,size/2,0); noStroke(); fill(clr, vividMode?155:75);
    circle(-size/2,0,3.2); circle(size/2,0,3.2);
    popMatrix();
  }
}

class CharacterSymbol {
  PVector originalP;
  float phase, baseSize;
  char symbol;
  color clr;
  char[] charPool = {'0','1','#','@','&','!'};
  CharacterSymbol(float x, float y, float size) {
    originalP=new PVector(x,y);
    phase=random(TWO_PI);
    symbol=charPool[int(random(charPool.length))];
    clr=paletteColorFromPosition(x,y,int(symbol));
    baseSize=max(12,size);
  }
  void run() {
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(originalP.x,originalP.y,sc,off);
    float size=max(8, baseSize*sc[0]*(0.9+0.1*sin(waveSys.masterTime*1.5+phase)));
    if (!paused && random(1)<0.08) {
      textGhostTrails.add(new TextGhostTrail(originalP.x+off.x, originalP.y+off.y, symbol, clr));
    }
    pushMatrix();
    translate(originalP.x+off.x, originalP.y+off.y);
    rotate(0.06*sin(waveSys.masterTime+phase));
    textSize(size); textAlign(CENTER,CENTER); fill(clr, vividMode?A_TEXT:130);
    text(symbol,0,0);
    popMatrix();
  }
}

class BinaryRain {
  float x;
  ArrayList<BinaryDrop> drops;
  BinaryRain(float x) { this.x=x; drops=new ArrayList<BinaryDrop>(); for(int i=0;i<int(random(2,4));i++) drops.add(new BinaryDrop(x,random(-200,height))); }
  void run() { for(BinaryDrop drop:drops) drop.run(); }
}
class BinaryDrop {
  float x,y,baseX;
  char digit;
  float speed,alpha,phase;
  color clr;
  char[] numPool={'0','1'};
  BinaryDrop(float x,float y){ this.x=x; this.baseX=x; this.y=y; phase=random(TWO_PI); digit=numPool[int(random(numPool.length))]; speed=random(0.9,1.7); clr=paletteColorFromPosition(x,y,int(random(1000))); alpha=vividMode?random(120,160):random(60,90);}
  void run(){ float sway=3.5*sin(waveSys.masterTime*1.2+phase+baseX*0.01); textSize(14); textAlign(CENTER,CENTER); fill(clr,alpha); text(digit, baseX+sway, y); y+=speed*speedMultiplier; if(y>height+20){y=-20; digit=numPool[int(random(numPool.length))];}}
}

class VibrantShape {
  float baseX, baseY, baseSize, angle, rotSpeed, phase;
  color clr;
  int shapeType, sides;
  VibrantShape(float x,float y,float size){ baseX=x; baseY=y; baseSize=max(12,size); phase=random(TWO_PI); angle=random(TWO_PI); rotSpeed=random(-0.006,0.006); clr=paletteColorFromPosition(x,y,int(size)); shapeType=int(random(10)); sides=int(random(3,8));}
  void run(){
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(baseX,baseY,sc,off);
    float size=max(6, baseSize*sc[0]*(1.0+0.3*sin(waveSys.masterTime*1.8)));
    pushMatrix(); translate(baseX+off.x, baseY+off.y); rotate(angle+0.15*sin(waveSys.masterTime+phase));
    noStroke(); fill(clr, vividMode?A_SOLID:120);
    switch(shapeType){
      case 0: ellipse(0,0,size,size); break;
      case 1: rect(0,0,size,size); break;
      case 2: dPolyH(0,0,size*0.48, sides); break;
      case 3: dStarH(0,0,size*0.24,size*0.48,5); break;
      case 4: dPolyH(0,0,size*0.48,6); break;
      case 5: dPolyH(0,0,size*0.48,3); break;
      case 6: dPlusH(size*0.55); break;
      case 7: dHeartH(size*0.45); break;
      case 8: dXCrossH(size*0.55); break;
      case 9: quad(-size*0.3,0,0,-size*0.4,size*0.3,0,0,size*0.4); break;
    }
    angle+=rotSpeed*speedMultiplier;
    popMatrix();
  }
}

class ComplexGeometry {
  float baseX,baseY,baseSize,angle,speed,phase;
  int type,layerDepth;
  color clr;
  ComplexGeometry(float x,float y,float size,int ld){ baseX=x; baseY=y; baseSize=max(12,size); layerDepth=ld; phase=random(TWO_PI); angle=random(TWO_PI); speed=random(0.003,0.01); type=int(random(10)); clr=paletteColorFromPosition(x,y,ld);}
  void run(){
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(baseX,baseY,sc,off);
    float s=max(6, baseSize*sc[0]*(1.0+0.3*sin(waveSys.masterTime*1.8)));
    pushMatrix(); translate(baseX+off.x, baseY+off.y); rotate(angle+0.15*sin(waveSys.masterTime+phase));
    noStroke(); fill(clr,145);
    for(int i=0;i<2;i++){ float sz=s*(1.0-i*0.3); fill(clr, vividMode?160-i*30:80); pushMatrix(); rotate(QUARTER_PI*i*0.5); if(type%2==0) rect(0,0,sz,sz,sz*0.1); else ellipse(0,0,sz,sz); popMatrix();}
    angle+=speed*speedMultiplier;
    popMatrix();
  }
}

class OrbitingElement {
  float baseX,baseY,baseRadius,angle,phase;
  color clr;
  OrbitingElement(float x,float y,float radius){ baseX=x; baseY=y; baseRadius=max(12,radius); phase=random(TWO_PI); angle=random(TWO_PI); clr=paletteColorFromPosition(x,y,int(radius));}
  void run(){
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(baseX,baseY,sc,off);
    float radius=max(6, baseRadius*sc[0]*(1.0+0.3*sin(waveSys.masterTime*1.8)));
    pushMatrix(); translate(baseX+off.x, baseY+off.y); rotate(angle+0.18*sin(waveSys.masterTime+phase));
    noStroke(); fill(clr, vividMode?A_SOLID:90); ellipse(0,0,radius*0.3,radius*0.3);
    int sats=3; for(int i=0;i<sats;i++){ float a=TWO_PI/sats*i+waveSys.masterTime*0.8; ellipse(cos(a)*radius*0.62, sin(a)*radius*0.62, max(2,radius*0.09), max(2,radius*0.09));}
    angle+=0.006*speedMultiplier;
    popMatrix();
  }
}

class OkazzFlower {
  float originalX, baseY, baseSize, phase;
  color clr;
  OkazzFlower(float x,float y,float size){ originalX=x; baseY=y; baseSize=max(12,size); phase=random(TWO_PI); clr=paletteColorFromPosition(x,y,int(size));}
  void run(){
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(originalX,baseY,sc,off);
    float s=max(6, baseSize*sc[0]*(1.0+0.3*sin(waveSys.masterTime*1.8)));
    pushMatrix(); translate(originalX+off.x, baseY+off.y); rotate(waveSys.masterTime*0.35+phase);
    noStroke(); fill(clr, vividMode?170:110);
    rect(0,0,s,s,s*0.15);
    pushMatrix(); rotate(-waveSys.masterTime*0.55);
    for(int i=0;i<4;i++){ float rs=max(3,(0.3+0.2*sin(waveSys.masterTime+phase+i))*s); float ss=max(2,s-rs); rotate(HALF_PI); if(rs>2&&ss>2) arc((ss)/2,-s/2,rs,rs,PI,TWO_PI);}
    popMatrix();
    popMatrix();
  }
}

class OkazzTrailShape {
  float originalX, yPos, w;
  int timer=0, tSpan=24, shapeType;
  color clr;
  ArrayList<TrailPiece> trail;
  OkazzTrailShape(float x,float y,float w,color clr){ originalX=x; yPos=y; this.w=max(12,w); this.clr=clr; shapeType=int(random(4)); trail=new ArrayList<TrailPiece>();}
  void run(){
    for(int i=trail.size()-1;i>=0;i--){ TrailPiece tp=trail.get(i); tp.w-=0.35*speedMultiplier; if(tp.w<=2.5) trail.remove(i);}
    for(TrailPiece tp:trail) if(tp.w>2.5) drawShape(tp.x,tp.y,tp.w,shapeType);
    if(w>2.5) drawShape(originalX,yPos,w,shapeType);
    if(!paused){ timer+=speedMultiplier; if(timer>=tSpan){ trail.add(new TrailPiece(originalX,yPos,w)); int dir=int(random(4)); float cellSize=60; originalX+=cellSize*cos(dir*HALF_PI); yPos+=cellSize*sin(dir*HALF_PI); originalX=constrain(originalX,BORDER_WIDTH,width-BORDER_WIDTH); yPos=constrain(yPos,BORDER_WIDTH,height-BORDER_WIDTH); timer=0; tSpan=int(random(20,32));}}
  }
  void drawShape(float x,float y,float size,int type){ if(size<2.5)return; pushStyle(); noFill(); stroke(clr, vividMode?160:100); strokeWeight(max(1,size*0.16)); if(type==0){ noStroke(); fill(clr, vividMode?160:110); rect(x,y,size,size);} else if(type==1){ noStroke(); fill(clr, vividMode?160:110); ellipse(x,y,size,size);} else if(type==2){ line(x-size/2,y,x+size/2,y); line(x,y-size/2,x,y+size/2);} else { line(x-size/2,y-size/2,x+size/2,y+size/2);} popStyle();}
}
class TrailPiece { float x,y,w; TrailPiece(float x,float y,float w){ this.x=x; this.y=y; this.w=w; } }

class TextGhostTrail {
  float x,y; char symbol; color clr; float alpha;
  TextGhostTrail(float x,float y,char symbol,color clr){ this.x=x; this.y=y; this.symbol=symbol; this.clr=clr; alpha=130;}
  void run(){ alpha-=2.0*speedMultiplier; if(alpha>0){ pushStyle(); textSize(20); textAlign(CENTER,CENTER); fill(clr,alpha); text(symbol,x,y); popStyle();}}
  boolean isDead(){ return alpha<=0; }
}

class CSym {
  float x,y,an,rs,pu,ps,sz,vx,vy,nT; int md; char sy; int gT; color c; float psp;
  CSym(float x,float y,char sy){ this.x=x; this.y=y; md=0; this.sy=sy; an=random(TWO_PI); rs=random(-0.02,0.02); pu=random(TWO_PI); ps=random(0.015,0.04); c=(sy=='0'||sy=='1')?accentPal[int(random(accentPal.length))]:color(0); sz=(sy=='0'||sy=='1')?random(10,14):random(12,16); vx=random(-0.4,0.4); vy=random(-0.4,0.4); nT=random(1000); psp=random(0.7,1.1);}
  CSym(float x,float y,int gT){ this.x=x; this.y=y; md=1; this.gT=gT; an=random(TWO_PI); rs=random(-0.025,0.025); pu=random(TWO_PI); ps=random(0.015,0.04); c=accentPal[int(random(accentPal.length))]; sz=random(12,20); vx=random(-0.7,0.7); vy=random(-0.7,0.7); nT=random(1000); psp=random(0.75,1.1);}
  void run(){
    float[] sc=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sc,off);
    float sp=gSpd*psp;
    x+=(vx+(noise(nT)-0.5)*0.7)*sp; y+=(vy+(noise(nT+777)-0.5)*0.7)*sp; nT+=0.015*sp;
    PVector p=new PVector(x,y); wrapXY(p,BORDER_WIDTH); x=p.x; y=p.y;
    pushMatrix(); translate(x+off.x,y+off.y); rotate(an); float pz=1+sin(pu)*0.1; float s=max(5,sz*pz);
    if(md==0){ textSize(sz); textAlign(CENTER,CENTER); if(sy=='0'||sy=='1') fill(c,vividMode?175:85); else fill(0,vividMode?150:50); text(sy,0,0);}
    else{ noStroke(); fill(c,vividMode?175:85); if(gT==10)dHeartH(s); else if(gT==11)dPlusH(s); else if(gT==12)dXCrossH(s); else rect(0,0,s*0.95,s*0.95,s*0.12);}
    an+=rs*sp; pu+=ps*sp;
    popMatrix();
  }
}

// ============================================================
// 11. CLASES MB, M01..M08 Y OBJCT (elementos modulares)
// ============================================================
class MB {
  float x,y,w,t; int t1; float tS,an; color c1,c2; float pS;
  MB(float x,float y,float w){this.x=x;this.y=y;this.w=max(15,w);t=0;t1=(int)random(45,100);
    tS=random(0.7,2.0);an=(int)random(4)*(TWO_PI/4);c1=c2=0;
    while(c1==c2){c1=pP();c2=pP();} pS=random(0.8,1.6);}
  void show(){} void move(){} float sp(){return gSpd*pS;}
}

class M01 extends MB {
  int n; float sw; int sc;
  M01(float x,float y,float w){super(x,y,w);n=(int)random(3,6);sw=max(1.5,w/n);sc=(int)random(2);}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    pushMatrix();translate(x+off.x,y+off.y);rotate(an);noFill();strokeCap(SQUARE);strokeWeight(sw);stroke(c2);
    for(int i=0;i<n;i++){float yy=map(i,0,n-1,-w/2+sw/2,w/2-sw/2);float offs=sc*((i%2)*sw)+t;
      for(float px=-w/2;px<w/2;px+=sw*2)line(px+offs,yy,px+sw+offs,yy);}popMatrix();
  }
  void move(){t+=tS*sp()*1.1;}
}

class M02 extends MB {
  float cx,cd;
  M02(float x,float y,float w){super(x,y,w);cx=0;cd=max(4.0,w*0.42);}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    pushMatrix();translate(x+off.x,y+off.y);rotate(an);noStroke();fill(c2,A_SOLID);circle(cx,0,cd);circle(cx-w,0,cd);
    fill(255,80);ellipse(cx-cd*0.2,-cd*0.2,max(2,cd*0.25),max(2,cd*0.25));popMatrix();
  }
  void move(){t+=sp()*1.3;if(0<t&&t<t1)cx=lerp(0,w,easeIO(norm(t,0,t1-1)));if(t>t1){t=0;cx=0;}}
}

class M03 extends MB {
  int t2; float d,sd,s0,s1;
  M03(float x,float y,float w){super(x,y,w);t2=t1+40;d=max(4.5,w*0.25);sd=d;s0=d;s1=d*3.8;}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    pushMatrix();translate(x+off.x,y+off.y);rotate(an);noStroke();fill(c2,A_SOLID);
    if(d>2.0) circle(0,0,d);
    if(t<t1){noFill();stroke(c2,130);strokeWeight(max(0.5,d*0.08));float ringSize=sd-d;if(ringSize>2.0) circle(0,0,ringSize);}
    noStroke();fill(255,90);ellipse(-d*0.2,-d*0.2,max(2,d*0.25),max(2,d*0.25));popMatrix();
  }
  void move(){if(0<t&&t<t1)sd=lerp(s0,s1,easeIO(norm(t,0,t1)));if(t>t2){t=0;sd=s0;}t+=sp()*1.1;}
}

class M04 extends MB {
  float d,rd; float[] ca,cd; int cn; color[] cs;
  M04(float x,float y,float w){super(x,y,w);d=max(4.5,w*0.25);rd=d;cn=5;
    ca=new float[cn];cd=new float[cn];for(int i=0;i<cn;i++){ca[i]=0;cd[i]=max(2,map(i,0,cn-1,d,d*0.2));}
    t1=(int)random(90,160);cs=new color[pal.length];arrayCopy(pal,cs);shufC(cs);}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    pushMatrix();translate(x+off.x,y+off.y);rotate(an);noFill();stroke(c1,25);strokeWeight(1);
    for(int i=0;i<cn;i++)ellipse(0,0,max(2,map(i,0,cn-1,rd*2,rd*0.4)),max(2,map(i,0,cn-1,rd*2,rd*0.4)));
    noStroke();for(int i=0;i<cn;i++){float ox=rd*cos(ca[i]),oy=rd*sin(ca[i]);fill(cs[i%cs.length],160);ellipse(ox,oy,cd[i],cd[i]);
      fill(255,110);ellipse(ox-cd[i]*0.15,oy-cd[i]*0.15,max(2,cd[i]*0.2),max(2,cd[i]*0.2));}popMatrix();
  }
  void move(){if(0<t&&t<t1){float n=norm(t,0,t1);for(int i=0;i<cn;i++)ca[i]=lerp(0,TWO_PI,pow(easeIO(n),map(i,0,cn-1,0.7,3.5)));}
    if(t>t1){t=0;for(int i=0;i<cn;i++)ca[i]=0;}t+=sp()*1.0;}
}

class M05 extends MB {
  int n5,r5; float sz5,tm5; float[] cx5,cy5; color[] cc5; int[] ct5;
  M05(float x,float y,float w){super(x,y,w);n5=(int)random(4,7);sz5=w/n5;tm5=random(0.025,0.065);
    color[] cs=new color[pal.length];arrayCopy(pal,cs);shufC(cs);
    int tot=n5*n5;cx5=new float[tot];cy5=new float[tot];cc5=new color[tot];ct5=new int[tot];
    int idx=0;for(int i=0;i<n5;i++)for(int j=0;j<n5;j++){cx5[idx]=i*sz5+x-w/2;cy5[idx]=j*sz5+y-w/2;cc5[idx]=cs[(i+j)%cs.length];ct5[idx]=(int)random(1000);idx++;}
    r5=(int)random(3);}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    noStroke();for(int i=0;i<cx5.length;i++){float as=sz5*sin(waveSys.masterTime*1.5+ct5[i])*0.65;if(as<=2.0)continue;
    fill(cc5[i],145);pushMatrix();translate(cx5[i]+sz5/2+off.x,cy5[i]+sz5/2+off.y);
    if(r5==0)ellipse(0,0,as,as);else if(r5==1){rotate(waveSys.masterTime*0.4);rect(0,0,as,as);}else{rotate(waveSys.masterTime*0.5);dPolyH(0,0,as/2,5+i%4);}
    fill(255,90);ellipse(-as*0.15,-as*0.15,max(2,as*0.2),max(2,as*0.2));popMatrix();}
  }
  void move(){t+=sp();}
}

class M06 extends MB {
  int wt,n6; color[] cs6; float[] ph,am;
  M06(float x,float y,float w){super(x,y,w);wt=(int)random(1,4);n6=(int)random(4,7);
    cs6=new color[pal.length];arrayCopy(pal,cs6);shufC(cs6);
    ph=new float[n6];am=new float[n6];for(int i=0;i<n6;i++){ph[i]=random(TWO_PI);am[i]=random(0.6,1.0);}}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    float amp=w/n6;pushMatrix();translate(x+off.x,y+off.y);rotate(an);noFill();
    for(int j=0;j<n6;j++){float yy=map(j,0,n6,-w/2,w/2);stroke(cs6[(j+1)%cs6.length],120);strokeWeight(max(0.5,w*0.01+(j%3)*0.01));
      beginShape();for(float i=0;i<=w;i+=4){float xx=i-w/2;float nr=norm(i,0,w);vertex(xx,yy+amp*0.4*am[j]*sin((nr*wt*PI)+waveSys.masterTime*1.2+ph[j]));}endShape();}
    popMatrix();
  }
  void move(){t+=sp();for(int i=0;i<n6;i++)ph[i]+=0.02*sp()*(i%2==0?1:-1);}
}

class M07 extends MB {
  float ex,ey,ew,ex0,ey0,ex1,ey1,tn; int r7,pr7;
  M07(float x,float y,float w){super(x,y,w);ex=0;ey=0;ew=max(4.5,w*0.16);r7=1000;i7();}
  void i7(){t1=(int)random(30,80);pr7=r7;while(r7==pr7)r7=(int)random(6);
    ex0=ex;ey0=ey;if(r7==0){ex1=0;ey1=0;}else if(r7==1){ex1=ew*0.28;ey1=0;}else if(r7==2){ex1=-ew*0.28;ey1=0;}
    else if(r7==3){ex1=0;ey1=ew*0.28;}else if(r7==4){ex1=0;ey1=-ew*0.28;}else{ex1=ex0;ey1=ey0;tn=0;}}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    pushMatrix();translate(x+off.x,y+off.y);rotate(an);noStroke();
    fill(c1,145);ellipse(w*0.28,0,max(2,w*0.3),max(2,w*0.3));ellipse(-w*0.28,0,max(2,w*0.3),max(2,w*0.3));
    fill(c2,165);ellipse(w*0.28+ex,ey,ew,ew);ellipse(-w*0.28+ex,ey,ew,ew);
    if(r7==5){fill(BG);rect(0,-w*0.3+tn,w,max(2,tn*2));}popMatrix();
  }
  void move(){t+=sp();if(0<t&&t<t1){float n=norm(t,0,t1-1);ex=lerp(ex0,ex1,easeIO(n));ey=lerp(ey0,ey1,easeIO(n));if(r7==5)tn=lerp(0,w*0.3,sin(easeIO(n)*PI));}
    if(t>t1){t=0;i7();}}
}

class M08 extends MB {
  float r8,pm; int cs8;
  M08(float x,float y,float w){super(x,y,w);r8=max(6.0,w*0.3);tS=random(0.8);pm=random(1)<0.5?-1:1;cs8=(int)random(3);}
  void show(){
    float[] sca=new float[1]; PVector off=new PVector();
    waveSys.compute(x,y,sca,off);
    pushMatrix();translate(x+off.x,y+off.y);rotate(an);
    switch(cs8){case 0:noFill();stroke(c1,120);strokeWeight(1.6);ellipse(0,0,r8*2.2,r8*2.2);break;
      case 1:noFill();stroke(c1,120);strokeWeight(1.6);dPolyH(0,0,r8*1.1,12);break;
      case 2:fill(c1,12);noStroke();ellipse(0,0,r8*2.2,r8*2.2);break;}
    fill(c1);noStroke();for(int i=0;i<12;i++){float a=map(i,0,12,0,TWO_PI);ellipse(r8*cos(a),r8*sin(a),max(2,w*0.025),max(2,w*0.025));}
    float ha=waveSys.masterTime*1.1*pm,ma=waveSys.masterTime*2.8*pm,sa=waveSys.masterTime*6.5*pm;
    stroke(c2);strokeWeight(max(0.9,w*0.018));line(0,0,r8*0.5*cos(ha),r8*0.5*sin(ha));
    strokeWeight(max(0.7,w*0.01));line(0,0,r8*0.7*cos(ma),r8*0.7*sin(ma));
    stroke(c1);strokeWeight(max(0.4,w*0.007));line(0,0,r8*0.8*cos(sa),r8*0.8*sin(sa));
    noStroke();fill(c2);ellipse(0,0,max(2,w*0.045),max(2,w*0.045));fill(255,145);ellipse(0,0,max(1,w*0.02),max(1,w*0.02));popMatrix();
  }
  void move(){t+=sp();}
}

class Objct {
  MB m;
  Objct(float x,float y,float w){
    float o=width*0.005;
    int r=(int)random(8)+1;
    if(r==1) m = new M01(x+w/2, y+w/2, w-o);
    else if(r==2) m = new M02(x+w/2, y+w/2, w-o);
    else if(r==3) m = new M03(x+w/2, y+w/2, w-o);
    else if(r==4) m = new M04(x+w/2, y+w/2, w-o);
    else if(r==5) m = new M05(x+w/2, y+w/2, w-o);
    else if(r==6) m = new M06(x+w/2, y+w/2, w-o);
    else if(r==7) m = new M07(x+w/2, y+w/2, w-o);
    else m = new M08(x+w/2, y+w/2, w-o);
  }
  void run(){ m.show(); m.move(); }
}

// ============================================================
// 12. FUNCIONES DE CONSTRUCCIÓN (MG, MK, MS, DE)
// ============================================================
void buildMG() {
  int gc=(int)random(6,9);
  float gw=(width-BORDER_WIDTH*2)/gc;
  float ox=BORDER_WIDTH, oy=BORDER_WIDTH;
  boolean[][] gr=new boolean[gc][gc];
  ArrayList<float[]> rs=new ArrayList<float[]>();
  int emp=gc*gc, att=0;
  while(emp>0 && att<1000) {
    att++;
    int w=(int)random(1,3), h=w;
    if(gc-w<0) continue;
    int x=(int)random(gc-w+1), y=(int)random(gc-h+1);
    boolean ok=true;
    for(int j=0; j<h && ok; j++) for(int i=0; i<w && ok; i++) if(y+j>=gc || x+i>=gc || gr[y+j][x+i]) ok=false;
    if(ok){
      for(int j=0; j<h; j++) for(int i=0; i<w; i++) gr[y+j][x+i]=true;
      rs.add(new float[]{x*gw+ox, y*gw+oy, w*gw, h*gw});
      emp-=w*h;
    }
  }
  for(float[] r : rs) objs.add(new Objct(r[0], r[1], r[2]));
}

void buildMK() {
  float gs=(width-BORDER_WIDTH*2)*0.7;
  int cc=max(2, int(2.0*densityFactor));
  float cs=gs/cc;
  float ox=(width-gs)/2, oy=(height-gs)/2;
  for(int i=0; i<cc; i++) for(int j=0; j<cc; j++)
    if(random(1)<0.45) mkMotions.add(new MKMotion(cs*j+cs/2+ox, cs*i+cs/2+oy, cs*0.48, paletteColor(i), paletteColor(j+10), patternIndex));
}

void buildMS() {
  int gx=2, gy=2;
  float cw=(width-BORDER_WIDTH*2)/gx, ch=(height-BORDER_WIDTH*2)/gy;
  float ox=BORDER_WIDTH, oy=BORDER_WIDTH;
  int cnt=0;
  for(int y=0; y<gy; y++) for(int x=0; x<gx; x++) {
    if(cnt>=4) break;
    mShapes.add(new MShape(ox+x*cw+cw/2, oy+y*ch+ch/2, min(cw,ch)*0.3, (int)random(8)));
    cnt++;
  }
}

void buildDE() {
  for(int i=0; i<int(6*densityFactor); i++)
    dElems.add(new DElem(random(width*0.25,width*0.75), random(height*0.25,height*0.75), random(10,18), pal[(int)random(pal.length)], random(0.3,0.6), (int)random(8)));
}

// ============================================================
// 13. MOTORES KINETIC KAL
// ============================================================
int KS; float KP, KG; int KC, KR; float KSX, KSY; color[] KPL; ArrayList<ArrayList<SLayer>> KAL;

void initKineticMotifs() {
  KS=68; KP=KS*0.45; KG=KS+KP;
  KPL=new color[]{color(255,94,196),color(20,166,255),color(232,68,31),color(255,106,0),color(247,160,0),color(244,205,0),color(21,173,3),color(27,130,230),color(109,90,207),color(239,71,111),color(6,214,160),color(255,0,110)};
  float aw=(width-BORDER_WIDTH*2), ah=(height-BORDER_WIDTH*2);
  KC=max(1,floor(aw/KG)); KR=max(1,floor(ah/KG));
  KSX=aw/KC; KSY=ah/KR;
  KAL=new ArrayList<ArrayList<SLayer>>();
  regenKS();
}

void regenKS(){
  if(KAL==null) return;
  KAL.clear();
  float ox = BORDER_WIDTH + (width-BORDER_WIDTH*2 - KC*KG)/2;
  float oy = BORDER_WIDTH + (height-BORDER_WIDTH*2 - KR*KG)/2;
  for(int x=0; x<KC; x++) for(int y=0; y<KR; y++){
    float px=ox+KSX*(x+0.5), py=oy+KSY*(y+0.5);
    KAL.add(mkKM(px,py));
  }
}

void runKineticMotifs(){
  if(!showKM || KAL==null) return;
  for(ArrayList<SLayer> s:KAL) for(SLayer l:s){
    if(l!=null && l.sd){
      pushMatrix();
      translate(l.px,l.py);
      l.upd();
      l.ren();
      popMatrix();
    }
  }
}

color kP(){ return KPL[floor(random(KPL.length))]; }

ArrayList<SLayer> mkKM(float x,float y){
  ArrayList<SLayer> ls=new ArrayList<SLayer>();
  String[] nm={"co","da","as","rs","oc","ct","dc","cc","re","ar","cr","dx","mc"};
  float[] wt={0.7,0.7,0.7,0.7,0.7,0.7,0.7,0.82,0.82,0.82,0.82,0.82,0.7};
  for(int i=nm.length-1;i>0;i--){
    int j=floor(random(i+1));
    String t=nm[i]; nm[i]=nm[j]; nm[j]=t;
    float tw=wt[i]; wt[i]=wt[j]; wt[j]=tw;
  }
  for(int i=0;i<nm.length;i++){
    if(random(1)>wt[i]){
      SLayer sl=cKM(nm[i],x,y);
      if(sl!=null) ls.add(sl);
    }
  }
  while(ls.size()>2) ls.remove(ls.size()-1);
  return ls;
}

SLayer cKM(String n,float x,float y){
  color c=kP();
  if(n.equals("co")) return new KCO(x,y,c);
  if(n.equals("da")) return new KDA(x,y,c);
  if(n.equals("as")) return new KAS(x,y,c);
  if(n.equals("rs")) return new KRS(x,y,c);
  if(n.equals("oc")) return new KOC(x,y,c);
  if(n.equals("ct")) return new KCT(x,y,c);
  if(n.equals("dc")) return new KDC(x,y,c);
  if(n.equals("cc")) return new KCC(x,y,c);
  if(n.equals("re")) return new KRE(x,y,c);
  if(n.equals("ar")) return new KAR(x,y,c);
  if(n.equals("cr")) return new KCR(x,y,c);
  if(n.equals("dx")) return new KDX(x,y,c);
  if(n.equals("mc")) return new KMC(x,y,c);
  return null;
}

abstract class SLayer {
  float px,py; color cl; boolean sd;
  SLayer(float x,float y,color c){px=x;py=y;cl=c;sd=true;}
  abstract void upd();
  abstract void ren();
}

class KCO extends SLayer{float g=1;int gd=1;KCO(float x,float y,color c){super(x,y,c);} void upd(){if(g>=1.7)gd=-1;else if(g<=0.65)gd=1;g+=0.03*gd*gSpd;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); noFill(); strokeWeight(3.5); stroke(cl); circle(0,0,max(4,KS*(g/1.5)-5)); popMatrix(); } }
class KDA extends SLayer{float r=0;KDA(float x,float y,color c){super(x,y,c);} void upd(){r+=2.8*gSpd;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); rotate(radians(-r)); noFill(); strokeCap(SQUARE); stroke(cl); strokeWeight(3.5); for(int i=0;i<8;i++){arc(0,0,max(4,KS-5),max(4,KS-5),radians(i*45),radians(i*45+18));} popMatrix(); popMatrix(); } }
class KAS extends SLayer{float w=3;int wd=1;KAS(float x,float y,color c){super(x,y,c);} void upd(){w+=0.7*wd*gSpd;if(w>=9||w<=3)wd*=-1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); stroke(cl); strokeWeight(max(1,w)); strokeCap(SQUARE); noFill(); for(int i=0;i<3;i++){line(0,-KS/2.3,0,KS/2.3);rotate(radians(60));} popMatrix(); } }
class KRS extends SLayer{float r=0;KRS(float x,float y,color c){super(x,y,c);} void upd(){r+=2.8*gSpd;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); noFill(); rotate(radians(-r)); strokeWeight(3); stroke(cl); float s=KS/1.5; rect(0,0,s,s,9); rotate(radians(45)); rect(0,0,s/1.4,s/1.4,4); popMatrix(); popMatrix(); } }
class KOC extends SLayer{float w=14;int wd=1;KOC(float x,float y,color c){super(x,y,c);} void upd(){w+=0.7*wd*gSpd;if(w>=38||w<=14)wd*=-1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); noFill(); stroke(cl); strokeWeight(max(1,w)); strokeJoin(ROUND); rotate(radians(22.5)); dPolyH(0,0,KS/2.6,8); popMatrix(); popMatrix(); } }
class KCT extends SLayer{float w=14;int wd=1;KCT(float x,float y,color c){super(x,y,c);} void upd(){w+=0.7*wd*gSpd;if(w>=38||w<=14)wd*=-1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); noFill(); strokeWeight(max(1,w)); stroke(cl); circle(0,0,max(4,KS/2.3)); popMatrix(); } }
class KDC extends SLayer{float w=4.5;int wd=1;KDC(float x,float y,color c){super(x,y,c);} void upd(){w+=0.7*wd*gSpd;if(w>=25||w<=4.5)wd*=-1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); noFill(); strokeWeight(max(1,w)); stroke(cl); circle(0,0,max(4,KS-w)); fill(cl); noStroke(); circle(0,0,max(4,KS/3.8)); popMatrix(); popMatrix(); } }
class KCC extends SLayer{float w=2;int wd=1;KCC(float x,float y,color c){super(x,y,c);} void upd(){w+=0.15*wd*gSpd;if(w>=11)wd=-1;else if(w<=2)wd=1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); stroke(cl); strokeWeight(max(0.5,w)); noFill(); float s=KS-w; ellipse(0,0,max(4,s),max(4,s)); ellipse(0,0,max(4,s/1.5),max(4,s/1.5)); ellipse(0,0,max(4,s/3),max(4,s/3)); popMatrix(); } }
class KRE extends SLayer{float w=4.5;int wd=1;KRE(float x,float y,color c){super(x,y,c);} void upd(){w+=0.7*wd*gSpd;if(w>=11||w<=4.5)wd*=-1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); noFill(); strokeWeight(max(1,w)); stroke(cl); rect(0,0,KS-10,KS-10); popMatrix(); } }
class KAR extends SLayer{float r=0;boolean tl;KAR(float x,float y,color c){super(x,y,c);tl=random(1)>0.5;} void upd(){r+=2.5*gSpd;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); fill(cl); rotate(radians(r)); noStroke(); if(KS>10){ if(tl){arc(0,0,KS,KS,radians(180),radians(270),PIE);arc(0,0,KS,KS,0,radians(90),PIE);} else{arc(0,0,KS,KS,radians(270),radians(360),PIE);arc(0,0,KS,KS,radians(90),radians(180),PIE);}} popMatrix(); popMatrix(); } }
class KCR extends SLayer{float r=0;KCR(float x,float y,color c){super(x,y,c);} void upd(){r+=2.2*gSpd;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); fill(cl); rotate(radians(r)); noStroke(); float d=6; rect(0,0,KS/d,KS); rect(0,0,KS,KS/d); popMatrix(); popMatrix(); } }
class KDX extends SLayer{float d=6;int dd=-1;KDX(float x,float y,color c){super(x,y,c);} void upd(){d+=0.07*dd*gSpd;if(d>=6)dd=-1;else if(d<=2)dd=1;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); fill(cl); noStroke(); rotate(radians(45)); rect(0,0,KS/d,KS); rect(0,0,KS,KS/d); popMatrix(); popMatrix(); } }
class KMC extends SLayer{float r=0;float rs;KMC(float x,float y,color c){super(x,y,c);rs=random(1);} void upd(){r+=2.5*gSpd;} void ren(){ float[] sc=new float[1]; PVector off=new PVector(); waveSys.compute(px,py,sc,off); pushMatrix(); translate(off.x,off.y); pushMatrix(); noStroke(); fill(cl); rotate(radians(r)); float q=KS/4.3,h=KS/2.3; if(rs<0.33){ellipse(-q,-q,h,h);ellipse(q,q,h,h);ellipse(-q,q,h,h);ellipse(q,-q,h,h);} else if(rs<0.66){ellipse(-q,-q,h,h);ellipse(q,q,h,h);} else{ellipse(-q,q,h,h);ellipse(q,-q,h,h);} popMatrix(); popMatrix(); } }

// ============================================================
// 14. HELPERS GEOMÉTRICOS Y UTILIDADES
// ============================================================
void dStarH(float x,float y,float r1,float r2,int n){ float a=TWO_PI/n; beginShape(); for(float i=0;i<TWO_PI;i+=a){ vertex(x+cos(i-HALF_PI)*r1,y+sin(i-HALF_PI)*r1); vertex(x+cos(i-HALF_PI+a/2)*r2,y+sin(i-HALF_PI+a/2)*r2); } endShape(CLOSE); }
void dPolyH(float x,float y,float r,int n){ beginShape(); for(int i=0;i<n;i++){ float a=TWO_PI/n*i-HALF_PI; vertex(x+cos(a)*r,y+sin(a)*r); } endShape(CLOSE); }
void dHeartH(float s){ beginShape(); vertex(0,-s*0.25); bezierVertex(s*0.50,-s*0.80,s*1.15,-s*0.05,0,s*0.60); bezierVertex(-s*1.15,-s*0.05,-s*0.50,-s*0.80,0,-s*0.25); endShape(CLOSE); }
void dPlusH(float s){ float t=max(2,s*0.22); rect(0,0,t,s); rect(0,0,s,t); }
void dXCrossH(float s){ float t=max(2,s*0.20); pushMatrix(); rotate(QUARTER_PI); rect(0,0,t,s*1.15); rect(0,0,s*1.15,t); popMatrix(); }

color pP(){ return pal[(int)random(pal.length)]; }
void shufC(color[] a){ for(int i=a.length-1;i>0;i--){int j=(int)random(i+1);color t=a[i];a[i]=a[j];a[j]=t;} }
float easeIO(float x){ return x==0?0:x==1?1:x<0.5?pow(2,20*x-10)/2:(2-pow(2,-20*x+10))/2; }
void wrapXY(PVector p,float margin){ float b=BORDER_WIDTH; if(p.x<b) p.x=width-b; if(p.x>width-b) p.x=b; if(p.y<b) p.y=height-b; if(p.y>height-b) p.y=b; }

// ============================================================
// 15. OVERLAYS Y CONTROLES
// ============================================================
void drawGuideGrid(){ stroke(0,15); strokeWeight(0.4); float step=width/12.0; for(float i=0;i<=width;i+=step) line(i,0,i,height); for(float j=0;j<=height;j+=step) line(0,j,width,j); }
void displayInfo(){ fill(30,180); textAlign(LEFT,TOP); textSize(11); text("APEX 9.0 – SYMBIOSIS | Grid: "+GRID+"x"+GRID+" | Onda: "+waveSys.mode+" | Vel: "+nf(speedMultiplier,1,1)+"x", 30, 30); }

void keyPressed() {
  if (key == '1' || key == 'q' || key == 'Q') {
    SEED = (int)random(999999);
    seedValue = int(random(1, 9999999));
    randomSeed(SEED); noiseSeed(SEED);
    applyPatternPalette();
    buildAccentPalette();
    hilmaEng.seed = SEED; hilmaEng.build();
    buildBlocks(); buildGrain(); buildVignette(); buildGlowLayer();
    gridMgr.refreshCache();
    initKineticMotifs(); composeAPEX();
    println(">>> MUTACIÓN | Seed: " + SEED);
  }
  else if (key == '2') {
    for (int i = 0; i < BLOCKS; i++) for (int j = 0; j < BLOCKS; j++) bPal[i][j] = (bPal[i][j] + 1) % pairPalette.length;
    gridMgr.refreshCache();
  }
  else if (key == 'y' || key == 'Y') {
    waveSys.mode = (waveSys.mode + 1) % 5;
    gridMgr.refreshCache();
    println(">>> Modo Onda: " + waveSys.mode);
  }
  else if (key == 'h' || key == 'H') { gridMgr.toggleHilma(); }
  else if (key == 'm' || key == 'M') { MOTION = !MOTION; }
  else if (key == 'k' || key == 'K') { showKM = !showKM; }
  else if (key == 'b' || key == 'B') { showBR = !showBR; }
  else if (key == 'p' || key == 'P') { showParticles = !showParticles; }
  else if (key == 'g' || key == 'G') { showGrid = !showGrid; }
  else if (key == 's' || key == 'S') { saveFrame("apex_symbiosis_####.png"); println("Obra guardada."); }
  else if (key == 'v' || key == 'V') { vignetteOn = !vignetteOn; }
  else if (key == ' ') { paused = !paused; if (paused) noLoop(); else loop(); }
  else if (keyCode == UP || key == '+' || key == '=') { gridMgr.resize(GRID + 6); }
  else if (keyCode == DOWN || key == '-' || key == '_') { gridMgr.resize(GRID - 6); }
  else if (keyCode == RIGHT) { speedMultiplier = constrain(speedMultiplier + 0.2, 0.1, 4.0); gSpd = constrain(gSpd + 0.2, 0.2, 5.0); waveSys.speedMultiplier = speedMultiplier; }
  else if (keyCode == LEFT) { speedMultiplier = constrain(speedMultiplier - 0.2, 0.1, 4.0); gSpd = constrain(gSpd - 0.2, 0.2, 5.0); waveSys.speedMultiplier = speedMultiplier; }
}
