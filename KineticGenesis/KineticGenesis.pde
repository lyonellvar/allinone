/*
 * KINETIC GENESIS — NFT Generative Art System
 * Processing 4.3 — 1080x1080 P2D — 30fps
 *
 * Inspired by Refik Anadol, Ryoji Ikeda, Japanese digital masters.
 *
 * Controles:
 *   SPACE  → siguiente paleta
 *   p      → ciclar paleta (FIRE / ICE / COSMOS / NEON / EARTH)
 *   c      → aberración cromática (0 / 4 / 8 / 14 px)
 *   a      → toggle atractor de Clifford
 *   1      → toggle campo de interferencia
 *   2      → toggle nube de partículas
 *   3      → toggle Voronoi
 *   4      → toggle Lissajous
 *   5      → toggle data stream
 *   6      → toggle kinetic motifs
 *   i      → toggle HUD
 *   s      → guardar PNG
 *   r      → nueva semilla aleatoria
 */

// ── CONSTANTES ───────────────────────────────────────────────────────────────
final int   W  = 1080;
final int   H  = 1080;
final float CX = W / 2.0;
final float CY = H / 2.0;

// ── CAPAS PGraphics ──────────────────────────────────────────────────────────
PGraphics layerMain;
PGraphics layerBloom;
PGraphics layerTrails;
PGraphics layerAttr;

// ── ESTADO ───────────────────────────────────────────────────────────────────
float gt          = 0;
int   paletteIdx  = 0;
int   chromaIdx   = 1;

boolean showAttractor    = true;
boolean showInfo         = true;
boolean showInterference = true;
boolean showParticles    = true;
boolean showVoronoi      = true;
boolean showLissajous    = true;
boolean showDataStream   = true;
boolean showMotifs       = true;

final float[] CHROMA = {0, 4, 8, 14};

// ── SISTEMAS ─────────────────────────────────────────────────────────────────
FlowField         flowField;
ArrayList<Mote>   motes;
ArrayList<Petal>  petals;
ArrayList<Link>   links;
ArrayList<Poly>   polys;
ArrayList<Rings>  rings;
ArrayList<Orbit>  orbits;
ArrayList<KMotif> kMotifs;
RainGrid          rainGrid;

ParticleCloud     pCloud;
WaveGrid          waveGrid;
LissajousWeb      lisWeb;
VoronoiMesh       voronoi;
GlyphStream       glyphs;
CliffordAtr       clifford;

long sketchSeed;

// ============================================================================
//  SETUP
// ============================================================================
void setup() {
  size(1080, 1080, P2D);
  smooth(4);
  frameRate(30);
  rectMode(CORNER);
  textAlign(LEFT, TOP);

  sketchSeed = (long)random(1, 999999);
  randomSeed(sketchSeed);
  noiseSeed(sketchSeed);

  layerMain   = createGraphics(W, H, P2D);
  layerBloom  = createGraphics(W, H, P2D);
  layerTrails = createGraphics(W, H, P2D);
  layerAttr   = createGraphics(W, H, P2D);

  layerTrails.beginDraw(); layerTrails.background(0); layerTrails.endDraw();
  layerAttr.beginDraw();   layerAttr.background(0);   layerAttr.endDraw();

  rebuild();
}

void rebuild() {
  randomSeed(sketchSeed);
  noiseSeed(sketchSeed);

  flowField = new FlowField(48, 48);

  motes  = new ArrayList<Mote>();
  for (int i = 0; i < 180; i++) motes.add(new Mote());

  petals = new ArrayList<Petal>();
  for (int i = 0; i < 8; i++)
    petals.add(new Petal(random(W), random(H), random(55, 160)));

  links  = new ArrayList<Link>();
  for (int i = 0; i < 32; i++) links.add(new Link());

  polys  = new ArrayList<Poly>();
  for (int i = 0; i < 16; i++) polys.add(new Poly());

  rings  = new ArrayList<Rings>();
  for (int i = 0; i < 5; i++)
    rings.add(new Rings(random(W), random(H)));

  orbits = new ArrayList<Orbit>();
  for (int i = 0; i < 4; i++)
    orbits.add(new Orbit(CX, CY, random(80, 380)));

  kMotifs = new ArrayList<KMotif>();
  kMotifs.add(new MetatronKM(CX,    CY,    220));
  kMotifs.add(new TorusKM   (W*0.27, H*0.29, 140));
  kMotifs.add(new SpiralKM  (W*0.73, H*0.72, 160));
  kMotifs.add(new PolyRingKM(W*0.73, H*0.27, 120));
  kMotifs.add(new LatticeKM (W*0.27, H*0.73, 140));

  rainGrid = new RainGrid(50);

  pCloud   = new ParticleCloud(4000);
  waveGrid = new WaveGrid(60, 5);
  lisWeb   = new LissajousWeb(10);
  voronoi  = new VoronoiMesh(36, 50);
  glyphs   = new GlyphStream(72);
  clifford = new CliffordAtr(40000);

  layerTrails.beginDraw(); layerTrails.background(0); layerTrails.endDraw();
  layerAttr.beginDraw();   layerAttr.background(0);   layerAttr.endDraw();
}

