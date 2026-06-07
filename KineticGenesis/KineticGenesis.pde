/* ============================================================================
 * KINETIC GENESIS  —  Generative Art NFT System (Processing 4.3)
 * Enhanced edition: multi-layer compositing, bloom, chromatic aberration,
 * particle clouds, interference fields, Lissajous, Voronoi, data streams,
 * strange attractors, multi-source waves and cosine HSB palettes.
 *
 * Inspired by Refik Anadol, Ryoji Ikeda and Japanese digital-art masters.
 * Canvas 1800x1800, P2D, 30fps.
 * ============================================================================ */

// ---------------------------------------------------------------------------
// GLOBAL VARIABLES
// ---------------------------------------------------------------------------
final int CANVAS = 1800;
final int FR = 30;

// Compositing layers
PGraphics layerMain;    // primary rendering
PGraphics layerBloom;   // bloom / glow accumulation
PGraphics layerTrails;  // motion trails with fade
PGraphics layerChroma;  // chromatic aberration target
PGraphics layerAttr;    // persistent strange-attractor accumulation

// Time / state
float gt = 0;                 // global animation time
int patternIndex = 0;        // selects palette + behaviours
int paletteIndex = 0;        // active cosine palette (0..4)
int chromaLevel = 1;         // 0..3 -> aberration amount
boolean showAttractor = true;
boolean showInfo = true;
boolean showInterference = true;
boolean showParticles = true;
boolean showVoronoi = true;
boolean showLissajous = true;
boolean showDataStream = true;
boolean showMotifs = true;

float[] chromaAmounts = {0, 4, 8, 14};

// Core kinetic systems (original)
Flow flow;
ArrayList<Motion> motions;
ArrayList<Flower> flowers;
ArrayList<Connector> connectors;
ArrayList<VibrantShape> vibrantShapes;
ArrayList<ComplexGeometry> geometries;
ArrayList<OrbitingElement> orbiters;
ArrayList<KineticMotif> motifs;
BinaryRain binaryRain;

// New systems
ParticleCloud particleCloud;
InterferenceField interference;
LissajousSystem lissajous;
VoronoiPulse voronoi;
DataStream dataStream;
AttractorTracer attractor;

// Random seed for reproducible NFT
long sketchSeed = 0;

// ---------------------------------------------------------------------------
// SETUP / DRAW
// ---------------------------------------------------------------------------
void settings() {
  size(CANVAS, CANVAS, P2D);
  smooth(4);
}

void setup() {
  frameRate(FR);
  sketchSeed = (long)random(1, 999999);
  randomSeed(sketchSeed);
  noiseSeed(sketchSeed);

  layerMain   = createGraphics(CANVAS, CANVAS, P2D);
  layerBloom  = createGraphics(CANVAS, CANVAS, P2D);
  layerTrails = createGraphics(CANVAS, CANVAS, P2D);
  layerChroma = createGraphics(CANVAS, CANVAS, P2D);
  layerAttr   = createGraphics(CANVAS, CANVAS, P2D);

  layerTrails.beginDraw(); layerTrails.background(0); layerTrails.endDraw();
  layerAttr.beginDraw();   layerAttr.background(0);   layerAttr.endDraw();

  flow = new Flow(64, 64, 0.0016);

  // Original systems
  motions = new ArrayList<Motion>();
  for (int i = 0; i < 220; i++) motions.add(new Motion());

  flowers = new ArrayList<Flower>();
  for (int i = 0; i < 9; i++)
    flowers.add(new Flower(random(CANVAS), random(CANVAS), random(80, 240)));

  connectors = new ArrayList<Connector>();
  for (int i = 0; i < 40; i++) connectors.add(new Connector());

  vibrantShapes = new ArrayList<VibrantShape>();
  for (int i = 0; i < 18; i++) vibrantShapes.add(new VibrantShape());

  geometries = new ArrayList<ComplexGeometry>();
  for (int i = 0; i < 6; i++)
    geometries.add(new ComplexGeometry(random(CANVAS), random(CANVAS)));

  orbiters = new ArrayList<OrbitingElement>();
  for (int i = 0; i < 5; i++)
    orbiters.add(new OrbitingElement(CANVAS*0.5, CANVAS*0.5, random(120, 600)));

  binaryRain = new BinaryRain(70);

  // Kinetic Motifs (sacred-geometry shape family)
  motifs = new ArrayList<KineticMotif>();
  motifs.add(new MetatronMotif(CANVAS*0.5, CANVAS*0.5, 360));
  motifs.add(new TorusMotif(CANVAS*0.28, CANVAS*0.30, 220));
  motifs.add(new SpiralMotif(CANVAS*0.74, CANVAS*0.72, 260));
  motifs.add(new PolygonRingMotif(CANVAS*0.74, CANVAS*0.28, 200));
  motifs.add(new GridLatticeMotif(CANVAS*0.26, CANVAS*0.74, 240));

  // New systems
  particleCloud = new ParticleCloud(6000);
  interference  = new InterferenceField(80, 5);
  lissajous     = new LissajousSystem(12);
  voronoi       = new VoronoiPulse(40, 60);
  dataStream    = new DataStream(96);
  attractor     = new AttractorTracer(50000);

  background(0);
}

