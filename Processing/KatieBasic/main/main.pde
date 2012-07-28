//Add Error of Temp to output
//Double Check manual of Thermistor

// Modified from http://arduino.cc/en/Tutorial/SerialCallResponse
/*
  Serial Call and Response
 Language: Processing
 
 This program sends an ASCII A (byte of value 65) on startup
 and repeats that until it gets some data in.
 Then it waits for a byte in the serial port, and 
 sends three sensor values whenever it gets a byte in.
 
 The handshake between ADL and processing is now being done with the clipboard.
 
 Ascii Codes:
 To Arduino:
 'B' - Send signal to turn on light
 'Z' - Send signal to turn off light
 
 From ADL:
 'X' - Start writing Temperature Measurements to File
 This means that ADL has started to take measurements
 
 'Y' - Stop writing Temperature Measurements to File
 This means that ADL has stopped taking measurements 
 
 */

// Font Tutorial at http://processing.org/learning/text
// Tutorial on Printing to a File: http://processing.org/reference/PrintWriter.html
// interfacia library can be found at: http://www.superstable.net/interfascia/   


import controlP5.*;
import processing.serial.*;
import java.io.File;

/****  BEGIN DECLARATIONS  ****/

int bgcolor = 155;                // Background Color
int xpos = 1;                     // horizontal position of the graph
Serial myPort;                    // the serial port
int[] serialInArray = new int[4]; //where we'll put what we receive
int serialCount = 0;              // a count of how many bytes we have recieved
int val_high;                     // First Part of Received int
int val_low;                      // Second Part of Received int
int val;                          // Full Received int
boolean firstContact = false;     // whether we've heard from the microcontroller
String clipped;                   // Stores Contents of the Clipboard
PFont font;                       // font to write display text
PFont fontMessage;                // font for user prompt messages
PFont inFont;                     // font to write filename input text
float volt;                       // The Voltage read by Arduino Pin A0
String voltVal;                   // The string version of variable "volt"
float temp;                       // the temperature converted from voltage (celcius)
PrintWriter output;             // Used to Write to file
int time_high;                  // First part of time Int
int time_low;                   // Second part of time int
int time;                       // Full time int
int serialport = 0;             // What serial port should be used
boolean light_isOn;
// One Global Call to create this (not supported in internal classes)
ControlP5 cp5;

/*
 manual Constants
 */

final double x3 = 0.049739;
final double x2 = 0.068603;
final double x1 = 4.397675;
final double x0 = 19.52896;



/****************************/
/****  BEGIN SETUP/DRAW  ****/
/****************************/

public void setup() {
  size(400, 400);                    // Display Window size
  background(bgcolor);               // Set Background Color for Display Window
  font = createFont("arial", 20); // See Above listed Font 
  fontMessage = createFont("arial", 20);  // create font for user prompt messages. 
  inFont = createFont("arial", 20);

  println(Serial.list());          // Print a list of the serial ports, for debugging purposes:

  serialport = 0;
  String portName = Serial.list()[serialport]; // Pick Serial Port to comunicate over (From Above List printed to screen)
  myPort = new Serial(this, portName, 9600); // Take this port and define the communication scheme. 
  // This scheme is an object "myPort" 
  // Should Get Filename from ADL
  cp.copyString("Not X");                    // Replace contents of Clipboard with "Not X"
  output = createWriter("testing01.txt");
  output.println("# temp = x3 * pow(v,3) + x2 * pow(v,2) + x1 * v + x0");
  output.println("# x0 = " + x0 );
  output.println("# x1 = " + x1 );
  output.println("# x2 = " + x2 );
  output.println("# x3 = " + x3 );
  output.println("# temperature measurements taken approximately every 300ms");
  output.println("# temperature measurements given in units of degrees celcius");
  output.println("#");
  output.println("#");
  output.println("# DATA");
  output.println("# Temp \t Voltage \t Time");
  output.println("# Celcius \t Volts \t mS");
  light_isOn = false;
} 

///**********************/
///****    getFileName()    ****/  Ended up not using this because the program would not wait for input
///**********************/
//
//public void getFileName() {
//  boolean received = false;
//  char letters[] = null;
//  String nameOfFile;
//  println("please type in file name");
//  while (received==false) {
//    if (keyPressed) {
//      if (key == '\n') {
//        received = true;
//        nameOfFile = new String(letters);
//        if (nameOfFile.equals(null)) {
//          nameOfFile = "Untitled";
//        }
//        output = createWriter(nameOfFile + ".txt");
//        println("filename accepted = " + nameOfFile + ".txt");
//        output.println("# temp = x3 * pow(v,3) + x2 * pow(v,2) + x1 * v + x0");
//        output.println("# x0 = " + x0 );
//        output.println("# x1 = " + x1 );
//        output.println("# x2 = " + x2 );
//        output.println("# x3 = " + x3 );
//        output.println("# temperature measurements taken approximately every 300ms");
//        output.println("# temperature measurements given in units of degrees celcius");
//        output.println("#");
//        output.println("#");
//        output.println("# DATA");
//        output.println("# Temp \t Voltage \t Time");
//        output.println("# Celcius \t Volts \t mS");
//       println("finished adding header");
//     }
//     else {
//       letters = append(letters, key);
//     }
//   }
// }
//}