// ============================================================================
//  DRAW
// ============================================================================
void draw() {
  gt += 0.01;
  flowField.update(gt);

  // ── trails layer ──────────────────────────────────────────────────────────
  layerTrails.beginDraw();
  layerTrails.noStroke();
  layerTrails.fill(0, 26);
  layerTrails.rect(0, 0, W, H);
  layerTrails.colorMode(HSB, 360, 100, 100, 255);
  for (Mote m : motes) { m.update(); m.trail(layerTrails); }
  if (showParticles) pCloud.trail(layerTrails, gt);
  layerTrails.endDraw();

  // ── attractor layer ────────────────────────────────────────────────────────
  if (showAttractor) {
    layerAttr.beginDraw();
    layerAttr.noStroke();
    layerAttr.fill(0, 8);
    layerAttr.rect(0, 0, W, H);
    clifford.render(layerAttr, gt);
    layerAttr.endDraw();
  }

  // ── main layer ────────────────────────────────────────────────────────────
  layerMain.beginDraw();
  layerMain.background(0);
  layerMain.colorMode(HSB, 360, 100, 100, 255);

  noiseField(layerMain, gt);
  if (showInterference) waveGrid.render(layerMain, gt);
  if (showVoronoi)      voronoi.render(layerMain, gt);

  for (Rings r  : rings)   { r.update();  r.draw(layerMain); }
  if (showMotifs)
    for (KMotif k : kMotifs) { k.update(gt); k.draw(layerMain); }
  for (Petal  p  : petals)  { p.update();  p.draw(layerMain); }
  for (Link   ln : links)   { ln.update(); ln.draw(layerMain, motes); }
  for (Poly   pl : polys)   { pl.update(); pl.draw(layerMain); }
  for (Orbit  o  : orbits)  { o.update();  o.draw(layerMain); }

  if (showLissajous)   lisWeb.render(layerMain, gt);
  if (showDataStream)  glyphs.render(layerMain, gt);
  else                 rainGrid.render(layerMain);

  layerMain.endDraw();

  // ── bloom layer ───────────────────────────────────────────────────────────
  layerBloom.beginDraw();
  layerBloom.background(0);
  layerBloom.blendMode(ADD);
  bloom(layerMain);
  layerBloom.endDraw();

  // ── composite ─────────────────────────────────────────────────────────────
  background(0);
  blendMode(ADD);
  image(layerTrails, 0, 0);
  if (showAttractor) image(layerAttr, 0, 0);
  blendMode(BLEND);
  chroma(layerMain, CHROMA[chromaIdx]);
  blendMode(SCREEN);
  image(layerBloom, 0, 0);
  blendMode(BLEND);
  if (showInfo) hud();
}

// ============================================================================
//  TECLADO
// ============================================================================
void keyPressed() {
  switch(key) {
    case 'p': paletteIdx  = (paletteIdx + 1) % 5;               break;
    case 'c': chromaIdx   = (chromaIdx  + 1) % CHROMA.length;   break;
    case 'a': showAttractor    = !showAttractor;    break;
    case '1': showInterference = !showInterference; break;
    case '2': showParticles    = !showParticles;    break;
    case '3': showVoronoi      = !showVoronoi;      break;
    case '4': showLissajous    = !showLissajous;    break;
    case '5': showDataStream   = !showDataStream;   break;
    case '6': showMotifs       = !showMotifs;       break;
    case 'i': showInfo         = !showInfo;         break;
    case 's': saveFrame("kinetic-genesis-####.png"); println("Saved."); break;
    case 'r':
      sketchSeed = (long)random(1, 999999);
      rebuild();
      break;
    case ' ':
      paletteIdx = (paletteIdx + 1) % 5;
      break;
  }
}

// ============================================================================
//  UTILIDADES GLOBALES
// ============================================================================

// Paleta coseno: 5 presets (FIRE / ICE / COSMOS / NEON / EARTH)
color pal(float t) {
  final float[][] A = {{.5,.3,.1},{.2,.4,.6},{.3,.2,.5},{.5,.5,.5},{.4,.35,.2}};
  final float[][] B = {{.5,.4,.1},{.3,.4,.4},{.4,.3,.5},{.5,.5,.5},{.3,.3,.2}};
  final float[][] C = {{1,1,1},{1,1,.8},{1,1,1.5},{2,1.5,1},{1,.8,.6}};
  final float[][] D = {{.0,.1,.2},{.5,.6,.7},{.8,.9,.3},{.0,.33,.67},{.2,.25,.3}};
  int p = paletteIdx % 5;
  float r = A[p][0] + B[p][0]*cos(TWO_PI*(C[p][0]*t + D[p][0]));
  float g = A[p][1] + B[p][1]*cos(TWO_PI*(C[p][1]*t + D[p][1]));
  float b = A[p][2] + B[p][2]*cos(TWO_PI*(C[p][2]*t + D[p][2]));
  return color(constrain(r,0,1)*255, constrain(g,0,1)*255, constrain(b,0,1)*255);
}