void draw() {
  gt += 0.01;
  flow.update(gt);

  // ---- TRAILS LAYER (fades previous frame, draws motion paths) ----
  layerTrails.beginDraw();
  layerTrails.noStroke();
  layerTrails.fill(0, 26);                 // gentle fade -> persistence
  layerTrails.rect(0, 0, CANVAS, CANVAS);
  layerTrails.colorMode(HSB, 360, 100, 100, 255);
  for (Motion m : motions) { m.update(); m.drawTrail(layerTrails); }
  if (showParticles) particleCloud.drawTrails(layerTrails, gt);
  layerTrails.endDraw();

  // ---- ATTRACTOR LAYER (slow persistent accumulation) ----
  if (showAttractor) {
    layerAttr.beginDraw();
    layerAttr.noStroke();
    layerAttr.fill(0, 8);                   // very slow fade
    layerAttr.rect(0, 0, CANVAS, CANVAS);
    attractor.render(layerAttr, gt);
    layerAttr.endDraw();
  }

  // ---- MAIN LAYER ----
  layerMain.beginDraw();
  layerMain.background(0);
  layerMain.colorMode(HSB, 360, 100, 100, 255);

  // subtle perlin noise color field underlay
  drawNoiseColorField(layerMain, gt);

  // interference field (Ikeda)
  if (showInterference) interference.render(layerMain, gt);

  // voronoi cellular pulse
  if (showVoronoi) voronoi.render(layerMain, gt);

  // original geometry / motifs
  for (ComplexGeometry g : geometries) { g.update(); g.display(layerMain); }
  if (showMotifs) for (KineticMotif km : motifs) { km.update(gt); km.display(layerMain); }
  for (Flower f : flowers) { f.update(); f.display(layerMain); }
  for (Connector c : connectors) { c.update(); c.display(layerMain, motions); }
  for (VibrantShape v : vibrantShapes) { v.update(); v.display(layerMain); }
  for (OrbitingElement o : orbiters) { o.update(); o.display(layerMain); }

  // lissajous curves
  if (showLissajous) lissajous.render(layerMain, gt);

  // data stream (katakana/hex/math)
  if (showDataStream) dataStream.render(layerMain, gt);
  else binaryRain.update_display(layerMain);

  layerMain.endDraw();

  // ---- BLOOM LAYER (built from main bright content) ----
  layerBloom.beginDraw();
  layerBloom.background(0);
  layerBloom.blendMode(ADD);
  applyBloom(layerMain, 1.0, 3);
  layerBloom.endDraw();

  // ---- FINAL COMPOSITE ----
  background(0);

  // trails + attractor as additive base
  blendMode(ADD);
  image(layerTrails, 0, 0);
  if (showAttractor) image(layerAttr, 0, 0);

  // chromatic aberration of the main layer (also blits main if amount=0)
  blendMode(BLEND);
  applyChromaAberration(layerMain, chromaAmounts[chromaLevel]);

  // bloom on top via SCREEN
  blendMode(SCREEN);
  image(layerBloom, 0, 0);

  blendMode(BLEND);
  if (showInfo) displayInfo();
}

// ---------------------------------------------------------------------------
// KEY CONTROLS
// ---------------------------------------------------------------------------
void keyPressed() {
  switch (key) {
    case 'c': chromaLevel = (chromaLevel + 1) % chromaAmounts.length; break;
    case 'a': showAttractor = !showAttractor; break;
    case 'p': paletteIndex = (paletteIndex + 1) % 5; break;
    case 'i': showInfo = !showInfo; break;
    case '1': showInterference = !showInterference; break;
    case '2': showParticles = !showParticles; break;
    case '3': showVoronoi = !showVoronoi; break;
    case '4': showLissajous = !showLissajous; break;
    case '5': showDataStream = !showDataStream; break;
    case '6': showMotifs = !showMotifs; break;
    case 's': saveFrame("kinetic-genesis-####.png"); break;
    case 'r':
      sketchSeed = (long)random(1, 999999);
      randomSeed(sketchSeed); noiseSeed(sketchSeed);
      setup();
      break;
    case ' ':
      patternIndex = (patternIndex + 1) % 5;
      paletteIndex = patternIndex;
      break;
  }
}

// ---------------------------------------------------------------------------
// UTILITY FUNCTIONS
// ---------------------------------------------------------------------------

// Cosine palette: color = A + B*cos(2PI*(C*t + D)). Returns an RGB color.
// 5 presets: fire, ice, cosmos, neon, earth.
color colorPaletteHSB(float t) {
  float[][] A = {
    {0.5,0.3,0.1},   // fire
    {0.2,0.4,0.6},   // ice
    {0.3,0.2,0.5},   // cosmos
    {0.5,0.5,0.5},   // neon
    {0.4,0.35,0.2}   // earth
  };
  float[][] B = {
    {0.5,0.4,0.1},
    {0.3,0.4,0.4},
    {0.4,0.3,0.5},
    {0.5,0.5,0.5},
    {0.3,0.3,0.2}
  };
  float[][] C = {
    {1.0,1.0,1.0},
    {1.0,1.0,0.8},
    {1.0,1.0,1.5},
    {2.0,1.5,1.0},
    {1.0,0.8,0.6}
  };
  float[][] D = {
    {0.00,0.10,0.20},
    {0.50,0.60,0.70},
    {0.80,0.90,0.30},
    {0.00,0.33,0.67},
    {0.20,0.25,0.30}
  };
  int p = paletteIndex % 5;
  float r = A[p][0] + B[p][0]*cos(TWO_PI*(C[p][0]*t + D[p][0]));
  float g = A[p][1] + B[p][1]*cos(TWO_PI*(C[p][1]*t + D[p][1]));
  float b = A[p][2] + B[p][2]*cos(TWO_PI*(C[p][2]*t + D[p][2]));
  return color(constrain(r,0,1)*255, constrain(g,0,1)*255, constrain(b,0,1)*255);
}

