/* @pjs crisp=false; pauseOnBlur=true; */

/**
 * Comedy-Connections
 *
 * Copyright (c) 2012 Steven Blair
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


/******************* Geometry settings ******************/
final int BORDER = 25;
final float VERTEX_RADIUS_SCALE = 0.5;
final float EDGE_THICKNESS_SCALE = 0.4;
final float MOUSE_OVER_LINE_DISTANCE_THRESHOLD = 0.1;
final float NEARNESS_THRESHOLD = 20.0;


/******************* Processing settings ****************/
final color COLOR_EDGE_DEFAULT = color(64, 128, 187, 100/*64, 128, 128, 200*/);
final color COLOR_EDGE_AXES = color(127, 127, 127, 250/*64, 128, 128, 200*/);
final color COLOR_VERTEX_DEFAULT = color(64, 128, 187, 190);
final color COLOR_VERTEX_HIGHLIGHT = color(64, 187, 128, 190);    // too "bright"?
final color COLOR_VERTEX_DIM = color(64, 128, 187, 40);
final float MAX_HUE = 235.0;        // less than 255.0 to provide better discrimination between colours at extremes
PFont font;
PFont fontBold;


boolean dragging = false;
int draggedVertex = -1;
int sortedPerson[];
int selectedPerson = -1;


/******************* Visulisation modes *****************/
final int MODE_PERSON_VERTICES = 0;
final int MODE_SHOWS_VERTICES = 1;
int mode = MODE_PERSON_VERTICES;        // set default mode


/******************* Layout modes ***********************/
final int LAYOUT_RANDOM_STATIC = 0;
final int LAYOUT_RANDOM_AUTO = 1;
final int LAYOUT_BY_DATE = 2;
final int LAYOUT_BY_VALUE = 3;
final int LAYOUT_BY_DATE_AND_VALUE = 4;
int layout = LAYOUT_RANDOM_STATIC;


/******************* Physics settings *******************/
final float EDGE_LENGTH = 400.0;
final float EDGE_STRENGTH = 0.002;
final float EDGE_DAMPING = 0.0002;
final float SPACER_STRENGTH = -10.0;
final float MINIMUM_DISTANCE = 10.0;
final float SPRING_LENGTH_NORMALISATION = 0.7;    // increase to reduce spring length
final float MASS_NORMALISATION = 0.2;             // increase to increase mass
final float RANDOM_MOVEMENT = 0.1;                // todo: should by scaled by aspect ratio?
ParticleSystem physics;
boolean physicsEnabled = false;


/******************* Graph data model *******************/
final int MAX_PEOPLE = 64;
final int MAX_SHOWS = 64;
Data dataStore;
private ArrayList show;
private ArrayList person;
Vertex vertices[];
MultiEdge edges[];
int vertexCount = 0;
int edgeCount = 0;


boolean near(float a, float b) {
    return abs(a - b) < NEARNESS_THRESHOLD;
}

void resetData() {
    dataStore = new Data();
}