// Suma de 5 frentes de onda → valor en -1..1
float mwave(float x, float y, float t) {
  final float[][] S = {
    {W*.25,H*.25,.020,0.0},{W*.75,H*.30,.030,1.3},
    {W*.50,H*.70,.015,2.1},{W*.20,H*.80,.036,3.7},
    {W*.85,H*.85,.025,5.2}
  };
  float s = 0;
  for (int i = 0; i < 5; i++)
    s += sin(dist(x,y,S[i][0],S[i][1]) * S[i][2] - t*2.0 + S[i][3]);
  return s / 5.0;
}

// Campo de color Perlin como underlay
void noiseField(PGraphics g, float t) {
  final int C = 30;
  final float cs = (float)W / C;
  g.noStroke(); g.colorMode(RGB, 255);
  for (int i = 0; i < C; i++) {
    for (int j = 0; j < C; j++) {
      float n = noise(i*.2, j*.2, t*.35);
      color c = pal(n + t*.04);
      g.fill(red(c), green(c), blue(c), 16);
      g.rect(i*cs, j*cs, cs+1, cs+1);
    }
  }
  g.colorMode(HSB, 360, 100, 100, 255);
}

// Bloom: src escalado a mayor tamaño con alpha bajo → halo suave
void bloom(PGraphics src) {
  final float[] sc = {1.02, 1.04, 1.06};
  final float[] al = {45,   28,   16  };
  layerBloom.imageMode(CENTER);
  for (int i = 0; i < 3; i++) {
    layerBloom.tint(255, al[i]);
    layerBloom.image(src, W*.5, H*.5, W*sc[i], H*sc[i]);
  }
  layerBloom.noTint();
  layerBloom.imageMode(CORNER);
}

// Aberración cromática: separa canales R G B horizontalmente
void chroma(PGraphics src, float amt) {
  if (amt < 0.001) { image(src, 0, 0); return; }
  blendMode(ADD);
  tint(255,   0,   0, 255); image(src, -amt, 0);
  tint(  0, 255,   0, 255); image(src,    0, 0);
  tint(  0,   0, 255, 255); image(src,  amt, 0);
  noTint();
  blendMode(BLEND);
}

// HUD informativo
void hud() {
  final String[] PAL = {"FIRE","ICE","COSMOS","NEON","EARTH"};
  pushStyle();
  rectMode(CORNER);
  noStroke(); fill(0, 170);
  rect(14, 14, 360, 256, 10);
  fill(255); textSize(17);
  text("KINETIC GENESIS  seed:" + sketchSeed, 28, 24);
  textSize(13);
  float y = 58;
  text("fps:" + nf(frameRate,0,1) + "  palette[p]:" + PAL[paletteIdx], 28, y); y+=20;
  text("chroma[c]:" + nf(CHROMA[chromaIdx],0,0) + "px", 28, y); y+=20;
  text("[a]attractor:"   + tf(showAttractor),    28, y); y+=20;
  text("[1]interference:" + tf(showInterference), 28, y); y+=20;
  text("[2]particles:"   + tf(showParticles),    28, y); y+=20;
  text("[3]voronoi:"     + tf(showVoronoi),       28, y); y+=20;
  text("[4]lissajous:"   + tf(showLissajous),    28, y); y+=20;
  text("[5]datastream:"  + tf(showDataStream),   28, y); y+=20;
  text("[6]motifs:"      + tf(showMotifs) + "  [i]hud [s]save [r]regen", 28, y);
  popStyle();
}
String tf(boolean v) { return v ? "ON" : "off"; }

// ============================================================================
//  FLOW FIELD
// ============================================================================
class FlowField {
  int cols, rows;
  PVector[][] f;
  float cw, ch;
  FlowField(int cols, int rows) {
    this.cols = cols; this.rows = rows;
    cw = (float)W/cols; ch = (float)H/rows;
    f  = new PVector[cols][rows];
  }
  void update(float t) {
    for (int i = 0; i < cols; i++)
      for (int j = 0; j < rows; j++)
        f[i][j] = PVector.fromAngle(noise(i*.07, j*.07, t*.5) * TWO_PI * 2);
  }
  PVector at(float x, float y) {
    int i = constrain((int)(x/cw), 0, cols-1);
    int j = constrain((int)(y/ch), 0, rows-1);
    return f[i][j].copy();
  }
}