// Multi-source wave: sums 5 wave sources at different canvas locations.
float multiWave(float x, float y, float t) {
  float sum = 0;
  float[][] src = {
    {0.25f*CANVAS, 0.25f*CANVAS, 0.012f, 0.0f},
    {0.75f*CANVAS, 0.30f*CANVAS, 0.018f, 1.3f},
    {0.50f*CANVAS, 0.70f*CANVAS, 0.009f, 2.1f},
    {0.20f*CANVAS, 0.80f*CANVAS, 0.022f, 3.7f},
    {0.85f*CANVAS, 0.85f*CANVAS, 0.015f, 5.2f}
  };
  for (int i = 0; i < src.length; i++) {
    float d = dist(x, y, src[i][0], src[i][1]);
    sum += sin(d * src[i][2] - t * 2.0 + src[i][3]);
  }
  return sum / src.length;   // -1..1
}

// Subtle perlin noise color field rendered as a grid of soft rects.
void drawNoiseColorField(PGraphics g, float t) {
  int cells = 36;
  float cs = (float)CANVAS / cells;
  g.noStroke();
  g.colorMode(RGB, 255);
  for (int i = 0; i < cells; i++) {
    for (int j = 0; j < cells; j++) {
      float n = noise(i*0.18, j*0.18, t*0.4);
      color c = colorPaletteHSB(n + t*0.05);
      g.fill(red(c), green(c), blue(c), 14);
      g.rect(i*cs, j*cs, cs+1, cs+1);
    }
  }
  g.colorMode(HSB, 360, 100, 100, 255);
}

// ---- BLOOM ----
// Draws src scaled up at decreasing alpha to create soft glow halo.
void applyBloom(PGraphics src, float intensity, int passes) {
  float[] scales = {1.02, 1.04, 1.06, 1.08};
  float[] alphas = {40, 25, 15, 8};
  layerBloom.imageMode(CENTER);
  for (int i = 0; i < min(passes, scales.length); i++) {
    float s = scales[i] * intensity;
    layerBloom.tint(255, alphas[i]);
    layerBloom.image(src, CANVAS*0.5, CANVAS*0.5, CANVAS*s, CANVAS*s);
  }
  layerBloom.noTint();
  layerBloom.imageMode(CORNER);
}

// ---- CHROMATIC ABERRATION ----
// Splits RGB channels horizontally; ADD-blends them back together.
void applyChromaAberration(PGraphics src, float amount) {
  if (amount <= 0.001) { image(src, 0, 0); return; }
  blendMode(ADD);
  tint(255, 0, 0, 255);   image(src, -amount, 0);   // red shifted left
  tint(0, 255, 0, 255);   image(src, 0, 0);          // green centered
  tint(0, 0, 255, 255);   image(src,  amount, 0);    // blue shifted right
  noTint();
  blendMode(BLEND);
}

// ===========================================================================
// ORIGINAL CLASSES
// ===========================================================================

// ---- Flow field --------------------------------------------------------
class Flow {
  int cols, rows;
  float scale;
  PVector[][] field;
  float cw, ch;
  Flow(int cols, int rows, float scale) {
    this.cols = cols; this.rows = rows; this.scale = scale;
    cw = (float)CANVAS / cols; ch = (float)CANVAS / rows;
    field = new PVector[cols][rows];
  }
  void update(float t) {
    for (int i = 0; i < cols; i++)
      for (int j = 0; j < rows; j++) {
        float a = noise(i*scale*40, j*scale*40, t*0.5) * TWO_PI * 2;
        field[i][j] = PVector.fromAngle(a);
      }
  }
  PVector lookup(float x, float y) {
    int i = constrain((int)(x/cw), 0, cols-1);
    int j = constrain((int)(y/ch), 0, rows-1);
    return field[i][j].copy();
  }
}

// ---- Motion: flow-field driven particle with trail ---------------------
class Motion {
  PVector pos, prev, vel;
  float maxSpeed, hue;
  Motion() { reset(); prev = pos.copy(); }
  void reset() {
    pos = new PVector(random(CANVAS), random(CANVAS));
    vel = new PVector();
    maxSpeed = random(2, 6);
    hue = random(360);
  }
  void update() {
    prev = pos.copy();
    PVector f = flow.lookup(pos.x, pos.y);
    f.mult(0.6);
    vel.add(f);
    vel.limit(maxSpeed);
    pos.add(vel);
    if (pos.x < 0 || pos.x > CANVAS || pos.y < 0 || pos.y > CANVAS) {
      reset(); prev = pos.copy();
    }
    hue = (hue + 0.4) % 360;
  }
  void drawTrail(PGraphics g) {
    g.stroke(hue, 70, 95, 90);
    g.strokeWeight(1.4);
    g.line(prev.x, prev.y, pos.x, pos.y);
  }
}

// ---- Flower: rotating petal mandala -------------------------------------
class Flower {
  float x, y, r, rot, rotSpeed, hue;
  int petals;
  Flower(float x, float y, float r) {
    this.x = x; this.y = y; this.r = r;
    petals = (int)random(6, 14);
    rotSpeed = random(-0.01, 0.01);
    hue = random(360);
  }
  void update() { rot += rotSpeed; hue = (hue + 0.2) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x, y);
    g.rotate(rot);
    g.noFill();
    g.strokeWeight(1.8);
    for (int i = 0; i < petals; i++) {
      float a = TWO_PI * i / petals;
      g.stroke((hue + i*12) % 360, 80, 95, 120);
      g.pushMatrix();
      g.rotate(a);
      g.ellipse(r*0.5, 0, r, r*0.4);
      g.popMatrix();
    }
    g.popMatrix();
  }
}

