import processing.serial.*;

Serial myPort;
String data = "";
int iAngle, iDistance;
int maxLimit = 40; 
int targetCounter = 1; // Generates unique IDs for targets

// --- ADVANCED CARTESIAN CLUSTERING ---
class Ping {
  float x, y, angle, dist;
  
  Ping(float a, float d) {
    angle = a; dist = d;
    x = d * cos(radians(a));
    y = d * sin(radians(a));
  }
  
  float distanceTo(Ping other) {
    return sqrt(pow(this.x - other.x, 2) + pow(this.y - other.y, 2));
  }
}

ArrayList<Ping> currentCluster = new ArrayList<Ping>();
ArrayList<Target> confirmedTargets = new ArrayList<Target>();
int lastPingAngle = -1;

void setup() {
  size(1200, 700);
  smooth();
  
  // MAKE SURE COM PORT MATCHES YOUR ESP32
  myPort = new Serial(this, "COM7", 115200); 
  myPort.bufferUntil('.');
}

void draw() {
  // 1. Radar screen fade effect (Left side only)
  fill(0, 10); 
  noStroke();
  rect(0, 0, 800, height); 
  
  // 2. Solid military UI panel (Right side)
  fill(5, 15, 5); 
  rect(800, 0, 400, height);
  
  drawRadarGrid();
  drawObjects(); 
  drawSweepArm(); 
  drawMilitaryHUD(); 
}

void serialEvent(Serial myPort) {
  try {
    data = myPort.readStringUntil('.');
    if (data != null) {
      data = trim(data);
      data = data.substring(0, data.length()-1);
      
      int[] vals = int(split(data, ','));
      if (vals.length == 2) {
        iAngle = vals[0];
        iDistance = vals[1];
        processRadarPing(iAngle, iDistance);
      }
    }
  } catch (Exception e) {}
}

void processRadarPing(int angle, int dist) {
  if (dist > 0 && dist < maxLimit) {
    Ping newPing = new Ping(angle, dist);
    
    if (currentCluster.size() == 0) {
      currentCluster.add(newPing);
    } else {
      Ping lastPing = currentCluster.get(currentCluster.size() - 1);
      if (newPing.distanceTo(lastPing) < 8.0 && abs(angle - lastPingAngle) <= 4) {
        currentCluster.add(newPing);
      } else {
        finalizeCluster();
        currentCluster.add(newPing);
      }
    }
  } else {
    finalizeCluster();
  }
  lastPingAngle = angle;
}

void finalizeCluster() {
  if (currentCluster.size() >= 3) {
    float sumX = 0, sumY = 0, sumAngle = 0;
    
    for (Ping p : currentCluster) {
      sumX += p.x; sumY += p.y; sumAngle += p.angle;
    }
    
    float avgX = sumX / currentCluster.size();
    float avgY = sumY / currentCluster.size();
    float avgAngle = sumAngle / currentCluster.size();
    float avgDist = sqrt(avgX*avgX + avgY*avgY);
    
    confirmedTargets.add(new Target(targetCounter, avgX, avgY, avgAngle, avgDist));
    
    targetCounter++;
    if(targetCounter > 999) targetCounter = 1; // Reset ID if it gets too high
  }
  currentCluster.clear(); 
}

void drawRadarGrid() {
  pushMatrix();
  translate(400, 650); // Center of radar
  noFill();
  strokeWeight(1);
  stroke(0, 150, 0); 
  
  // Adjusted rings so they don't bleed into the HUD!
  // Outer ring (40cm mapped to 400px radius)
  arc(0, 0, 800, 800, PI, TWO_PI);
  arc(0, 0, 600, 600, PI, TWO_PI);   // 30cm
  arc(0, 0, 400, 400, PI, TWO_PI);   // 20cm
  arc(0, 0, 200, 200, PI, TWO_PI);   // 10cm
  
  // Crosshairs
  line(-400, 0, 400, 0);
  line(0, 0, 0, -400);
  
  // Structural angle lines
  for(int a = 30; a < 180; a += 30) {
    stroke(0, 80, 0); // Dimmer grid lines
    line(0, 0, -400*cos(radians(a)), -400*sin(radians(a)));
  }
  
  // Distance Markers on the Rings
  fill(0, 200, 0);
  textSize(12);
  text("10cm", 10, -105);
  text("20cm", 10, -205);
  text("30cm", 10, -305);
  text("40cm", 10, -405);
  popMatrix();
}