// ============================================================================
//  MOTE — partícula guiada por flow field, con trail HSB
// ============================================================================
class Mote {
  PVector pos, prv, vel;
  float   spd, hue;
  Mote() { reset(); prv = pos.copy(); }
  void reset() {
    pos = new PVector(random(W), random(H));
    vel = new PVector();
    spd = random(1.5, 5);
    hue = random(360);
  }
  void update() {
    prv = pos.copy();
    PVector ff = flowField.at(pos.x, pos.y); ff.mult(.5);
    vel.add(ff); vel.limit(spd); pos.add(vel);
    if (pos.x<0||pos.x>W||pos.y<0||pos.y>H) { reset(); prv=pos.copy(); }
    hue = (hue + .4) % 360;
  }
  void trail(PGraphics g) {
    g.stroke(hue, 70, 95, 85); g.strokeWeight(1.3);
    g.line(prv.x, prv.y, pos.x, pos.y);
  }
}

// ============================================================================
//  PETAL — mandala de pétalos rotante
// ============================================================================
class Petal {
  float x, y, r, rot, spd, hue;
  int   n;
  Petal(float x, float y, float r) {
    this.x=x; this.y=y; this.r=r;
    n=  (int)random(6,14);
    spd = random(-.012,.012);
    hue = random(360);
  }
  void update() { rot+=spd; hue=(hue+.2)%360; }
  void draw(PGraphics g) {
    g.pushMatrix(); g.translate(x,y); g.rotate(rot);
    g.noFill(); g.strokeWeight(1.6);
    for (int i=0;i<n;i++) {
      g.stroke((hue+i*14)%360, 80, 95, 115);
      g.pushMatrix(); g.rotate(TWO_PI*i/n);
      g.ellipse(r*.5, 0, r, r*.38);
      g.popMatrix();
    }
    g.popMatrix();
  }
}

// ============================================================================
//  LINK — arista entre motes cercanos
// ============================================================================
class Link {
  int   idx;
  float maxD;
  Link() { idx=(int)random(1000); maxD=random(90,200); }
  void update() { idx++; }
  void draw(PGraphics g, ArrayList<Mote> ms) {
    if (ms.size()<2) return;
    Mote a = ms.get(idx % ms.size());
    for (int k=0;k<5;k++) {
      Mote b = ms.get((idx+k*7+1) % ms.size());
      float d = PVector.dist(a.pos, b.pos);
      if (d < maxD) {
        g.stroke(a.hue, 50, 100, map(d,0,maxD,75,0));
        g.strokeWeight(.7);
        g.line(a.pos.x, a.pos.y, b.pos.x, b.pos.y);
      }
    }
  }
}

// ============================================================================
//  POLY — polígono pulsante con outline
// ============================================================================
class Poly {
  float x, y, r, rot, spd, hue, ph;
  int   sides;
  Poly() {
    x=random(W); y=random(H); r=random(28,110);
    sides=(int)random(3,9); spd=random(-.018,.018);
    hue=random(360); ph=random(TWO_PI);
  }
  void update() { rot+=spd; ph+=.038; hue=(hue+.25)%360; }
  void draw(PGraphics g) {
    float rr = r*(1+.18*sin(ph));
    g.pushMatrix(); g.translate(x,y); g.rotate(rot);
    g.noFill(); g.strokeWeight(2); g.stroke(hue,85,100,140);
    g.beginShape();
    for (int i=0;i<sides;i++) {
      float a=TWO_PI*i/sides;
      g.vertex(cos(a)*rr, sin(a)*rr);
    }
    g.endShape(CLOSE);
    g.popMatrix();
  }
}

// ============================================================================
//  RINGS — anillos concéntricos contra-rotantes
// ============================================================================
class Rings {
  float x, y, base, rot, hue;
  int   n;
  Rings(float x, float y) {
    this.x=x; this.y=y;
    base=random(55,180); n=(int)random(4,8); hue=random(360);
  }
  void update() { rot+=.005; hue=(hue+.12)%360; }
  void draw(PGraphics g) {
    g.pushMatrix(); g.translate(x,y); g.noFill();
    for (int i=0;i<n;i++) {
      float rr=base*(i+1.0)/n; int seg=6+i;
      g.stroke((hue+i*22)%360, 70, 95, 85); g.strokeWeight(1.3);
      g.pushMatrix(); g.rotate(rot*(i%2==0?1:-1)*(i+1));
      g.beginShape();
      for (int k=0;k<=seg;k++) { float a=TWO_PI*k/seg; g.vertex(cos(a)*rr,sin(a)*rr); }
      g.endShape();
      g.popMatrix();
    }
    g.popMatrix();
  }
}