// ---- Connector: draws lines between nearby motions ---------------------
class Connector {
  int idx;
  float maxDist;
  Connector() { idx = (int)random(1000); maxDist = random(120, 260); }
  void update() { idx++; }
  void display(PGraphics g, ArrayList<Motion> ms) {
    if (ms.size() < 2) return;
    Motion a = ms.get(idx % ms.size());
    for (int k = 0; k < 6; k++) {
      Motion b = ms.get((idx + k*7 + 1) % ms.size());
      float d = PVector.dist(a.pos, b.pos);
      if (d < maxDist) {
        float al = map(d, 0, maxDist, 80, 0);
        g.stroke(a.hue, 50, 100, al);
        g.strokeWeight(0.8);
        g.line(a.pos.x, a.pos.y, b.pos.x, b.pos.y);
      }
    }
  }
}

// ---- CharacterSymbol: a single falling glyph ---------------------------
class CharacterSymbol {
  char c;
  float size, bright;
  CharacterSymbol(char c, float size, float bright) {
    this.c = c; this.size = size; this.bright = bright;
  }
}

// ---- BinaryDrop: a column of falling binary --------------------------
class BinaryDrop {
  float x, y, speed, size;
  int len;
  char[] chars;
  float hue;
  BinaryDrop(float x) {
    this.x = x;
    y = random(-CANVAS, 0);
    speed = random(4, 16);
    size = random(12, 22);
    len = (int)random(8, 26);
    hue = random(110, 160);
    chars = new char[len];
    for (int i = 0; i < len; i++) chars[i] = random(1) < 0.5 ? '0' : '1';
  }
  void update() {
    y += speed;
    if (y - len*size > CANVAS) {
      y = random(-CANVAS*0.5, 0);
      speed = random(4, 16);
      for (int i = 0; i < len; i++) chars[i] = random(1) < 0.5 ? '0' : '1';
    }
    if (random(1) < 0.1) chars[(int)random(len)] = random(1) < 0.5 ? '0' : '1';
  }
  void display(PGraphics g) {
    g.textAlign(CENTER, CENTER);
    g.textSize(size);
    for (int i = 0; i < len; i++) {
      float yy = y - i*size;
      if (yy < 0 || yy > CANVAS) continue;
      float b = map(i, 0, len, 100, 10);
      if (i == 0) g.fill(hue, 20, 100, 255);
      else g.fill(hue, 80, b, 200);
      g.text(chars[i], x, yy);
    }
  }
}

// ---- BinaryRain: classic matrix rain (fallback) ------------------------
class BinaryRain {
  ArrayList<BinaryDrop> drops;
  BinaryRain(int n) {
    drops = new ArrayList<BinaryDrop>();
    float gap = (float)CANVAS / n;
    for (int i = 0; i < n; i++) drops.add(new BinaryDrop(i*gap + gap*0.5));
  }
  void update_display(PGraphics g) {
    for (BinaryDrop d : drops) { d.update(); d.display(g); }
  }
}

// ---- VibrantShape: pulsing polygon -------------------------------------
class VibrantShape {
  float x, y, r, rot, rotSpeed, hue, pulse;
  int sides;
  VibrantShape() {
    x = random(CANVAS); y = random(CANVAS);
    r = random(40, 160);
    sides = (int)random(3, 9);
    rotSpeed = random(-0.02, 0.02);
    hue = random(360);
    pulse = random(TWO_PI);
  }
  void update() { rot += rotSpeed; pulse += 0.04; hue = (hue + 0.3) % 360; }
  void display(PGraphics g) {
    float rr = r * (1 + 0.2*sin(pulse));
    g.pushMatrix();
    g.translate(x, y);
    g.rotate(rot);
    g.noFill();
    g.strokeWeight(2.2);
    g.stroke(hue, 85, 100, 150);
    g.beginShape();
    for (int i = 0; i < sides; i++) {
      float a = TWO_PI * i / sides;
      g.vertex(cos(a)*rr, sin(a)*rr);
    }
    g.endShape(CLOSE);
    g.popMatrix();
  }
}

// ---- ComplexGeometry: nested rotating rings ----------------------------
class ComplexGeometry {
  float x, y, baseR, rot, hue;
  int rings;
  ComplexGeometry(float x, float y) {
    this.x = x; this.y = y;
    baseR = random(80, 260);
    rings = (int)random(4, 9);
    hue = random(360);
  }
  void update() { rot += 0.006; hue = (hue + 0.15) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x, y);
    g.noFill();
    for (int i = 0; i < rings; i++) {
      float rr = baseR * (i+1) / rings;
      g.stroke((hue + i*20) % 360, 70, 95, 90);
      g.strokeWeight(1.4);
      g.pushMatrix();
      g.rotate(rot * (i%2==0 ? 1 : -1) * (i+1));
      int seg = 6 + i;
      g.beginShape();
      for (int k = 0; k <= seg; k++) {
        float a = TWO_PI * k / seg;
        g.vertex(cos(a)*rr, sin(a)*rr);
      }
      g.endShape();
      g.popMatrix();
    }
    g.popMatrix();
  }
}

// ---- OrbitingElement: bodies orbiting a center -------------------------
class OrbitingElement {
  float cx, cy, radius, angle, speed, hue, sz;
  OrbitingElement(float cx, float cy, float radius) {
    this.cx = cx; this.cy = cy; this.radius = radius;
    angle = random(TWO_PI);
    speed = random(0.005, 0.02) * (random(1) < 0.5 ? 1 : -1);
    hue = random(360);
    sz = random(8, 26);
  }
  void update() { angle += speed; hue = (hue + 0.5) % 360; }
  void display(PGraphics g) {
    float x = cx + cos(angle)*radius;
    float y = cy + sin(angle)*radius;
    g.noStroke();
    g.fill(hue, 80, 100, 180);
    g.ellipse(x, y, sz, sz);
    g.stroke(hue, 30, 100, 60);
    g.noFill();
    g.strokeWeight(0.6);
    g.ellipse(cx, cy, radius*2, radius*2);
  }
}

