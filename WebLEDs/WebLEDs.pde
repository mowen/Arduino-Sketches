/* WebLEDs.pde - Control the values of 5 LEDs using the Webduino library */

#include "Ethernet.h"
#include "WebServer.h"

static uint8_t mac[6] = { 0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x22 };
//static uint8_t ip[4] = { 192, 168, 1, 65 }; // IP at girlfriend's flat
static uint8_t ip[4] = { 192, 168, 1, 147 }; // IP at home

/* all URLs on this server will start with /buzz because of how we
 * define the PREFIX value.  We also will listen on port 80, the
 * standard HTTP service port */
#define PREFIX "/led"
WebServer webserver(PREFIX, 80);

int pins[] = { 2, 3, 4, 5, 6 }; // an array of pin numbers
int pinOffset = 2;
int num_pins = 5;               // the number of pins (i.e. the length of the array)
int pinSettings[5];

void initLEDs() {
  int i;
  for (i = 0; i < num_pins; i++) {
    pinMode(pins[i], OUTPUT);
    pinSettings[i] = LOW;
  }
}

void clearLEDs() {
  int i;
  for (i = 0; i < num_pins; i++)
    pinSettings[i] = LOW;
}

void setLEDs() {
  int i;
  for (i = num_pins - 1; i >= 0; i--)
    digitalWrite(pins[i], pinSettings[i]);
}

/* This command is set as the default command for the server.  It
 * handles both GET and POST requests.  For a GET, it returns a simple
 * page with some buttons.  For a POST, it saves the value posted to
 * the buzzDelay variable, affecting the output of the speaker */
void processRequest(WebServer &server, WebServer::ConnectionType type)
{    
  Serial.println("In processRequest...");
  
  if (type == WebServer::POST)
  {
    bool repeat;
    char name[16], value[16];
    int pinNum;
    
    clearLEDs();
    
    Serial.print("In POST...");
    
    do
    {
      /* readURLParam returns false when there are no more parameters
       * to read from the input.  We pass in buffers for it to store
       * the name and value strings along with the length of those
       * buffers. */
      repeat = server.readURLParam(name, 16, value, 16);
      
      Serial.print("Name: ");
      Serial.print(name);
      Serial.print("Value: ");
      Serial.print(value);
      Serial.print("\n");

      /* this is a standard string comparison function.  It returns 0
       * when there's an exact match.  We're looking for a parameter
       * named "led" here. */
      if (strcmp(name, "led") == 0)
      {
	/* use the STRing TO Unsigned Long function to turn the string
	 * version of the delay number into our integer buzzDelay
	 * variable */
         pinNum = strtoul(value, NULL, 10);
         pinSettings[pinNum - pinOffset] = HIGH;
      }
    } while (repeat);
    
    // after procesing the POST data, tell the web browser to reload
    // the page using a GET method. 
    server.httpSeeOther(PREFIX);
    return;
  }

  /* for a GET or HEAD, send the standard "it's all OK headers" */
  server.httpSuccess();

  /* we don't output the body for a HEAD request */
  if (type == WebServer::GET)
  {
    Serial.print("In GET...");

    /* store the HTML in program memory using the P macro */
    P(messageStart) = 
      "<html><head><title>Martin&apos;s LED Controller</title>"
      "<body>"
      "<h1>Change the value of an LED!</h1>"
      "<form action='/led' method='POST'>";
    server.printP(messageStart);  
      
    int i;
    for (i = 0; i < num_pins; i++) {
      char pinChar[1];
      itoa(pins[i], pinChar, 10);
      server.checkBox("led",  pinChar, pinChar, (pinSettings[i] == HIGH));
    }
    
    P(messageEnd) = 
      "<p><input type='submit' value='Submit' /></p>"
      "</form></body></html>";
    server.printP(messageEnd);    
  }
}

void setup()
{
  Serial.begin(9600); // For debugging
  
  initLEDs();
  
  // setup the Ethernet library to talk to the Wiznet board
  Ethernet.begin(mac, ip);

  /* register our default command (activated with the request of
   * http://x.x.x.x/buzz */
  webserver.setDefaultCommand(&processRequest);

  /* start the server to wait for connections */
  webserver.begin();
}

void loop()
{
  // process incoming connections one at a time forever
  webserver.processConnection();
  setLEDs();
}