void createGraph() {
    mouseReleased();
    vertices = null;
    edges = null;
    vertices = new Vertex[max(MAX_PEOPLE, MAX_SHOWS)];
    edges = new MultiEdge[MAX_PEOPLE * MAX_SHOWS];
    vertexCount = 0;
    edgeCount = 0;

    if (physics == null) {
        physics = new ParticleSystem(0, 0.2);     // no gravity, small drag
    }
    else {
        physics.clear();                          // remove all particles and forces
    }

    show = dataStore.getShowList();
    person = dataStore.getPersonList();

    colorMode(HSB);

    for (int j = 0; j < person.size(); j++) {
        ((Person) person.get(j)).c = color(j * (MAX_HUE / person.size()), 128, 187, 100);
    }
    
    if (mode == MODE_PERSON_VERTICES) {
        for (int j = 0; j < person.size(); j++) {
            vertices[vertexCount] = new Vertex((Person)person.get(j));
            //((Person) vertices[vertexCount].item).c = color(j * (MAX_HUE / person.size()), 128, 187, 100);
            vertices[vertexCount].p = physics.makeParticle(1.0, vertices[vertexCount].x, vertices[vertexCount].y, 0);

            int i = vertexCount;
            while (i > 0) {
                physics.makeAttraction(vertices[i - 1].p, vertices[vertexCount].p, SPACER_STRENGTH, MINIMUM_DISTANCE);        // all vertices repel each other
                i--;
            }

            vertexCount++;
        }

        for (int j = 0; j < show.size(); j++) {
            for (int k = 0; k < person.size(); k++) {
                for (int l = k + 1; l < person.size(); l++) {
                    if (k != l && ((Person)(vertices[k].item)).isInShow(j) && ((Person)(vertices[l].item)).isInShow(j)) {

                        MultiEdge e = findEdge(vertices[k], vertices[l]);

                        if (e == null) {
                            edges[edgeCount] = new MultiEdge((Show)show.get(j), vertices[k], vertices[l]);
                            edgeCount++;
                        }
                        else {
                            e.addEdge((Show)show.get(j), vertices[k], vertices[l]);
                        }
                    }
                }
            }
        }
    }
    else {
        for (int j = 0; j < show.size(); j++) {
            vertices[vertexCount] = new Vertex((Show)show.get(j));
            vertices[vertexCount].p = physics.makeParticle(1.0, vertices[vertexCount].x, vertices[vertexCount].y, 0);

            int i = vertexCount;
            while (i > 0) {
                physics.makeAttraction(vertices[i - 1].p, vertices[vertexCount].p, SPACER_STRENGTH, MINIMUM_DISTANCE);        // all vertices repel each other
                i--;
            }

            vertexCount++;
        }
        for (int j = 0; j < person.size(); j++) {
            for (int k = 0; k < show.size(); k++) {
                for (int l = k + 1; l < show.size(); l++) {
                    Person p = (Person) person.get(j);

                    if (k != l && p.isInShow(k) && p.isInShow(l)) {
                        MultiEdge e = findEdge(vertices[k], vertices[l]);

                        if (e == null) {
                            edges[edgeCount] = new MultiEdge((Person) person.get(j), vertices[k], vertices[l]);
                            edgeCount++;
                        }
                        else {
                            e.addEdge((Person) person.get(j), vertices[k], vertices[l]);
                        }
                    }
                }
            }
        }
    }
    //colorMode(RGB);

    for (int j = 0; j < edgeCount; j++) {
        edges[j].spring = physics.makeSpring(edges[j].vertexA.p, edges[j].vertexB.p, EDGE_STRENGTH * edges[j].numberOfEdges, EDGE_DAMPING, EDGE_LENGTH / (SPRING_LENGTH_NORMALISATION * float(edges[j].numberOfEdges)));        // linked vertices are "springy"
    }
    for (int j = 0; j < vertexCount; j++) {
        vertices[j].p.setMass(MASS_NORMALISATION * max(1, vertices[j].numberOfEdges));
    }
}

// Centre equal-valued results instead of dividing by zero (for example, one match).
float layoutPosition(float value, float minimum, float maximum, float extent) {
    if (minimum == maximum) {
        return extent / 2.0;
    }
    return BORDER + (extent - 2 * BORDER) * (value - minimum) / (maximum - minimum);
}