// ============================================================================
//  ORBIT — cuerpos orbitando un centro
// ============================================================================
class Orbit {
  float cx, cy, radius, ang, spd, hue, sz;
  Orbit(float cx, float cy, float r) {
    this.cx=cx; this.cy=cy; this.radius=r;
    ang=random(TWO_PI); spd=random(.005,.018)*(random(1)<.5?1:-1);
    hue=random(360); sz=random(6,20);
  }
  void update() { ang+=spd; hue=(hue+.4)%360; }
  void draw(PGraphics g) {
    float x=cx+cos(ang)*radius, y=cy+sin(ang)*radius;
    g.noStroke(); g.fill(hue,80,100,175); g.ellipse(x,y,sz,sz);
    g.noFill(); g.stroke(hue,28,100,55); g.strokeWeight(.5);
    g.ellipse(cx,cy,radius*2,radius*2);
  }
}

// ============================================================================
//  KINETIC MOTIFS
// ============================================================================
abstract class KMotif {
  float x, y, r, rot, hue;
  KMotif(float x, float y, float r) { this.x=x;this.y=y;this.r=r;hue=random(360); }
  abstract void update(float t);
  abstract void draw(PGraphics g);
}

class MetatronKM extends KMotif {
  PVector[] nd;
  MetatronKM(float x, float y, float r) {
    super(x,y,r);
    nd = new PVector[13];
    nd[0] = new PVector(0,0);
    for (int i=0;i<6;i++) { float a=TWO_PI*i/6; nd[1+i]=new PVector(cos(a)*r*.5,sin(a)*r*.5); }
    for (int i=0;i<6;i++) { float a=TWO_PI*i/6+PI/6; nd[7+i]=new PVector(cos(a)*r,sin(a)*r); }
  }
  void update(float t) { rot+=.003; hue=(hue+.1)%360; }
  void draw(PGraphics g) {
    g.pushMatrix(); g.translate(x,y); g.rotate(rot); g.strokeWeight(.9);
    for (int i=0;i<nd.length;i++)
      for (int j=i+1;j<nd.length;j++) {
        g.stroke((hue+(i+j)*4)%360,60,95,45);
        g.line(nd[i].x,nd[i].y,nd[j].x,nd[j].y);
      }
    g.noStroke();
    for (PVector v:nd) { g.fill(hue,70,100,190); g.ellipse(v.x,v.y,6,6); }
    g.popMatrix();
  }
}

class TorusKM extends KMotif {
  TorusKM(float x,float y,float r){super(x,y,r);}
  void update(float t){rot+=.009;hue=(hue+.18)%360;}
  void draw(PGraphics g){
    g.pushMatrix();g.translate(x,y);g.noFill();g.strokeWeight(1.1);
    for(int i=0;i<20;i++){
      float a=TWO_PI*i/20+rot;
      g.stroke((hue+i*9)%360,75,95,115);
      g.ellipse(cos(a)*r*.38,sin(a)*r*.14,r,r*.48);
    }
    g.popMatrix();
  }
}

class SpiralKM extends KMotif {
  SpiralKM(float x,float y,float r){super(x,y,r);}
  void update(float t){rot+=.011;hue=(hue+.22)%360;}
  void draw(PGraphics g){
    g.pushMatrix();g.translate(x,y);g.rotate(rot);
    g.noFill();g.strokeWeight(1.8);
    g.beginShape();
    for(float a=0;a<TWO_PI*5;a+=.12){
      float rr=r*.022*a*exp(a*.038);
      if(rr>r)break;
      g.stroke((hue+degrees(a)*.28)%360,85,100,145);
      g.vertex(cos(a)*rr,sin(a)*rr);
    }
    g.endShape();
    g.popMatrix();
  }
}

class PolyRingKM extends KMotif {
  PolyRingKM(float x,float y,float r){super(x,y,r);}
  void update(float t){rot+=.007;hue=(hue+.16)%360;}
  void draw(PGraphics g){
    g.pushMatrix();g.translate(x,y);g.noFill();g.strokeWeight(1.5);
    for(int i=0;i<6;i++){
      int sd=3+i; float rr=r*(i+1)/6;
      g.stroke((hue+i*18)%360,80,95,125);
      g.pushMatrix();g.rotate(rot*(i%2==0?1:-1));
      g.beginShape();
      for(int k=0;k<sd;k++){float a=TWO_PI*k/sd;g.vertex(cos(a)*rr,sin(a)*rr);}
      g.endShape(CLOSE);
      g.popMatrix();
    }
    g.popMatrix();
  }
}