void drawObjects() {
  pushMatrix();
  translate(400, 650);
  
  for (int i = confirmedTargets.size() - 1; i >= 0; i--) {
    Target t = confirmedTargets.get(i);
    t.display();
    if (t.alpha <= 0) {
      confirmedTargets.remove(i);
    }
  }
  popMatrix();
}

void drawSweepArm() {
  pushMatrix();
  translate(400, 650);
  strokeWeight(5);
  stroke(100, 255, 100, 200); 
  line(0, 0, 400*cos(radians(iAngle)), -400*sin(radians(iAngle)));
  popMatrix();
}

void drawMilitaryHUD() {
  pushMatrix();
  translate(800, 0); // Move to the right panel
  
  // Panel borders
  strokeWeight(2);
  stroke(0, 255, 0);
  line(0, 0, 0, height);
  line(10, 10, 390, 10);
  line(10, 10, 10, 30);
  
  // Header
  fill(50, 255, 50);
  textSize(22);
  text("ARDUINO RADAR", 20, 40);
  textSize(14);
  fill(0, 200, 0);
  text("SYSTEM: ACTIVE   |   MODE: SRFC-SCAN", 20, 65);
  text("FREQ: 40 kHz     |   DATALINK: SECURE", 20, 85);
  
  stroke(0, 150, 0);
  line(20, 105, 380, 105);
  
  // Live Scanner Data
  fill(50, 255, 50);
  textSize(18);
  text("SWEEP AZIMUTH: " + nf(iAngle, 3) + "°", 20, 140);
  
  // Table Header
  fill(0, 150, 0);
  rect(20, 180, 360, 25);
  fill(0);
  textSize(12);
  text("ID   |  BRG  | RNG(cm) |  COORD(X,Y)  |  THREAT", 25, 197);
  
  // Target Table Data
  int yPos = 230;
  // Loop backwards to show the newest targets at the top of the list
  for (int i = confirmedTargets.size() - 1; i >= max(0, confirmedTargets.size() - 12); i--) {
    Target t = confirmedTargets.get(i);
    
    // Determine Threat Level based on distance
    String threat = "LOW";
    fill(50, 255, 50); // Default Green
    
    if (t.distance < 15) {
      threat = "CRITICAL";
      fill(255, 50, 50); // Red if too close
    } else if (t.distance < 25) {
      threat = "MODERATE";
      fill(255, 200, 50); // Yellow if medium distance
    }
    
    // Format the text nicely into columns
    String tgtId = "T-" + nf(t.id, 3);
    String brg = nf(t.bearing, 3, 1) + "°";
    String rng = nf(t.distance, 2, 1);
    String coord = nf(t.cmX, 2, 1) + "," + nf(t.cmY, 2, 1);
    
    text(tgtId, 25, yPos);
    text(brg, 75, yPos);
    text(rng, 130, yPos);
    text(coord, 200, yPos);
    text(threat, 310, yPos);
    
    yPos += 30; // Move down for the next row
  }
  
  if (confirmedTargets.size() == 0) {
    fill(0, 150, 0);
    text("NO ACTIVE TARGETS IN SECTOR", 90, 230);
  }
  
  popMatrix();
}

class Target {
  int id;
  float cmX, cmY, bearing, distance;
  float alpha, boxSize;

  Target(int id, float x, float y, float b, float d) {
    this.id = id;
    cmX = x; cmY = y; bearing = b; distance = d;
    alpha = 255; 
    boxSize = 60; 
  }

  void display() {
    float pxX = cmX * 10; // Fixed scale factor: 400px / 40cm
    float pxY = -cmY * 10; 
    
    // Core blip
    strokeWeight(12); 
    
    // Color code the blip based on threat level
    if (distance < 15) stroke(255, 50, 50, alpha); // Red
    else if (distance < 25) stroke(255, 200, 50, alpha); // Yellow
    else stroke(50, 255, 50, alpha); // Green
    
    point(pxX, pxY);
    
    // Animated target lock box
    if (boxSize > 20) boxSize -= 2; 
    
    noFill();
    strokeWeight(2);
    rectMode(CENTER);
    rect(pxX, pxY, boxSize, boxSize);
    rectMode(CORNER); // Reset for the rest of the UI
    
    // Tag the blip with its ID directly on the radar
    fill(0, 255, 0, alpha);
    textSize(10);
    text("T-" + nf(id, 3), pxX + 15, pxY - 15);
    
    alpha -= 0.8; // Fades slowly
  }
}