void setLayout() {
    physicsEnabled = layout == LAYOUT_RANDOM_AUTO;
    loop();
    if (vertexCount == 0) {
        return;
    }
    int minYear = mode == MODE_PERSON_VERTICES ? getMinYearOfBirth() : getMinYear(show);
    int maxYear = mode == MODE_PERSON_VERTICES ? getMaxYearOfBirth() : getMaxYear(show);
    int minValue = getMinValue();
    int maxValue = getMaxValue();
    boolean coincident = true;
    for (int i = 1; i < vertexCount; i++) {
        if (dist(vertices[0].x, vertices[0].y, vertices[i].x, vertices[i].y) > 1) {
            coincident = false;
            break;
        }
    }

    for (int j = 0; j < vertexCount; j++) {
        Vertex v = vertices[j];
        if (physicsEnabled) {
            // A rebuilt graph starts at the centre. Separate particles so the
            // springs and repulsion have a direction in which to apply force.
            if (coincident && vertexCount > 1) {
                v.x = random(BORDER, width - BORDER);
                v.y = random(BORDER, height - BORDER);
            }
            v.p.position.set(v.x, v.y, 0);
            v.p.velocity.set(0, 0, 0);
            continue;
        }
        int itemYear = mode == MODE_PERSON_VERTICES ? ((Person) v.item).yearOfBirth : ((Show) v.item).startYear;
        v.newX = random(BORDER, width - BORDER);
        v.newY = random(BORDER, height - BORDER);
        if (layout == LAYOUT_BY_DATE) {
            v.newX = layoutPosition(itemYear, minYear, maxYear, width);
        } else if (layout == LAYOUT_BY_VALUE || layout == LAYOUT_BY_DATE_AND_VALUE) {
            v.newX = layoutPosition(v.numberOfEdges, minValue, maxValue, width);
        }
        if (layout == LAYOUT_BY_DATE_AND_VALUE) {
            v.newY = layoutPosition(itemYear, minYear, maxYear, height);
        }
    }
}

// Browser controls use these methods without depending on Processing internals.
int getVertexCount() { return vertexCount; }
int getEdgeCount() { return edgeCount; }
Vertex getVertex(int index) { return vertices[index]; }

void setViewMode(int viewMode) {
    mode = viewMode;
}

float resizePosition(float value, float oldExtent, float newExtent) {
    if (oldExtent <= 2 * BORDER) {
        return newExtent / 2.0;
    }
    return constrain(BORDER + (value - BORDER) * (newExtent - 2 * BORDER) / (oldExtent - 2 * BORDER), BORDER, newExtent - BORDER);
}

void resizeGraph(int graphWidth, int graphHeight) {
    graphWidth = max(2 * BORDER + 1, graphWidth);
    graphHeight = max(2 * BORDER + 1, graphHeight);
    if (width == graphWidth && height == graphHeight) {
        return;
    }
    int oldWidth = width;
    int oldHeight = height;
    mouseReleased();
    size(graphWidth, graphHeight);
    textFont(font);
    textLeading(10);

    for (int i = 0; i < vertexCount; i++) {
        Vertex v = vertices[i];
        v.x = resizePosition(v.x, oldWidth, width);
        v.y = resizePosition(v.y, oldHeight, height);
        v.newX = resizePosition(v.newX, oldWidth, width);
        v.newY = resizePosition(v.newY, oldHeight, height);
        v.p.position.set(v.x, v.y, 0);
        v.p.velocity.set(0, 0, 0);
    }
    loop();
}


int getMaxYearOfBirth() {
    int max = 0;

    for (int i = 0; i < person.size(); i++) {
        Person p = (Person) person.get(i);
        if (p.yearOfBirth > max) {
            max = p.yearOfBirth;
        }
    }

    return max;
}

int getMinYearOfBirth() {
    int min = year();

    for (int i = 0; i < person.size(); i++) {
        Person p = (Person) person.get(i);
        if (p.yearOfBirth < min) {
            min = p.yearOfBirth;
        }
    }

    return min;
}

int getMaxValue() {
    int maxValue = 0;

    for (int j = 0; j < vertexCount; j++) {
        if (vertices[j].numberOfEdges > maxValue) {
            maxValue = vertices[j].numberOfEdges;
        }
    }

    return maxValue;
}

int getMinValue() {
    int minValue = getMaxValue();

    for (int j = 0; j < vertexCount; j++) {
        if (vertices[j].numberOfEdges < minValue) {
            minValue = vertices[j].numberOfEdges;
        }
    }

    return minValue;
}

MultiEdge findEdge(Vertex a, Vertex b) {
    for (int i = 0; i < edgeCount; i++) {
        if ((edges[i].vertexA == a && edges[i].vertexB == b) || (edges[i].vertexA == b && edges[i].vertexB == a)) {
            return edges[i];
        }
    }
    return null;
}

void changeLayoutMode(int mode) {
    if (mode >= 0 && mode <= 4) {
        layout = mode;
        setLayout();
    }
}

void mouseMoved() {
    loop();
}

void mouseOver() {
    loop();
}

