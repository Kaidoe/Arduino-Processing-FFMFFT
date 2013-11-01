
// Forward Fast MoFo Fourier Transform
// Andrew Briggs .. kaidoe.org

import controlP5.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import javax.swing.JFileChooser;
import processing.serial.*; 

ControlP5 cp5;
Minim minim;
AudioPlayer choon;
FFT fft;
Serial port;

int grid_margin = 8;
int grid_size = 16;
int grid_columns = 42;
int grid_rows = 22;
int grid_width = grid_size*grid_columns+(grid_margin*2);
int grid_height = grid_size*grid_rows+(grid_margin*2);

int grid_lc = 30;
int grid_rc = 5;

int color_text = color(242, 238, 234);
int color_bg = color(35, 31, 32);
int color_cp5_fg = color(241, 94, 0);
int color_cp5_bg = color(241, 156, 40);
int color_cp5_active = color(161, 46, 51);
int color_cp5_textfield = color(35, 31, 32);

int fft_samples = 32;
boolean fft_lp, fft_bp, fft_hp;

int eq_size = 32;
float eq_gain = 0.7;
int eq_gaps = fft_samples-1;
int eq_padding = 2;
int eq_val, eq_barheight;
float eq_bar_width = (((grid_size*eq_size)-eq_gaps)/fft_samples);
float eq_width = eq_bar_width*fft_samples+(fft_samples-2)+eq_padding*2;
float eq_height = 140;


int filter_lp_max = 3;
int filter_lp_thresh = 37;
int filter_bp_min = 5;
int filter_bp_max = 9;
int filter_bp_thresh = 58;
int filter_hp_min = 12;
int filter_hp_thresh = 5;

Textlabel cp5LabelTitle, cp5LabelSubTitle;
Textfield cp5File;
Range cp5BPRange;
Slider cp5LPMax, cp5HPMin, cp5LPThresh, cp5BPThresh, cp5HPThresh, cp5EQGain;