class LatticeKM extends KMotif {
  final int N=10;
  LatticeKM(float x,float y,float r){super(x,y,r);}
  void update(float t){rot=t;hue=(hue+.1)%360;}
  void draw(PGraphics g){
    g.pushMatrix();g.translate(x-r,y-r);g.strokeWeight(1.1);
    float step=(r*2)/N;
    for(int i=0;i<=N;i++)
      for(int j=0;j<=N;j++){
        float off=mwave(x-r+i*step,y-r+j*step,rot)*8;
        g.stroke((hue+(i+j)*5)%360,70,95,115);
        g.point(i*step+off,j*step+off);
        if(i<N)g.line(i*step,j*step,(i+1)*step,j*step);
        if(j<N)g.line(i*step,j*step,i*step,(j+1)*step);
      }
    g.popMatrix();
  }
}

// ============================================================================
//  RAIN GRID — lluvia binaria de fallback
// ============================================================================
class RainDrop {
  float x,y,spd,sz;
  int   len;
  char[]cs;
  float hue;
  RainDrop(float x){
    this.x=x; y=random(-H,0); spd=random(4,14); sz=random(11,20);
    len=(int)random(6,22); hue=random(110,160);
    cs=new char[len];
    for(int i=0;i<len;i++)cs[i]=random(1)<.5?'0':'1';
  }
  void update(){
    y+=spd;
    if(y-len*sz>H){y=random(-H*.5,0);spd=random(4,14);for(int i=0;i<len;i++)cs[i]=random(1)<.5?'0':'1';}
    if(random(1)<.1)cs[(int)random(len)]=random(1)<.5?'0':'1';
  }
  void draw(PGraphics g){
    g.textAlign(CENTER,CENTER);g.textSize(sz);
    for(int i=0;i<len;i++){
      float yy=y-i*sz;
      if(yy<0||yy>H)continue;
      g.fill(i==0?color(hue,20,100,255):color(hue,80,map(i,0,len,100,10),200));
      g.text(cs[i],x,yy);
    }
  }
}
class RainGrid {
  ArrayList<RainDrop> drops;
  RainGrid(int n){
    drops=new ArrayList<RainDrop>();
    float gap=(float)W/n;
    for(int i=0;i<n;i++)drops.add(new RainDrop(i*gap+gap*.5));
  }
  void render(PGraphics g){for(RainDrop d:drops){d.update();d.draw(g);}}
}

// ============================================================================
//  PARTICLE CLOUD — Anadol-style data materialization (float arrays)
// ============================================================================
class ParticleCloud {
  final int N;
  float[]px,py,vx,vy,ppx,ppy,col;
  final int AC = 180;
  float[]ax,ay,tax,tay;
  int   shape=0;
  float morph=0;
  final float MS=.005;

  ParticleCloud(int n){
    N=n;
    px=new float[N];py=new float[N];vx=new float[N];vy=new float[N];
    ppx=new float[N];ppy=new float[N];col=new float[N];
    for(int i=0;i<N;i++){px[i]=random(W);py[i]=random(H);ppx[i]=px[i];ppy[i]=py[i];col[i]=random(360);}
    ax=new float[AC];ay=new float[AC];tax=new float[AC];tay=new float[AC];
    buildShape(0,ax,ay);buildShape(1,tax,tay);
  }

  void buildShape(int s,float[]xs,float[]ys){
    switch(s%4){
      case 0: for(int i=0;i<AC;i++){float a=TWO_PI*i/AC,r=W*.32;xs[i]=CX+cos(a)*r;ys[i]=CY+sin(a)*r;}break;
      case 1: int sd=(int)sqrt(AC);float gp=W*.55/sd,o=W*.22;for(int i=0;i<AC;i++){xs[i]=o+(i%sd)*gp;ys[i]=o+(i/sd)*gp;}break;
      case 2: for(int i=0;i<AC;i++){float a=.4*i,r=W*.0014*i;xs[i]=CX+cos(a)*r;ys[i]=CY+sin(a)*r;}break;
      default:for(int i=0;i<AC;i++){float tt=(float)i/AC*6;int e=(int)tt;float f=tt-e,a0=TWO_PI*e/6,a1=TWO_PI*(e+1)/6,r=W*.30;xs[i]=lerp(CX+cos(a0)*r,CX+cos(a1)*r,f);ys[i]=lerp(CY+sin(a0)*r,CY+sin(a1)*r,f);}break;
    }
  }