void mouseOut() {
    loop();
}

void mouseDragged() {
    loop();
    if (draggedVertex < 0) {
        return;
    }
    dragging = true;
    Vertex v = vertices[draggedVertex];
    v.x = v.newX = constrain(mouseX, BORDER, width - BORDER);
    v.y = v.newY = constrain(mouseY, BORDER, height - BORDER);
    v.p.position.set(v.x, v.y, 0);
    v.p.velocity.set(0, 0, 0);
}

void mouseReleased() {
    if (draggedVertex >= 0 && draggedVertex < vertexCount) {
        vertices[draggedVertex].p.makeFree();
    }
    dragging = false;
    draggedVertex = -1;
    loop();
}

void mousePressed() {
    loop();
    if (mouseButton != LEFT) {
        return;
    }
    for (int i = vertexCount - 1; i >= 0; i--) {
        Vertex v = vertices[i];
        if (dist(v.x, v.y, mouseX, mouseY) <= max(6, v.numberOfEdges * VERTEX_RADIUS_SCALE)) {
            draggedVertex = i;
            v.p.makeFixed();
            break;
        }
    }
}

boolean mouseIsOverLine(float x1, float y1, float x2, float y2) {
    float d = dist(x1, y1, x2, y2);
    float d1 = dist(x1, y1, mouseX, mouseY);
    float d2 = dist(x2, y2, mouseX, mouseY);

    // do not trigger if mouse is near a vertex
    if (d1 < 25 || d2 < 25) {       // todo: better value than 25?
        return false;
    }

    // distance between vertices must be similar to sum of distances from each vertex to mouse
    if (d1 + d2 < d + MOUSE_OVER_LINE_DISTANCE_THRESHOLD) {
        return true;
    }

    return false;
}


// returns array of people connecting two shows
int[] getConnections(int j, int k) {
    int conn[] = new int[MAX_PEOPLE];
    int c = 0;
    
    for (int i = 0; i < person.size(); i++) {
        if (((Person) person.get(i)).isInShow(j) && ((Person) person.get(i)).isInShow(k)) {
            conn[c] = i;
            c++;
        }
    }

    return conn;
}

boolean arrayFind(int a[], int e) {
    for (int i = 0; i < a.length; i++) {
        if (a[i] == e) {
            return true;
        }
    }

    return false;
}

int getMaxYear(ArrayList show) {
    int maxYear = 0;
    for (int i = 0; i < show.size(); i++) {
        maxYear = max(maxYear, ((Show) show.get(i)).startYear);
    }
    return maxYear;
}

int getMinYear(ArrayList show) {
    Show s;
    int minYear = year();

    for (int i = 0; i < show.size(); i++) {
        s = ((Show) show.get(i));

        if (s.startYear <= minYear) {
            minYear = s.startYear;
        }
    }

    return minYear;
}


void setup() {
    size(1200, 600);
    smooth();

    strokeWeight(4);
    font = createFont("SansSerif.plain", 12);
    fontBold = createFont("SansSerif.bold", 12);
    textFont(font);
    textLeading(10);
    textAlign(CENTER);

    // create graph data model
    resetData();
    createGraph();
    setLayout();
}