// ===========================================================================
// KINETIC MOTIFS  (sacred-geometry shape family)
// ===========================================================================
abstract class KineticMotif {
  float x, y, r, rot, hue;
  KineticMotif(float x, float y, float r) {
    this.x = x; this.y = y; this.r = r; hue = random(360);
  }
  abstract void update(float t);
  abstract void display(PGraphics g);
}

// Metatron's cube style node + connection motif
class MetatronMotif extends KineticMotif {
  PVector[] nodes;
  MetatronMotif(float x, float y, float r) {
    super(x, y, r);
    nodes = new PVector[13];
    nodes[0] = new PVector(0, 0);
    for (int i = 0; i < 6; i++) {
      float a = TWO_PI*i/6;
      nodes[1+i] = new PVector(cos(a)*r*0.5, sin(a)*r*0.5);
    }
    for (int i = 0; i < 6; i++) {
      float a = TWO_PI*i/6 + PI/6;
      nodes[7+i] = new PVector(cos(a)*r, sin(a)*r);
    }
  }
  void update(float t) { rot += 0.004; hue = (hue + 0.1) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x, y);
    g.rotate(rot);
    g.strokeWeight(1.0);
    for (int i = 0; i < nodes.length; i++)
      for (int j = i+1; j < nodes.length; j++) {
        g.stroke((hue + (i+j)*4) % 360, 60, 95, 50);
        g.line(nodes[i].x, nodes[i].y, nodes[j].x, nodes[j].y);
      }
    g.noStroke();
    for (PVector n : nodes) {
      g.fill(hue, 70, 100, 200);
      g.ellipse(n.x, n.y, 8, 8);
    }
    g.popMatrix();
  }
}

// Torus rendered as stacked offset ellipses
class TorusMotif extends KineticMotif {
  int rings = 24;
  TorusMotif(float x, float y, float r) { super(x, y, r); }
  void update(float t) { rot += 0.01; hue = (hue + 0.2) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x, y);
    g.noFill();
    g.strokeWeight(1.2);
    for (int i = 0; i < rings; i++) {
      float a = TWO_PI*i/rings + rot;
      float ox = cos(a) * r * 0.4;
      float oy = sin(a) * r * 0.15;
      g.stroke((hue + i*8) % 360, 75, 95, 120);
      g.ellipse(ox, oy, r, r*0.5);
    }
    g.popMatrix();
  }
}

// Logarithmic spiral
class SpiralMotif extends KineticMotif {
  SpiralMotif(float x, float y, float r) { super(x, y, r); }
  void update(float t) { rot += 0.012; hue = (hue + 0.25) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x, y);
    g.rotate(rot);
    g.noFill();
    g.strokeWeight(2.0);
    g.beginShape();
    for (float a = 0; a < TWO_PI*5; a += 0.1) {
      float rr = r * 0.02 * a * exp(a*0.04);
      if (rr > r) break;
      g.stroke((hue + degrees(a)*0.3) % 360, 85, 100, 150);
      g.vertex(cos(a)*rr, sin(a)*rr);
    }
    g.endShape();
    g.popMatrix();
  }
}

// Concentric polygon rings
class PolygonRingMotif extends KineticMotif {
  int rings = 7;
  PolygonRingMotif(float x, float y, float r) { super(x, y, r); }
  void update(float t) { rot += 0.008; hue = (hue + 0.18) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x, y);
    g.noFill();
    g.strokeWeight(1.6);
    for (int i = 0; i < rings; i++) {
      int sides = 3 + i;
      float rr = r * (i+1)/rings;
      g.stroke((hue + i*16) % 360, 80, 95, 130);
      g.pushMatrix();
      g.rotate(rot * (i%2==0?1:-1));
      g.beginShape();
      for (int k = 0; k < sides; k++) {
        float a = TWO_PI*k/sides;
        g.vertex(cos(a)*rr, sin(a)*rr);
      }
      g.endShape(CLOSE);
      g.popMatrix();
    }
    g.popMatrix();
  }
}

// Animated grid lattice with wave displacement
class GridLatticeMotif extends KineticMotif {
  int n = 12;
  GridLatticeMotif(float x, float y, float r) { super(x, y, r); }
  void update(float t) { rot = t; hue = (hue + 0.12) % 360; }
  void display(PGraphics g) {
    g.pushMatrix();
    g.translate(x - r, y - r);
    g.strokeWeight(1.2);
    float step = (r*2)/n;
    for (int i = 0; i <= n; i++)
      for (int j = 0; j <= n; j++) {
        float w = multiWave(x - r + i*step, y - r + j*step, rot);
        float off = w * 10;
        g.stroke((hue + (i+j)*5) % 360, 70, 95, 120);
        g.point(i*step + off, j*step + off);
        if (i < n) g.line(i*step, j*step, (i+1)*step, j*step);
        if (j < n) g.line(i*step, j*step, i*step, (j+1)*step);
      }
    g.popMatrix();
  }
}