  void trail(PGraphics g,float t){
    morph+=MS;
    if(morph>=1){morph=0;shape=(shape+1)%4;for(int i=0;i<AC;i++){ax[i]=tax[i];ay[i]=tay[i];}buildShape(shape+1,tax,tay);}
    g.strokeWeight(1.1);
    for(int i=0;i<N;i++){
      int ai=i%AC;
      float axp=lerp(ax[ai],tax[ai],morph),ayp=lerp(ay[ai],tay[ai],morph);
      float dx=axp-px[i],dy=ayp-py[i];
      float d=sqrt(dx*dx+dy*dy)+.0001;
      vx[i]+=(dx/d)*.055;vy[i]+=(dy/d)*.055;
      float an=noise(px[i]*.0012,py[i]*.0012,t*.3)*TWO_PI*2;
      vx[i]+=cos(an)*.35;vy[i]+=sin(an)*.35;
      vx[i]*=.92;vy[i]*=.92;
      ppx[i]=px[i];ppy[i]=py[i];px[i]+=vx[i];py[i]+=vy[i];
      float sp=sqrt(vx[i]*vx[i]+vy[i]*vy[i]);
      float h=(col[i]+sp*28+t*10)%360;
      float al=constrain(map(d,0,300,135,6),6,135);
      g.stroke(h,80,map(sp,0,5,50,100),al);
      g.line(ppx[i],ppy[i],px[i],py[i]);
    }
  }
}

// ============================================================================
//  WAVE GRID — campo de interferencia estilo Ikeda
// ============================================================================
class WaveGrid {
  int   grid,src;
  float[]sx,sy,sfx,sfy,sax,say,sph;
  float cell;
  WaveGrid(int grid,int src){
    this.grid=grid;this.src=src;cell=(float)W/grid;
    sx=new float[src];sy=new float[src];sfx=new float[src];sfy=new float[src];
    sax=new float[src];say=new float[src];sph=new float[src];
    for(int i=0;i<src;i++){sfx[i]=random(.3,1.3);sfy[i]=random(.3,1.3);sax[i]=random(W*.18,W*.38);say[i]=random(H*.18,H*.38);sph[i]=random(TWO_PI);}
  }
  void render(PGraphics g,float t){
    for(int i=0;i<src;i++){sx[i]=CX+sin(t*sfx[i]+sph[i])*sax[i];sy[i]=CY+cos(t*sfy[i]+sph[i])*say[i];}
    g.noStroke();
    for(int i=0;i<grid;i++) for(int j=0;j<grid;j++){
      float x=i*cell+cell*.5,y=j*cell+cell*.5,sum=0;
      for(int s=0;s<src;s++)sum+=sin(dist(x,y,sx[s],sy[s])*.035-t*2);
      float b=map(sum,-src,src,0,100);
      if(b<34)continue;
      color c=pal(b/100+t*.05);
      g.colorMode(RGB,255);g.fill(red(c),green(c),blue(c),map(b,34,100,28,155));
      g.rect(x-cell*.34,y-cell*.34,cell*.68,cell*.68);
      g.colorMode(HSB,360,100,100,255);
    }
  }
}

// ============================================================================
//  LISSAJOUS WEB — 10 curvas Lissajous animadas
// ============================================================================
class LissajousWeb {
  int n;
  float[]axB,ayB,ph,sc;
  LissajousWeb(int n){
    this.n=n;axB=new float[n];ayB=new float[n];ph=new float[n];sc=new float[n];
    for(int i=0;i<n;i++){axB[i]=(int)random(1,7);ayB[i]=(int)random(1,7);ph[i]=random(TWO_PI);sc[i]=W*.5*map(i,0,n,.28,.92);}
  }
  void render(PGraphics g,float t){
    g.pushMatrix();g.translate(CX,CY);g.noFill();
    for(int i=0;i<n;i++){
      float ax=axB[i]+sin(t*.1+i)*.5,ay=ayB[i]+cos(t*.13+i)*.5;
      color c=pal((float)i/n+t*.04);
      g.colorMode(RGB,255);g.strokeWeight(2.2);g.stroke(red(c),green(c),blue(c),65);
      g.beginShape();
      for(float a=0;a<=TWO_PI;a+=.022)
        g.vertex(sin(ax*a+ph[i]+t*.2)*sc[i],sin(ay*a)*sc[i]);
      g.endShape();
      g.colorMode(HSB,360,100,100,255);
    }
    g.popMatrix();
  }
}

