#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

// 핀 설정
#define RST_PIN 9   // RFID 리더의 RST 핀
#define SS_PIN 10   // RFID 리더의 SDA 핀
#define LED_WAITING 7  // 대기 중 켜져 있는 LED 핀
#define LED_DONE 6     // RFID 읽은 후 1초 동안 켜지는 LED 핀
#define BT_RX 2        // HC-06 RX 핀
#define BT_TX 3        // HC-06 TX 핀

MFRC522 rfid(SS_PIN, RST_PIN); // RFID 리더 객체 생성
SoftwareSerial bluetooth(BT_RX, BT_TX); // HC-06 통신 설정

void setup() {
  Serial.begin(9600);         // 시리얼 모니터 시작
  bluetooth.begin(9600);      // HC-06 통신 시작
  SPI.begin();                // SPI 통신 시작
  rfid.PCD_Init();            // RFID 초기화

  pinMode(LED_WAITING, OUTPUT); // LED_WAITING 핀 출력 모드
  pinMode(LED_DONE, OUTPUT);    // LED_DONE 핀 출력 모드

  digitalWrite(LED_WAITING, HIGH); // 초기화: 대기 LED 켜기
  digitalWrite(LED_DONE, LOW);     // 초기화: 완료 LED 끄기

  Serial.println("HC-06 및 RFID 모듈 준비 완료");
}

void loop() {
  // RFID 태그가 감지되지 않으면 반복
  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;

  // 태그를 읽는 동안 대기 LED 끄기
  digitalWrite(LED_WAITING, LOW);

  // UID 정보 저장 및 출력
  String uid = "";
  Serial.print("RFID 태그 감지됨. UID: ");
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(rfid.uid.uidByte[i], HEX); // UID를 16진수로 출력
    uid += String(rfid.uid.uidByte[i], HEX); // UID를 문자열로 저장
  }
  Serial.println();

  // UID 정보를 Bluetooth로 전송
  bluetooth.print("UID: ");
  bluetooth.println(uid);
  Serial.println("UID 정보 HC-06으로 전송 완료");

  // 카드 처리 종료
  rfid.PICC_HaltA();

  // 완료 LED 켜기
  digitalWrite(LED_DONE, HIGH);
  delay(100); // 1초 동안 켜짐
  digitalWrite(LED_DONE, LOW); // 완료 LED 끄기

  // 다시 대기 LED 켜기
  digitalWrite(LED_WAITING, HIGH);
}
