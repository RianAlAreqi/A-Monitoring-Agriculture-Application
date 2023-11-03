#include <DHT.h>
#include <SoftwareSerial.h>

// Replace with your Wi-Fi SSID and password
const char *SSID = "your_wifi_ssid";
const char *PASSWORD = "your_wifi_password";

#define APN "diginet"
#define ThingSpeak_URL "api.thingspeak.com/update"
String ThingSpeak_api_key = "4FXWKIRRLBAKE9WH";

// Create a SoftwareSerial object for the ESP8266 module
// SoftwareSerial esp8266(10, 11); // RX, TX
SoftwareSerial SIM900(10, 11);

#define DHTPIN 2
#define DHTTYPE DHT11
#define RAIN_SENSOR A0
#define SOIL_MOISTURE_SENSOR A1

DHT dht(DHTPIN, DHTTYPE);

const int RAIN_SENSOR_DRY_VALUE = 642;
const int RAIN_SENSOR_WET_VALUE = 425;

const int SOIL_MOISTURE_DRY_VALUE = 645;
const int SOIL_MOISTURE_WET_VALUE = 460;

const float RAIN_SENSOR_SENSITIVITY = 1.0;   // Adjust the sensitivity of the rain sensor (1.0 = default)
const float SOIL_MOISTURE_SENSITIVITY = 1.0; // Adjust the sensitivity of the soil moisture sensor (1.0 = default)
void send_to_serial()
{
    while (SIM900.available() != 0)
    {                                      /* If data is available on serial port */
        Serial.write(char(SIM900.read())); /* Print character received on to the serial monitor */
    }
}
void sendToThingSpeakSIM900A(float temperature, float humidity, float rain_percentage, float soil_moisture_percentage)
{
  String HTTP_POST_DATA = "api_key=" + ThingSpeak_api_key + "&field1=" + String(temperature) + "&field2=" + String(humidity) + "&field3=" + String(rain_percentage) + "&field4=" + String(soil_moisture_percentage);

  int DELAY_VALUE = 5000;
  // Test AT command
  SIM900.println("AT");
  Serial.print("Test AT command: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Check GPRS attachment
  SIM900.println("AT+CGATT?");
  Serial.print("Check GPRS attachment: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Set GPRS connection type
  SIM900.println("AT+SAPBR=3,1,\"Contype\",\"GPRS\"");
  Serial.print("Set GPRS connection type: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Set APN
  SIM900.println("AT+SAPBR=3,1,\"APN\",\"" + String(APN) + "\"");
  Serial.print("Set APN: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Activate bearer profile
  SIM900.println("AT+SAPBR=1,1");
  Serial.print("Activate bearer profile: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Query bearer profile
  SIM900.println("AT+SAPBR=2,1");
  Serial.print("Query bearer profile: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Initialize HTTP service
  SIM900.println("AT+HTTPINIT");
  Serial.print("Initialize HTTP service: ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Set HTTP parameters - CID
  SIM900.println("AT+HTTPPARA=\"CID\",1");
  Serial.print("Set HTTP parameters (CID): ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Set HTTP parameters - URL
  SIM900.println("AT+HTTPPARA=\"URL\",\"" + String(ThingSpeak_URL) + "\"");
  Serial.print("Set HTTP parameters (URL): ");
  send_to_serial(); // Print GSM Status an the Serial Output;
  delay(DELAY_VALUE);

  // Set HTTP data and timeout
  SIM900.println("AT+HTTPDATA=" + String(HTTP_POST_DATA.length()) + ",10000");
  Serial.print("Set HTTP data and timeout: ");
  send_to_serial(); //

// Print GSM Status an the Serial Output;
delay(DELAY_VALUE);

// Send HTTP_POST_DATA
SIM900.println(HTTP_POST_DATA);
Serial.print("Send HTTP POST data: ");
send_to_serial(); // Print GSM Status an the Serial Output;
delay(DELAY_VALUE);

// Start HTTP POST session
SIM900.println("AT+HTTPACTION=1");
Serial.print("Start HTTP POST session: ");
send_to_serial(); // Print GSM Status an the Serial Output;
delay(DELAY_VALUE);

// Terminate HTTP service
SIM900.println("AT+HTTPTERM");
Serial.print("Terminate HTTP service: ");
send_to_serial(); // Print GSM Status an the Serial Output;
delay(DELAY_VALUE);
}

/* void sendToThingSpeak(float temperature, float humidity, float rain_percentage, float soil_moisture_percentage) {
  esp8266.print("AT+CIPSTART=\"TCP\",\"");
  esp8266.print("api.thingspeak.com");
  esp8266.print("\",80\r\n");
  delay(2000);

  String data = "GET /update?api_key=" + String(API_KEY) +
                "&field1=" + String(temperature) +
                "&field2=" + String(humidity) +
                "&field3=" + String(rain_percentage) +
                "&field4=" + String(soil_moisture_percentage);

  esp8266.print("AT+CIPSEND=");
  esp8266.print(data.length() + 4);
  esp8266.print("\r\n");
  delay(2000);

  esp8266.print(data);
  esp8266.print("\r\n");
  delay(2000);
}
 */

float getPercentage(float value, float minValue, float maxValue)
{
  float percentage = 100.0 * (value - minValue) / (maxValue - minValue);
  return constrain(percentage, 0, 100);
}

void printSensorData(float temperature, float humidity, float rain_percentage, float soil_moisture_percentage)
{
  Serial.print("Temperature:");
  Serial.print(temperature);
  Serial.print(" Humidity:");
  Serial.print(humidity);
  Serial.print(" RainPercentage:");
  Serial.print(rain_percentage, 2);
  Serial.print(" SoilMoisturePercentage:");
  Serial.println(soil_moisture_percentage, 2);
}

void setup()
{
  Serial.begin(9600);
  // esp8266.begin(9600);
  dht.begin();
  SIM900.begin(9600);
  // esp8266.print("AT+CWJAP=\"");
  // esp8266.print(SSID);
  // esp8266.print("\",\"");
  // esp8266.print(PASSWORD);
  // esp8266.print("\"\r\n");
  // delay(5000);
}

void loop()
{
  delay(2000);
  //delay (60UL * 60UL * 1000UL);
  Serial.println("Reading sensor data..."); 

  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  int raw_rain_sensor_value = analogRead(RAIN_SENSOR);
  int raw_soil_moisture_value = analogRead(SOIL_MOISTURE_SENSOR);

  if (isnan(humidity) || isnan(temperature))
  {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }

  float rain_percentage = getPercentage(raw_rain_sensor_value * RAIN_SENSOR_SENSITIVITY, RAIN_SENSOR_DRY_VALUE, RAIN_SENSOR_WET_VALUE);
  float soil_moisture_percentage = getPercentage(raw_soil_moisture_value * SOIL_MOISTURE_SENSITIVITY, SOIL_MOISTURE_DRY_VALUE, SOIL_MOISTURE_WET_VALUE);
  printSensorData(temperature, humidity, rain_percentage, soil_moisture_percentage);
  // sendToThingSpeak(temperature, humidity, rain_percentage, soil_moisture_percentage);
  sendToThingSpeakSIM900A(temperature, humidity, rain_percentage, soil_moisture_percentage);
 // Serial.print("rain sensor");
 // Serial.print(raw_rain_sensor_value);
 // Serial.print("soil sensor");
  //Serial.print(raw_soil_moisture_value);
}