// ============================================================================
//  VORONOI MESH — celdas pulsantes con bordes luminosos
// ============================================================================
class VoronoiMesh {
  int seeds,grid;
  float[]sx,sy,svx,svy,sh,sp;
  float cell;
  VoronoiMesh(int seeds,int grid){
    this.seeds=seeds;this.grid=grid;cell=(float)W/grid;
    sx=new float[seeds];sy=new float[seeds];svx=new float[seeds];svy=new float[seeds];
    sh=new float[seeds];sp=new float[seeds];
    for(int i=0;i<seeds;i++){sx[i]=random(W);sy[i]=random(H);svx[i]=random(-.5,.5);svy[i]=random(-.5,.5);sh[i]=random(360);sp[i]=random(TWO_PI);}
  }
  void render(PGraphics g,float t){
    for(int i=0;i<seeds;i++){
      sx[i]+=svx[i];sy[i]+=svy[i];
      if(sx[i]<0||sx[i]>W)svx[i]*=-1;if(sy[i]<0||sy[i]>H)svy[i]*=-1;
      sp[i]+=.028;
    }
    g.noStroke();
    for(int i=0;i<grid;i++) for(int j=0;j<grid;j++){
      float x=i*cell+cell*.5,y=j*cell+cell*.5;
      int best=-1;float bD=Float.MAX_VALUE,s2=Float.MAX_VALUE;
      for(int s=0;s<seeds;s++){
        float p=1+.28*sin(sp[s]),dx=x-sx[s],dy=y-sy[s],d=(dx*dx+dy*dy)/(p*p);
        if(d<bD){s2=bD;bD=d;best=s;}else if(d<s2)s2=d;
      }
      if(best<0)continue;
      boolean edge=sqrt(s2)-sqrt(bD)<7;
      float gr=constrain(map(sqrt(bD),0,550,55,7),6,55);
      g.fill(sh[best],70,78,gr*.5);g.rect(i*cell,j*cell,cell+1,cell+1);
      if(edge){g.fill(sh[best],18,100,65);g.rect(i*cell,j*cell,cell+1,cell+1);}
    }
  }
}

// ============================================================================
//  GLYPH STREAM — lluvia de binario + katakana + símbolos matemáticos
// ============================================================================
class GlyphStream {
  int n;
  float[]x,y,spd,drift,sz,hue;
  int[]len,dir;
  char[][]gl;
  final String CH = "01ABCDEFアイウエオカキクケコ∑∏∂∇∞∫≈≠±";

  GlyphStream(int n){
    this.n=n;
    x=new float[n];y=new float[n];spd=new float[n];drift=new float[n];
    sz=new float[n];hue=new float[n];len=new int[n];dir=new int[n];gl=new char[n][];
    float gap=(float)W/n;
    for(int i=0;i<n;i++)init(i,i*gap+gap*.5);
  }
  void init(int i,float xp){
    x[i]=xp;y[i]=random(-H,0);spd[i]=random(4,16);sz[i]=random(13,26);
    len[i]=(int)random(7,24);dir[i]=(int)random(3);
    drift[i]=dir[i]==1?random(-1.4,-.3):dir[i]==2?random(.3,1.4):0;
    hue[i]=random(1)<.6?random(145,200):random(275,320);
    gl[i]=new char[len[i]];
    for(int k=0;k<len[i];k++)gl[i][k]=CH.charAt((int)random(CH.length()));
  }
  void render(PGraphics g,float t){
    g.textAlign(CENTER,CENTER);g.colorMode(HSB,360,100,100,255);
    for(int i=0;i<n;i++){
      y[i]+=spd[i];x[i]+=drift[i];
      if(y[i]-len[i]*sz[i]>H||x[i]<-40||x[i]>W+40)init(i,random(W));
      if(random(1)<.08)gl[i][(int)random(len[i])]=CH.charAt((int)random(CH.length()));
      g.textSize(sz[i]);
      for(int k=0;k<len[i];k++){
        float yy=y[i]-k*sz[i],xx=x[i]-k*drift[i]*.55;
        if(yy<-28||yy>H+28)continue;
        g.fill(k==0?color(hue[i],14,100,255):color(hue[i],84,map(k,0,len[i],100,8),205));
        g.text(gl[i][k],xx,yy);
      }
    }
  }
}

// ============================================================================
//  CLIFFORD ATTRACTOR — Strange attractor con morphing de parámetros
// ============================================================================
class CliffordAtr {
  int   itr;
  float a,b,c,d,ta,tb,tc,td,mt=0;
  CliffordAtr(int itr){
    this.itr=itr;
    rnd();a=ta;b=tb;c=tc;d=td;rnd();
  }
  void rnd(){ta=random(-2,2);tb=random(-2,2);tc=random(-2,2);td=random(-2,2);}
  void render(PGraphics g,float t){
    mt+=.003;
    if(mt>=1){mt=0;a=ta;b=tb;c=tc;d=td;rnd();}
    float ca=lerp(a,ta,mt),cb=lerp(b,tb,mt),cc=lerp(c,tc,mt),cd=lerp(d,td,mt);
    g.pushMatrix();g.translate(CX,CY);g.rotate(t*.018);
    float scl=W*.2;
    g.colorMode(HSB,360,100,100,255);g.strokeWeight(1.8);
    float x=0,y=0;
    for(int i=0;i<itr;i++){
      float nx=sin(ca*y)+cc*cos(ca*x);
      float ny=sin(cb*x)+cd*cos(cb*y);
      float v=dist(x,y,nx,ny);
      x=nx;y=ny;
      g.stroke((map(v,0,4,175,355)+t*18)%360,80,100,55);
      g.point(x*scl,y*scl);
    }
    g.popMatrix();
  }
}