void setup() {

  port = new Serial(this, Serial.list()[0], 9600); 

  size(grid_width, grid_height);
  noStroke();

  cp5 = new ControlP5(this);

  // Title Text

  cp5.addTextlabel("label1")
    .setText("Forward Fast-MoFo-Fourier-Transform")
      .setPosition(g_px(0), g_px(0))
        .setColorValue(color_text)
          .setFont(createFont("Verdana", 14))
            ;

  cp5.addTextlabel("label2")
    .setText("LP, BP, HP filters and flashing LED tekniq")
      .setPosition(g_px(0), g_px(1))
        .setColorValue(color_text)
          .setFont(createFont("Verdana", 10))
            ;

  cp5LPMax =   cp5.addSlider("LP Max")
    .setBroadcast(false) 
      .setPosition(g_px(0), g_px(3))
        .setSize(g_sz(grid_lc), 20)
          .setRange(0, fft_samples)
            .setValue(filter_lp_max)
              .setDecimalPrecision(0)
                .setColorForeground(color_cp5_fg)
                  .setColorBackground(color_cp5_bg)
                    .setColorActive(color_cp5_active)
                      .setBroadcast(true)
                        ;

  cp5LPThresh = cp5.addSlider("LP Threshold")
    .setBroadcast(false) 
      .setPosition(g_px(grid_lc+3), g_px(3))
        .setSize(g_sz(grid_rc), 20)
          .setRange(0, 100)
            .setValue(filter_lp_thresh)
              .setDecimalPrecision(0)
                .setColorForeground(color_cp5_fg)
                  .setColorBackground(color_cp5_bg)
                    .setColorActive(color_cp5_active)
                      .setBroadcast(true)
                        ;          

  cp5BPRange = cp5.addRange("BP Range")
    // disable boradcasting since setRange and setRangeValues will trigger an event
    .setBroadcast(false) 
      .setPosition(g_px(0), g_px(5))
        .setSize(g_sz(grid_lc), 20)
          .setDecimalPrecision(0)
            .setHandleSize(20)
              .setRange(0, fft_samples)
                .setRangeValues(filter_bp_min, filter_bp_max)
                  // after the initialization we turn broadcast back on again
                  .setColorForeground(color_cp5_fg)
                    .setColorBackground(color_cp5_bg)
                      .setColorActive(color_cp5_active)
                        .setBroadcast(true)  
                          ;

  cp5BPThresh = cp5.addSlider("BP Threshold")
    .setBroadcast(false) 
      .setPosition(g_px(grid_lc+3), g_px(5))
        .setSize(g_sz(grid_rc), 20)
          .setRange(0, 100)
            .setValue(filter_bp_thresh)
              .setDecimalPrecision(0)
                .setColorForeground(color_cp5_fg)
                  .setColorBackground(color_cp5_bg)
                    .setColorActive(color_cp5_active)
                      .setBroadcast(true)
                        ;              

  cp5HPMin   = cp5.addSlider("HP Min")
    .setBroadcast(false) 
      .setPosition(g_px(0), g_px(7))
        .setSize(g_sz(grid_lc), 20)
          .setRange(0, fft_samples)
            .setValue(filter_hp_min)
              .setDecimalPrecision(0)
                .setColorForeground(color_cp5_bg)
                  .setColorBackground(color_cp5_fg)
                    .setColorActive(color_cp5_active)
                      .setBroadcast(true)
                        ;

  cp5HPThresh = cp5.addSlider("HP Threshold")
    .setBroadcast(false) 
      .setPosition(g_px(grid_lc+3), g_px(7))
        .setSize(g_sz(grid_rc), 20)
          .setRange(0, 100)
            .setValue(filter_hp_thresh)
              .setDecimalPrecision(0)
                .setColorForeground(color_cp5_fg)
                  .setColorBackground(color_cp5_bg)
                    .setColorActive(color_cp5_active)
                      .setBroadcast(true)
                        ;  


  cp5File =   cp5.addTextfield("No file loaded.")
    .setPosition(g_px(0), g_px(9))
      .setSize(g_sz(15), 20)
        //.setFont(font)
        .setColor(color_cp5_textfield)
          .setColorForeground(color_cp5_fg)
            .setColorBackground(color_cp5_bg)
              .setColorActive(color_cp5_active)
                ;

  cp5.addButton("open1")
    .setPosition(g_px(16), g_px(9))
      .setSize(g_sz(4), 20)
        .setCaptionLabel("Open MP3")
          //.setFont(font)
          //.setColor(color_cp5_textfield)
          .setColorForeground(color_cp5_fg)
            .setColorBackground(color_cp5_bg)
              .setColorActive(color_cp5_active)
                ; 
  cp5.addButton("play1")
    .setPosition(g_px(21), g_px(9))
      .setSize(g_sz(4), 20)
        .setCaptionLabel("Play")
          //.setFont(font)
          //.setColor(color_cp5_textfield)
          .setColorForeground(color_cp5_fg)
            .setColorBackground(color_cp5_bg)
              .setColorActive(color_cp5_active)
                ;  
  cp5.addButton("stop1")
    .setPosition(g_px(26), g_px(9))
      .setSize(g_sz(4), 20)
        .setCaptionLabel("Stop")
          //.setFont(font)
          //.setColor(color_cp5_textfield)
          .setColorForeground(color_cp5_fg)
            .setColorBackground(color_cp5_bg)
              .setColorActive(color_cp5_active)
                ;

  cp5EQGain = cp5.addSlider("EQ Gain")
    .setBroadcast(false) 
      .setPosition(g_px(grid_lc+3), g_px(9))
        .setSize(g_sz(grid_rc), 20)
          .setRange(0, 2)
            .setValue(eq_gain)
              .setDecimalPrecision(1)
                .setColorForeground(color_cp5_fg)
                  .setColorBackground(color_cp5_bg)
                    .setColorActive(color_cp5_active)
                      .setBroadcast(true)
                        ; 

  cp5.addTextlabel("label3")
    .setText("LP Filter State")
      .setPosition(g_px(33), g_px(12))
        .setColorValue(color_text)
          .setFont(createFont("Verdana", 10))
            ;  
  cp5.addTextlabel("label4")
    .setText("BP Filter State")
      .setPosition(g_px(33), g_px(15))
        .setColorValue(color_text)
          .setFont(createFont("Verdana", 10))
            ;   
  cp5.addTextlabel("label5")
    .setText("HP Filter State")
      .setPosition(g_px(33), g_px(18))
        .setColorValue(color_text)
          .setFont(createFont("Verdana", 10))
            ;


  minim = new Minim(this);
  choon = minim.loadFile("audio.mp3", 2048);
  //choon.loop();

  fft = new FFT(choon.bufferSize(), choon.sampleRate());
  fft.window(FFT.HAMMING);
  fft.linAverages(fft_samples);
}