void draw() {
    boolean animating = physicsEnabled && vertexCount > 0;
    if (physicsEnabled) {
        physics.tick();

        for (int i = 0; i < vertexCount; ++i) {
            Vertex v = vertices[i];
            // Keep the simulation and the displayed position in the same bounds.
            v.p.position.x = constrain(v.p.position.x, BORDER, width - BORDER);
            v.p.position.y = constrain(v.p.position.y, BORDER, height - BORDER);
            v.x = v.p.position.x;
            v.y = v.p.position.y;
        }
    }
    else {
        // update vertex positions
        for (int i = 0; i < vertexCount; ++i) {
            if (!near(vertices[i].x, vertices[i].newX)) {
                vertices[i].x += ((vertices[i].newX - vertices[i].x) / frameRate);
                animating = true;
            }
            if (!near(vertices[i].y, vertices[i].newY)) {
                vertices[i].y += ((vertices[i].newY - vertices[i].y) / frameRate);
                animating = true;
            }
        }
    }

    colorMode(HSB);
    background(0);        // fill background black
    textAlign(RIGHT);

    // draw axes
    stroke(COLOR_EDGE_AXES);
    strokeWeight(3);
    fill(COLOR_EDGE_AXES);

    if (layout == LAYOUT_BY_VALUE) {
        line(25, 25, 225, 25);
        line(225, 25, 220, 20);
        line(225, 25, 220, 30);
        text("size", 220, 40);
    }
    else if (layout == LAYOUT_BY_DATE) {
        line(25, 25, 225, 25);
        line(225, 25, 220, 20);
        line(225, 25, 220, 30);
        text("year", 220, 40);
    }
    else if (layout == LAYOUT_BY_DATE_AND_VALUE) {
        line(25, 25, 225, 25);
        line(225, 25, 220, 20);
        line(225, 25, 220, 30);
        text("size", 220, 40);

        line(25, 25, 25, 225);
        line(25, 225, 20, 220);
        line(25, 225, 30, 220);
        text("year", 60, 220);
    }

    // draw edges
    stroke(COLOR_EDGE_DEFAULT);
    strokeWeight(1);
    colorMode(HSB);
    
    for (int k = 0; k < edgeCount; k++) {
        if (edges[k].vertexA.item.visible() && edges[k].vertexB.item.visible()) {
            if (mouseIsOverLine(edges[k].vertexA.x, edges[k].vertexA.y, edges[k].vertexB.x, edges[k].vertexB.y)) {
                if (edges[k].anim < 21.0) {
                    edges[k].anim = edges[k].anim + 5.0;
                    animating = true;
                }
                else {
                    edges[k].anim = 21.0;
                }

                drawEdge(edges[k], edges[k].vertexA, edges[k].vertexB, edges[k].anim, true);
            }
            else {
                if (edges[k].anim > 1.0) {
                    edges[k].anim = edges[k].anim - 5.0;
                    animating = true;
                }
                else {
                    edges[k].anim = 1.0;
                }

                if (edges[k].anim == 1.0) {
                    if (mode == MODE_SHOWS_VERTICES) {
                        stroke(edges[k].colorMix);
                    }
                    strokeWeight((float) (edges[k].numberOfEdges * edges[k].numberOfEdges * EDGE_THICKNESS_SCALE)); // non-linear scaling: exaggerates "connective-ness" to make graphs less "messy" and useless
                    line(edges[k].vertexA.x, edges[k].vertexA.y, edges[k].vertexB.x, edges[k].vertexB.y);
                }
                else {
                    drawEdge(edges[k], edges[k].vertexA, edges[k].vertexB, edges[k].anim, false);
                }
            }
        }
    }
    
    // draw vertices
    colorMode(RGB);
    textAlign(LEFT);
    textFont(font);

    for (j = 0; j < vertexCount; j++) {
        // Disable shape stroke/border
        noStroke();

        // Cache diameter and radius of current circle
        float radi = max(5, vertices[j].numberOfEdges * VERTEX_RADIUS_SCALE);
        float diam = radi * 2.0;

        if (j == draggedVertex || dist(vertices[j].x, vertices[j].y, mouseX, mouseY) < radi) {
            fill(COLOR_VERTEX_HIGHLIGHT);
        }
        else {
            colorMode(RGB);
            // Keep fill color blue
            if (vertices[j].item instanceof Person) {
                fill(((Person) vertices[j].item).c);
            }
            else {
                fill(COLOR_VERTEX_DEFAULT);
            }
        }

        if (selectedPerson == -1 || (selectedPerson > -1 && arrayFind(getConnections(j, j), selectedPerson))) {
            ellipse(vertices[j].x, vertices[j].y, diam, diam);
            text(vertices[j].item.name, vertices[j].x + 2, vertices[j].y - 5 - radi);
        }
        else {
            fill(COLOR_VERTEX_DIM);
            ellipse(vertices[j].x, vertices[j].y, diam, diam);
            text(vertices[j].item.name, vertices[j].x + 2, vertices[j].y - 5 - radi);
        }
    }

    // Retain the last frame until input or a layout change needs another one.
    if (!animating) {
        noLoop();
    }
}

