#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>

/* 1. CONFIGURATION */
#define WIFI_SSID       "YOUR_WIFI_NAME"
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"

#define API_KEY         "YOUR_FIREBASE_API_KEY"
#define PROJECT_ID      "YOUR_PROJECT_ID" 
#define USER_ID         "YOUR_USER_ID_HERE" // The ID of the user in Firestore

/* 2. PIN DEFINITIONS */
const int BUTTON_PIN = 27;  
const int MOTOR_1_PIN = 26; 
const int MOTOR_2_PIN = 25; 

/* 3. FIREBASE OBJECTS */
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

void setup() {
  Serial.begin(115200);
  
  // Setup Pins
  pinMode(MOTOR_1_PIN, OUTPUT);
  pinMode(MOTOR_2_PIN, OUTPUT);
  digitalWrite(MOTOR_1_PIN, LOW);
  digitalWrite(MOTOR_2_PIN, LOW);
  
  pinMode(BUTTON_PIN, INPUT_PULLUP); 

  // Setup WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nConnected");

  // Setup Firebase
  config.api_key = API_KEY;
  config.project_id = PROJECT_ID;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase Auth Success");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.test_mode ? "Error" : config.signer.tokens.error.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  if (Firebase.ready() && signupOK) {
    
    // Check if Button Pressed
    if (digitalRead(BUTTON_PIN) == LOW) {
      Serial.println("Button Pressed. Searching for active schedule...");
      checkAndDispense();
      delay(2000); // Prevent double press
    }
  }
}

void checkAndDispense() {
  // Path to the user's schedules collection
  String collectionPath = "users/" + String(USER_ID) + "/medSchedules";

  // Get all schedules for this user
  if (Firebase.Firestore.getDocuments(&fbdo, PROJECT_ID, "", collectionPath.c_str(), "", "", "")) {
    
    // The result is a large JSON document containing all schedules
    FirebaseJson payload;
    payload.setJsonData(fbdo.payload().c_str());

    // We need to iterate through the documents to find one where isTimeToTake is true
    size_t len = payload.iteratorBegin();
    FirebaseJson::IteratorValue value;
    
    bool pillDispensed = false; 

    for (size_t i = 0; i < len; i++) {
      value = payload.valueAt(i);
      
      // Each 'value' is a document. We check the fields.
      // Note: The structure is complex. We verify if this entry has the specific field set to true.
      
      // Check if "isTimeToTake" is true
      FirebaseJsonData isTimeData;
      value.value.get(isTimeData, "name/fields/isTimeToTake/booleanValue"); 
      // Note: If using getDocuments, the path inside JSON often includes 'documents' array.
      // Simpler approach: We parse the raw JSON string of this specific document item
      
      FirebaseJson docJson;
      docJson.setJsonData(value.value.toString().c_str());
      
      FirebaseJsonData fieldData;
      docJson.get(fieldData, "fields/isTimeToTake/booleanValue");

      if (fieldData.success && fieldData.boolValue == true) {
        
        // FOUND A SCHEDULE!
        Serial.println("Active Schedule Found.");

        // 1. Get Document ID (Name) to update later
        FirebaseJsonData nameData;
        docJson.get(nameData, "name");
        String fullPath = nameData.stringValue; 
        // fullPath looks like: projects/proj-id/databases/(default)/documents/users/uid/medSchedules/docID
        // We need just the relative path for the update function: users/uid/medSchedules/docID
        String relativePath = fullPath.substring(fullPath.indexOf("users/"));

        // 2. Get Tube Number
        int tubeNum = 1; // Default
        docJson.get(fieldData, "fields/tubeNumber/integerValue");
        if(fieldData.success) tubeNum = fieldData.intValue;

        // 3. Get Pills Left
        int pillsLeft = 0;
        docJson.get(fieldData, "fields/pillsLeft/integerValue");
        if(fieldData.success) pillsLeft = fieldData.intValue;

        // 4. DISPENSE
        if (tubeNum == 1) {
          Serial.println("Dispensing Tube 1");
          digitalWrite(MOTOR_1_PIN, HIGH);
          delay(1000);
          digitalWrite(MOTOR_1_PIN, LOW);
        } else {
          Serial.println("Dispensing Tube 2");
          digitalWrite(MOTOR_2_PIN, HIGH);
          delay(1000);
          digitalWrite(MOTOR_2_PIN, LOW);
        }

        // 5. UPDATE DATABASE
        updateSchedule(relativePath, pillsLeft - 1);
        
        pillDispensed = true;
        break; // Stop looking after dispensing one
      }
    }
    
    payload.iteratorEnd();
    
    if (!pillDispensed) {
      Serial.println("No schedules are currently due.");
    }

  } else {
    Serial.println("Failed to get schedules.");
    Serial.println(fbdo.errorReason());
  }
}

void updateSchedule(String docPath, int newCount) {
  
  FirebaseJson content;
  
  // Set isTimeToTake to false
  content.set("fields/isTimeToTake/booleanValue", false);
  
  // Set new pill count
  content.set("fields/pillsLeft/integerValue", newCount);

  // Patch (Update) the document
  if (Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "" /* db default */, docPath.c_str(), &content, "isTimeToTake,pillsLeft")) {
    Serial.println("Database updated successfully.");
  } else {
    Serial.println("Update failed.");
    Serial.println(fbdo.errorReason());
  }
}