public void open1() {

  openFile();
}


void openFile() {
  String loadPath = selectInput();  // Opens file chooser
  if (loadPath == null) {
    // If a file was not selected
    println("No file was selected...");
  } 
  else {
    // If a file was selected, print path to file
    choon.close();
    choon = minim.loadFile("loadPath", 2048);
    fft = new FFT(choon.bufferSize(), choon.sampleRate());
    fft.window(FFT.HAMMING);
    fft.linAverages(fft_samples);
  }
}

public void play1() {
  choon.loop();
}
public void stop1() {
  choon.pause();
}

public int envelope(int t, int x, int y) {

  int res = 3*(t^2)*x - y - 2 * t^3;

  return res;
}

public int myenvelope( int x, int y ) {
  return (x/x)*y;
}

void draw() {
  background(color_bg);    
  filter_lp_max = int(cp5LPMax.getValue());
  filter_lp_thresh = int(cp5LPThresh.getValue());
  filter_bp_min = int(cp5BPRange.getMin());
  filter_bp_max = int(cp5BPRange.getMax());
  filter_bp_thresh = int(cp5BPThresh.getValue());
  filter_hp_min = int(cp5HPMin.getValue());
  filter_hp_thresh = int(cp5HPThresh.getValue());
  eq_gain = cp5EQGain.getValue();

  fft_lp = false;
  fft_bp = false;
  fft_hp = false;

  stroke(color_cp5_fg);
  fill(color_cp5_bg);
  rect(g_px(0), g_px(12), int(eq_width), eq_height);
  noStroke();
  fill(color_cp5_fg);

  fft.forward(choon.mix);

  for (int i=0; i<fft_samples;i++) {
    //eq_val = int(fft.getBand(i*(choon.bufferSize()/fft_samples))*eq_gain);

    eq_val = int(fft.getAvg(i)*eq_gain);
    eq_val = abs(eq_val * envelope(i, 0, eq_val));

    if (i==0) {
      eq_val=0;
    };

    if (eq_val>eq_height) { 
      fill(color_cp5_active);
    } 
    else { 
      fill(color_cp5_fg);
    };
    rect((i*eq_bar_width+i)+float(g_px(0)+eq_padding), max(0, eq_height-eq_val)+float(g_px(12)), eq_bar_width, min(eq_height, eq_val));

    if (i<filter_lp_max &&  eq_val > filter_lp_thresh) {
      fft_lp = true;
    }
    if (i<filter_bp_max && i>filter_bp_min &&  eq_val > filter_bp_thresh) {
      fft_bp = true;
    }
    if (i>filter_hp_min &&  eq_val > filter_hp_thresh) {
      fft_hp = true;
    }
    fire_filters(fft_lp, fft_bp, fft_hp);
  }
}

void fire_filters(boolean fft_lp, boolean fft_bp, boolean fft_hp) {
  fill(color_cp5_bg);
  if (fft_lp) { 
    fill(color_cp5_fg);
  } 
  rect(g_px(33), g_px(13), g_sz(6), 20);
  fill(color_cp5_bg);
  if (fft_bp) { 
    fill(color_cp5_fg);
  } 
  rect(g_px(33), g_px(16), g_sz(6), 20);
  fill(color_cp5_bg);
  if (fft_hp) { 
    fill(color_cp5_fg);
  } 
  rect(g_px(33), g_px(19), g_sz(6), 20);

int buf = 0;

if (fft_lp) { buf += 1; }
if (fft_bp) { buf += 2; }
if (fft_hp) { buf += 4; }

port.write(byte(buf));



}

int g_px(int loc) {
  return loc * grid_size + grid_margin;
}
int g_sz(int blocks) {
  return blocks * grid_size;
}