void drawEdge(MultiEdge e, Vertex v1, Vertex v2, float distance, boolean drawNames) {
    float mid = e.visibleItems() / 2.0;
    color col = color(0);

    float xm = 0.0;
    float ym = 0.0;
    float x1 = 0.0;
    float y1 = 0.0;
    float x2 = 0.0;
    float y2 = 0.0;
    float xoffset = 0.0;
    float yoffset = 0.0;

    if (v1.x == v2.x) {
        xm = v1.x;
    }
    else if (v1.x < v2.x) {
        xm = v1.x + ((v2.x - v1.x) / 2);
    }
    else if (v1.x > v2.x) {
        xm = v2.x + ((v1.x - v2.x) / 2);
    }
    if (v1.y == v2.y) {
        ym = v1.y;
    }
    else if (v1.y < v2.y) {
        ym = v1.y + ((v2.y - v1.y) / 2);
    }
    else if (v1.y > v2.y) {
        ym = v2.y + ((v1.y - v2.y) / 2);
    }

    float th = acos( dist(v1.x, v1.y, v1.x, v2.y) / dist(v1.x, v1.y, v2.x, v2.y) );

    if (v1.x < v2.x && v1.y < v2.y) {
        //continue;
        th = TWO_PI - th;
    }

    for (int n = 0; n < e.numberOfEdges; n++) {
        if (mode == MODE_SHOWS_VERTICES) {
            col = ((Person) e.edges[n].item).c;
        }
        
        // todo: not the best way to check this?
        if (e.visibleItems() > 1) {
            xoffset = (((float) (n)) + 0.5 - mid) * cos(th) * distance;
            yoffset = (((float) (n)) + 0.5 - mid) * sin(th) * distance;
        }

        noFill();

        if (drawNames) {
            strokeWeight(4);
        }
        else {
            strokeWeight(1);
        }

        if (e.edges[n].item instanceof Show) {
            colorMode(RGB);
            stroke(COLOR_EDGE_DEFAULT);
            colorMode(HSB);
        }
        else if (e.edges[n].item instanceof Person) {
            stroke(col);
        }

        bezier( v1.x, v1.y,
        xm + xoffset, ym + yoffset,
        xm + xoffset, ym + yoffset,
        v2.x, v2.y);

        if (drawNames) {
            if (e.edges[n].item instanceof Person) {
                fill(col);
            }
            text(e.edges[n].item.name, xm + xoffset, ym + yoffset);
        }
    }
}

class Item {
    public int id;
    public String name;
    public boolean selected = true;
    public boolean hovered = false;
    
    public boolean visible() {
        if (hovered || selected) {
            return true;
        }
        
        return false;
    }
}

class Person extends Item {
    public int yearOfBirth;
    public int showsBeenIn[];
    
    private int count;
    
    public color c;

    // returns id of show object that matches s; -1 if not found
    public int find(int s, ArrayList showList) {
        for (int i = 0; i < showList.size(); i++) {
            if (s == ((Show) showList.get(i)).id) {
                return i;
            }
        }
    
        return -1;
    }
    
    Person(int id, String name, int yearOfBirth, Object shows[], ArrayList showList) {
        this.id = id;
        this.name = name;
        this.yearOfBirth = yearOfBirth;
        this.count = 0;
        this.showsBeenIn = new int[MAX_SHOWS];
        
        int num = 0;
        
        for (int i = 0; i < shows.length; i++) {
            num = find(shows[i].id, showList);
            
            if (num > -1) {
                this.showsBeenIn[this.count] = num;
                this.count++;
            }
        }
    }
    
    int getTotalShowsBeenIn() {
        return count;
    }
    
    boolean isInShow(int s) {
        for (int i = 0; i < this.count; i++) {
            if (this.showsBeenIn[i] == s) {
                return true;
            }
        }
        return false;
    }
}

class Show extends Item {
    public int startYear;

    Show(int id, String name, int startYear) {
        this.id = id;
        this.name = name;
        this.startYear = startYear;
    }
}


public class Vertex {
    public Item item;
    