// ===========================================================================
// NEW SYSTEM 1: ParticleCloud  (Anadol-style data materialization)
// ===========================================================================
class ParticleCloud {
  int n;
  float[] px, py, vx, vy, ppx, ppy, life;
  float[] col;            // hue per particle
  int attractorCount = 240;
  float[] ax, ay;         // current attractor positions
  float[] tax, tay;       // target attractor positions
  int shape = 0;
  float morph = 0;        // 0..1 interpolation toward target shape
  float morphSpeed = 0.004;

  ParticleCloud(int n) {
    this.n = n;
    px = new float[n]; py = new float[n];
    vx = new float[n]; vy = new float[n];
    ppx = new float[n]; ppy = new float[n];
    life = new float[n]; col = new float[n];
    for (int i = 0; i < n; i++) {
      px[i] = random(CANVAS); py[i] = random(CANVAS);
      ppx[i] = px[i]; ppy[i] = py[i];
      vx[i] = 0; vy[i] = 0;
      life[i] = random(1);
      col[i] = random(360);
    }
    ax = new float[attractorCount]; ay = new float[attractorCount];
    tax = new float[attractorCount]; tay = new float[attractorCount];
    setShape(0, ax, ay);
    setShape(1, tax, tay);
  }

  // Generate attractor layout for shape index into supplied arrays.
  void setShape(int s, float[] xs, float[] ys) {
    float cx = CANVAS*0.5, cy = CANVAS*0.5;
    int m = attractorCount;
    switch (s % 4) {
      case 0: // circle
        for (int i = 0; i < m; i++) {
          float a = TWO_PI*i/m;
          float r = CANVAS*0.34;
          xs[i] = cx + cos(a)*r; ys[i] = cy + sin(a)*r;
        } break;
      case 1: // grid
        int side = (int)sqrt(m);
        float gap = CANVAS*0.6/side;
        float o = CANVAS*0.2;
        for (int i = 0; i < m; i++) {
          int gx = i % side, gy = i / side;
          xs[i] = o + gx*gap; ys[i] = o + gy*gap;
        } break;
      case 2: // spiral
        for (int i = 0; i < m; i++) {
          float a = 0.4*i;
          float r = CANVAS*0.0016*i;
          xs[i] = cx + cos(a)*r; ys[i] = cy + sin(a)*r;
        } break;
      case 3: // polygon (hexagram outline)
        for (int i = 0; i < m; i++) {
          float t = (float)i/m * 6;
          int edge = (int)t; float f = t - edge;
          float a0 = TWO_PI*edge/6, a1 = TWO_PI*(edge+1)/6;
          float r = CANVAS*0.32;
          float x0 = cx+cos(a0)*r, y0 = cy+sin(a0)*r;
          float x1 = cx+cos(a1)*r, y1 = cy+sin(a1)*r;
          xs[i] = lerp(x0,x1,f); ys[i] = lerp(y0,y1,f);
        } break;
    }
  }

  void advanceMorph() {
    morph += morphSpeed;
    if (morph >= 1) {
      morph = 0;
      shape = (shape + 1) % 4;
      for (int i = 0; i < attractorCount; i++) { ax[i] = tax[i]; ay[i] = tay[i]; }
      setShape(shape + 1, tax, tay);
    }
  }

  void drawTrails(PGraphics g, float t) {
    advanceMorph();
    g.strokeWeight(1.2);
    for (int i = 0; i < n; i++) {
      // interpolated attractor position
      int ai = i % attractorCount;
      float axp = lerp(ax[ai], tax[ai], morph);
      float ayp = lerp(ay[ai], tay[ai], morph);

      // attraction
      float dx = axp - px[i], dy = ayp - py[i];
      float d = sqrt(dx*dx + dy*dy) + 0.0001;
      float force = 0.06;
      vx[i] += (dx/d) * force;
      vy[i] += (dy/d) * force;

      // noise jitter
      float ang = noise(px[i]*0.001, py[i]*0.001, t*0.3) * TWO_PI * 2;
      vx[i] += cos(ang) * 0.4;
      vy[i] += sin(ang) * 0.4;

      // drag
      vx[i] *= 0.92; vy[i] *= 0.92;

      ppx[i] = px[i]; ppy[i] = py[i];
      px[i] += vx[i]; py[i] += vy[i];

      float speed = sqrt(vx[i]*vx[i] + vy[i]*vy[i]);
      float hue = (col[i] + speed*30 + t*10) % 360;
      float alpha = map(d, 0, 400, 140, 8);
      alpha = constrain(alpha, 6, 140);
      g.stroke(hue, 80, map(speed, 0, 6, 50, 100), alpha);
      g.line(ppx[i], ppy[i], px[i], py[i]);
    }
  }
}

// ===========================================================================
// NEW SYSTEM 2: InterferenceField  (Ikeda-style sine interference)
// ===========================================================================
class InterferenceField {
  int grid;
  int sources;
  float[] sx, sy, sfx, sfy, sax, say, sph;  // Lissajous source params
  float cell;

  InterferenceField(int grid, int sources) {
    this.grid = grid; this.sources = sources;
    cell = (float)CANVAS / grid;
    sx = new float[sources]; sy = new float[sources];
    sfx = new float[sources]; sfy = new float[sources];
    sax = new float[sources]; say = new float[sources];
    sph = new float[sources];
    for (int i = 0; i < sources; i++) {
      sfx[i] = random(0.3, 1.3);
      sfy[i] = random(0.3, 1.3);
      sax[i] = random(CANVAS*0.2, CANVAS*0.4);
      say[i] = random(CANVAS*0.2, CANVAS*0.4);
      sph[i] = random(TWO_PI);
    }
  }

  void updateSources(float t) {
    for (int i = 0; i < sources; i++) {
      sx[i] = CANVAS*0.5 + sin(t*sfx[i] + sph[i]) * sax[i];
      sy[i] = CANVAS*0.5 + cos(t*sfy[i] + sph[i]) * say[i];
    }
  }