/**********************/
/****    DRAW()    ****/
/**********************/

public void draw() {

  background (bgcolor); //Needed otherwise each loop just draws ontop of itself.
  /* Print Voltage to Window */
  textFont(font, 72);  
  fill(0);
  textAlign(CENTER);
  voltVal = nf(volt, 1, 3);
  text(voltVal + " V", width/2, 200);
}

/*******************************/
/****  BEGIN SERIALEVENT()  ****/
/*******************************/

void serialEvent(Serial myport) {
  println("in SerialEvent();");

  int inByte = myPort.read();          // read a byte from the serial port
  // if this is the first byte received, and it's an A,
  // clear the serial buffer and note that you've
  // had first contact from the microcontroller. 
  // Otherwise, add the incoming byte to the array:

  if (firstContact == false) {
    if (inByte == 'A') { 
      myPort.clear();                 // clear the serial buffer
      firstContact = true;            // you've had first contact from the microcontroller
      myPort.write('A');              // ask for more
    }
  } 
  else {
    // Add the latest byte from the serial port to array:
    serialInArray[serialCount] = inByte;
    serialCount++;
    // println("SerialCount = " +serialCount);      // For Debugging
    if (serialCount > 3) {             // if we have 4 bytes:
      time_high = serialInArray[0];     // The byte that was recieved first 
      // is the first 8 bits of time
      time_low = serialInArray[1];      // The byte that was recieved second
      // is the second 8 bits of time
      val_high = serialInArray[2]; //First 8 bits of val
      val_low = serialInArray[3];  //Second 8 bits of val
      //println("time_high = " + time_high + "time_low = " + time_low);     // For Debugging

      val = val_high << 8 | val_low;   // Place the first 8 bits in val_high 
      // before the last 8 bits in val_low
      // to make val
      time = time_high << 8 | time_low;
      //println(int(val));             // For Debugging 
      //println(time);                  //for Debugging
      volt = mapDouble(val, 0, 1023, 0.00, 5.00); //Change the range of val from 0-1023
      // to 0.00-5.00 to be a meaningful quantity (voltage)
      // println(volt);      // For Debugging


      //graph.pushVal((int) map(inByte, 0, 1023, 0, height));  // Add Corresponding value to graph object
      clipboardCheck();
      myPort.write('A');                // Send a capital A to request new sensor readings:   
      serialCount = 0;                  // Reset serialCount:
    }
  }
}




/*******************************/
/****  CLIPBOARD FUNCTIONS  ****/
/*******************************/

public void clipboardCheck() {
  /* Clipboard Operations */
  clipped = cp.pasteString();            // Get contents of Clipboard and store them in Clipped
  println(clipped);                      // Print Contents of Clipboard to screen (For Debugging)
  if (clipped.equals("X")) {             // If Signal "X" recieved from ADL (Through Clipboard)
    if (!light_isOn) {
      lightOn(); 
      light_isOn = true;
    }
    try {                                // Try writing data
      output.println(volt2temp(volt) + "\t" + volt + "\t" + time);     // If Start Signal "X" has been recieved write
    } 
    catch (NullPointerException ex) {
      println("Cannot write to file, no data to write. Or no file");
    }
  } 
  else if (clipped.equals("Y")) {

    try {
      output.flush();                      // Writes the remaining data to the file
      output.close();                      // Finishes the file
      lightOff();                          // Turn off light
      myPort.stop();                       // Stop Serial Communication to Arduino
      exit();                              // Exit Processing
    } 
    catch (NullPointerException ex) {  
      println("Couldn't flush/close file or exit port");
    }
  }
  else {
    delay(300);                         // Give it 0.3s and then test clipboard again.
    println("chose no action based on clipboard");
  }
  delay(1000);
}


/*******************************/
/****  CUSTOM FUNCTIONS  *******/
/*******************************/

/*  VOLT2TEMP
 */
public double volt2temp(float v) {
  double temp;
  temp = x3 * pow(v, 3) + x2 * pow(v, 2) + x1 * v + x0;
  return temp;
}


/*  MAPDOUBLE
 Change the range of x from range in_min to in_max
 to out_min to out_max
 */
float mapDouble(float x, float in_min, float in_max, float out_min, float out_max) {
  float result;
  result = (x-in_min)*(out_max - out_min)/(in_max -in_min) +out_min;
  return result;
}


/*  LIGHT ON/OFF FUNCTIONS
 */
void lightOn() {
  try {
    myPort.write('B');                    // Send signal (To Arduino) to turn on light
  }  
  catch (NullPointerException e) {
    println("Can't send lightOn ('B') to arduino, no serial connection detected");
  }
} // END lightOn()



void lightOff() {
  //println("LightOFF Main"); // Debugging Only
  try {
    myPort.write('Z');                // Will this work? myPort is defined in outer class...
    // Send signal (To Arduino) to turn on light
  } 
  catch (NullPointerException e) {
    println("Can't send lightOff ('Z') to arduino, no serial connection detected");
  }
} // END lightOff()