    public Edge edge[];         // 'cache' of edges connecting this vertex
    public int numberOfEdges;
    
    public Particle p;
    
    public float x;
    public float y;
    
    // destination coordinates, for movement animation
    // e.g.: assign random locations at start, but move to more sensible later; animate between different views
    public float newX;
    public float newY;
    
    public Vertex(Item i) {
        item = i;
        
        edge = new Edge[MAX_PEOPLE * MAX_SHOWS];
        
        x = round(width / 2);
        y = round(height / 2);
        
        newX = x;
        newY = y;
    }
    
    public void addEdge(Edge e) {
        edge[numberOfEdges] = e;
        numberOfEdges++;
    }
}

public class Edge {
    public Item item;
    
    public Vertex vertexA;
    public Vertex vertexB;
    
    public Edge(Item i, Vertex a, Vertex b) {
        item = i;
        vertexA = a;
        vertexB = b;
        
        vertexA.addEdge(this);
        vertexB.addEdge(this);
    }
}

public class MultiEdge extends Edge {
    public Edge edges[];
    public int numberOfEdges = 0;
    public float anim = 1.0;
    public Spring spring;
    public color colorMix;
    
    public MultiEdge(Item i, Vertex a, Vertex b) {
        super(i, a, b);
        
        edges = new Edge[max(MAX_PEOPLE, MAX_SHOWS)];
        this.addEdge(i, a, b);
        
        this.item = null;   // as a pre-caution, a MultiEdge instance should not be associated with an item
    }
    
    public void addEdge(Item item, Vertex a, Vertex b) {
        for (int i = 0; i < numberOfEdges; i++) {
            //if (edges[i].item.name.equals(item.name)) {
            if (edges[i].item.id == item.id) {
                return;
            }
        }
        
        edges[numberOfEdges] = new Edge(item, a, b);
        numberOfEdges++;
        
        // todo: improve on colour blending? seems to mix poorly
        // colour this aggregate edge as a crude mix of the others
        if (edges[0].item instanceof Person) {
            float hueTotal = 0;
            float satTotal = 0;
            float brightTotal = 0;
            float alphaTotal = 0;
            
            for    (int i = 0; i < numberOfEdges; i++) {
                hueTotal += hue(((Person) edges[i].item).c);
                satTotal += saturation(((Person) edges[i].item).c);
                brightTotal += brightness(((Person) edges[i].item).c);
                alphaTotal += alpha(((Person) edges[i].item).c);
            }
            colorMode(HSB);
            this.colorMix = color(hueTotal / (float) numberOfEdges, satTotal / (float) numberOfEdges, brightTotal / (float) numberOfEdges, alphaTotal / (float) numberOfEdges);

        }
    }
    
    public int visibleItems() {
        int visibleItems = 0;
        
        for (int i = 0; i < numberOfEdges; i++) {
            if (edges[i].item.visible() == true) {
                visibleItems++;
            }
        }
        
        return visibleItems;
    }
}
public class Data {
    private ArrayList showList = new ArrayList();            // must be populated first, to allow connectivity calculations to be made
    private ArrayList personList = new ArrayList();
    
    public ArrayList getShowList() {
        return this.showList;
    }
    
    public ArrayList getPersonList() {
        return this.personList;
    }

    // returns number of people connecting two shows
    int countConnections(int j, int k) {
        int c = 0;
    
        for (int i = 0; i < personList.size(); i++) {
            if (((Person) personList.get(i)).isInShow(j) && ((Person) personList.get(i)).isInShow(k)) {
                c++;
            }
        }
    
        return c;
    }
    
    public Data() {
        showList.clear();
        personList.clear();

        // begin JavaScript
        for (var item in UsedData.show) {
            showList.add(new Show(UsedData.show[item].id, UsedData.show[item].title, UsedData.show[item].year));
        }

        for (var item in UsedData.person) {
            var getShows = findShowsWithPersonIdFast(UsedData.person[item].id);
            personList.add(new Person(UsedData.person[item].id, UsedData.person[item].name, UsedData.person[item].dob, getShows, showList));
        }
        // end JavaScript
    }
}