  void render(PGraphics g, float t) {
    updateSources(t);
    g.noStroke();
    g.colorMode(HSB, 360, 100, 100, 255);
    for (int i = 0; i < grid; i++) {
      for (int j = 0; j < grid; j++) {
        float x = i*cell + cell*0.5;
        float y = j*cell + cell*0.5;
        float sum = 0;
        for (int s = 0; s < sources; s++) {
          float d = dist(x, y, sx[s], sy[s]);
          sum += sin(d * 0.03 - t * 2.0);
        }
        float b = map(sum, -sources, sources, 0, 100);
        if (b < 35) continue;                 // sparse Ikeda look
        color pc = colorPaletteHSB(b/100 + t*0.05);
        g.colorMode(RGB,255);
        g.fill(red(pc), green(pc), blue(pc), map(b, 35, 100, 30, 160));
        g.rect(x - cell*0.35, y - cell*0.35, cell*0.7, cell*0.7);
        g.colorMode(HSB,360,100,100,255);
      }
    }
  }
}

// ===========================================================================
// NEW SYSTEM 3: LissajousSystem
// ===========================================================================
class LissajousSystem {
  int count;
  float[] axr, ayr, phase, axBase, ayBase, hue, scale;
  LissajousSystem(int count) {
    this.count = count;
    axr = new float[count]; ayr = new float[count]; phase = new float[count];
    axBase = new float[count]; ayBase = new float[count];
    hue = new float[count]; scale = new float[count];
    for (int i = 0; i < count; i++) {
      axBase[i] = (int)random(1, 7);
      ayBase[i] = (int)random(1, 7);
      phase[i] = random(TWO_PI);
      hue[i] = random(360);
      scale[i] = CANVAS*0.5 * map(i, 0, count, 0.3, 0.95);
    }
  }
  void render(PGraphics g, float t) {
    g.pushMatrix();
    g.translate(CANVAS*0.5, CANVAS*0.5);
    g.noFill();
    for (int i = 0; i < count; i++) {
      axr[i] = axBase[i] + sin(t*0.1 + i)*0.5;
      ayr[i] = ayBase[i] + cos(t*0.13 + i)*0.5;
      g.strokeWeight(2.4);
      color c = colorPaletteHSB((float)i/count + t*0.04);
      g.colorMode(RGB,255);
      g.stroke(red(c), green(c), blue(c), 70);
      g.beginShape();
      for (float a = 0; a <= TWO_PI; a += 0.02) {
        float x = sin(axr[i]*a + phase[i] + t*0.2) * scale[i];
        float y = sin(ayr[i]*a) * scale[i];
        g.vertex(x, y);
      }
      g.endShape();
      g.colorMode(HSB,360,100,100,255);
    }
    g.popMatrix();
  }
}

// ===========================================================================
// NEW SYSTEM 4: VoronoiPulse
// ===========================================================================
class VoronoiPulse {
  int seeds, grid;
  float[] sx, sy, svx, svy, shue, spulse;
  float cell;
  VoronoiPulse(int seeds, int grid) {
    this.seeds = seeds; this.grid = grid;
    cell = (float)CANVAS / grid;
    sx = new float[seeds]; sy = new float[seeds];
    svx = new float[seeds]; svy = new float[seeds];
    shue = new float[seeds]; spulse = new float[seeds];
    for (int i = 0; i < seeds; i++) {
      sx[i] = random(CANVAS); sy[i] = random(CANVAS);
      svx[i] = random(-0.6, 0.6); svy[i] = random(-0.6, 0.6);
      shue[i] = random(360); spulse[i] = random(TWO_PI);
    }
  }
  void update(float t) {
    for (int i = 0; i < seeds; i++) {
      sx[i] += svx[i]; sy[i] += svy[i];
      if (sx[i] < 0 || sx[i] > CANVAS) svx[i] *= -1;
      if (sy[i] < 0 || sy[i] > CANVAS) svy[i] *= -1;
      spulse[i] += 0.03;
    }
  }
  void render(PGraphics g, float t) {
    update(t);
    g.noStroke();
    for (int i = 0; i < grid; i++) {
      for (int j = 0; j < grid; j++) {
        float x = i*cell + cell*0.5;
        float y = j*cell + cell*0.5;
        int best = -1; float bestD = 1e9, secondD = 1e9;
        for (int s = 0; s < seeds; s++) {
          float r = 1 + 0.3*sin(spulse[s]);   // pulsing influence
          float dx = x - sx[s], dy = y - sy[s];
          float d = (dx*dx + dy*dy) / (r*r);
          if (d < bestD) { secondD = bestD; bestD = d; best = s; }
          else if (d < secondD) secondD = d;
        }
        if (best < 0) continue;
        float grad = map(sqrt(bestD), 0, 700, 60, 8);
        grad = constrain(grad, 6, 60);
        float edge = secondD - bestD;
        boolean border = sqrt(secondD) - sqrt(bestD) < 8;
        g.fill(shue[best], 70, 80, grad*0.5);
        g.rect(i*cell, j*cell, cell+1, cell+1);
        if (border) {
          g.fill(shue[best], 20, 100, 70);
          g.rect(i*cell, j*cell, cell+1, cell+1);
        }
      }
    }
  }
}

// ===========================================================================
// NEW SYSTEM 5: DataStream  (upgraded BinaryRain)
// ===========================================================================
class DataStream {
  int n;
  float[] x, y, speed, drift, size, hue;
  int[] len, dir;            // dir: 0 down, 1 down-left drift, 2 down-right
  char[][] glyphs;
  String charset;
  DataStream(int n) {
    this.n = n;
    // binary, hex, katakana, math symbols
    charset = "01ABCDEF" + "アイウエオカキクケコ"
            + "∑∏∂∇∞∫≈≠±";
    x = new float[n]; y = new float[n]; speed = new float[n];
    drift = new float[n]; size = new float[n]; hue = new float[n];
    len = new int[n]; dir = new int[n];
    glyphs = new char[n][];
    float gap = (float)CANVAS / n;
    for (int i = 0; i < n; i++) initDrop(i, i*gap + gap*0.5);
  }
  void initDrop(int i, float xpos) {
    x[i] = xpos;
    y[i] = random(-CANVAS, 0);
    speed[i] = random(5, 18);
    size[i] = random(14, 30);
    len[i] = (int)random(8, 28);
    dir[i] = (int)random(3);
    drift[i] = dir[i]==1 ? random(-1.5,-0.3) : dir[i]==2 ? random(0.3,1.5) : 0;
    hue[i] = random(1) < 0.6 ? random(150, 200) : random(280, 320);
    glyphs[i] = new char[len[i]];
    for (int k = 0; k < len[i]; k++)
      glyphs[i][k] = charset.charAt((int)random(charset.length()));
  }
  void render(PGraphics g, float t) {
    g.textAlign(CENTER, CENTER);
    g.colorMode(HSB, 360, 100, 100, 255);
    for (int i = 0; i < n; i++) {
      y[i] += speed[i];
      x[i] += drift[i];
      if (y[i] - len[i]*size[i] > CANVAS || x[i] < -50 || x[i] > CANVAS+50)
        initDrop(i, random(CANVAS));
      if (random(1) < 0.08)
        glyphs[i][(int)random(len[i])] = charset.charAt((int)random(charset.length()));
      g.textSize(size[i]);
      for (int k = 0; k < len[i]; k++) {
        float yy = y[i] - k*size[i];
        float xx = x[i] - k*drift[i]*0.6;
        if (yy < -30 || yy > CANVAS+30) continue;
        if (k == 0) {
          g.fill(hue[i], 15, 100, 255);          // bright leading glyph
        } else {
          float b = map(k, 0, len[i], 100, 8);
          g.fill(hue[i], 85, b, 210);
        }
        g.text(glyphs[i][k], xx, yy);
      }
    }
  }
}

// ===========================================================================
// NEW SYSTEM 6: AttractorTracer  (Clifford strange attractor)
// ===========================================================================
class AttractorTracer {
  int iterations;
  float a, b, c, d;
  float ta, tb, tc, td;
  float morphT = 0;
  AttractorTracer(int iterations) {
    this.iterations = iterations;
    randomizeParams();
    a=ta; b=tb; c=tc; d=td;
    randomizeParams();
  }
  void randomizeParams() {
    ta = random(-2, 2); tb = random(-2, 2);
    tc = random(-2, 2); td = random(-2, 2);
  }
  void render(PGraphics g, float t) {
    morphT += 0.003;
    if (morphT >= 1) { morphT = 0; a=ta; b=tb; c=tc; d=td; randomizeParams(); }
    float ca = lerp(a, ta, morphT);
    float cb = lerp(b, tb, morphT);
    float cc = lerp(c, tc, morphT);
    float cd = lerp(d, td, morphT);

    g.pushMatrix();
    g.translate(CANVAS*0.5, CANVAS*0.5);
    g.rotate(t*0.02);
    float scl = CANVAS*0.22;
    g.colorMode(HSB, 360, 100, 100, 255);
    g.strokeWeight(2);

    float x = 0, y = 0, px = 0, py = 0;
    for (int i = 0; i < iterations; i++) {
      float nx = sin(ca*y) + cc*cos(ca*x);
      float ny = sin(cb*x) + cd*cos(cb*y);
      float vel = dist(x, y, nx, ny);
      x = nx; y = ny;
      float hue = (map(vel, 0, 4, 180, 360) + t*20) % 360;
      g.stroke(hue, 80, 100, 60);
      g.point(x*scl, y*scl);
      px = x; py = y;
    }
    g.popMatrix();
  }
}

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------
void displayInfo() {
  String[] palNames = {"FIRE","ICE","COSMOS","NEON","EARTH"};
  pushStyle();
  fill(0, 160);
  noStroke();
  rect(20, 20, 430, 300, 12);
  fill(255);
  textAlign(LEFT, TOP);
  textSize(20);
  text("KINETIC GENESIS  —  seed " + sketchSeed, 40, 36);
  textSize(15);
  float yy = 76;
  text("fps: " + nf(frameRate, 0, 1), 40, yy);          yy += 24;
  text("palette ['p']: " + palNames[paletteIndex], 40, yy); yy += 24;
  text("chroma ['c']: " + nf(chromaAmounts[chromaLevel],0,0) + "px", 40, yy); yy += 24;
  text("attractor ['a']: " + (showAttractor?"ON":"off"), 40, yy); yy += 24;
  text("interference ['1']: " + (showInterference?"ON":"off"), 40, yy); yy += 24;
  text("particles ['2']: " + (showParticles?"ON":"off") + " (" + particleCloud.n + ")", 40, yy); yy += 24;
  text("voronoi ['3']: " + (showVoronoi?"ON":"off"), 40, yy); yy += 24;
  text("lissajous ['4'] | datastream ['5'] | motifs ['6']", 40, yy); yy += 24;
  text("'r' regen  's' save  'i' hud  SPACE pattern", 40, yy);
  popStyle();
}
