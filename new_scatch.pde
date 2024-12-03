import processing.net.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.io.FileWriter;
import java.io.IOException;

Server s;
Client c;

String product = ""; // 제품명
String uid = ""; // UID (고정될 값)
String[] products = {"computer", "arduino", "mouse"};
String[] uids = {"49cae429", "e6a8c849", "20a545a7"};
int[] quantities = {100, 25, 45};  // 각 제품의 초기 수량 설정

// 입출고 수량을 저장할 변수
int incomingQuantity = -1; // -1로 초기화하여 비어 있는 상태를 나타냄

void setup() {
  size(600, 400);  // 창 크기 설정
  s = new Server(this, 12345);  // 서버 생성, 포트 12345
  
  
  /// 파일 생성 
  PrintWriter output = createWriter("C:/temp/49cae429.txt");
  int data = quantities[0];
  output.println("\t\t49cae429 : computer\n\n");
  output.println(data);
  output.close();
  output = createWriter("C:/temp/e6a8c849.txt");
  data = quantities[1];
  output.println("\t\te6a8c849 : arduino\n\n");
  output.println(data);
  output.close();
  output = createWriter("C:/temp/20a545a7.txt");
  output.println("\t\20a545a7 : mouse\n\n");
  data = quantities[2];
  output.println(data);
  output.close();
}




void draw() {
  background(255);  // 흰색 배rud
  displayInfo(0);
  delay(1000);
  
  c = s.available();  // 클라이언트 연결 확인
  if (c != null) {
    StringBuilder requestBody = new StringBuilder();
    String input;

    // 클라이언트로부터 데이터 읽기
    while ((input = c.readString()) != null) {
      requestBody.append(input);
    }

    // 요청 본문이 비어 있지 않은 경우 처리
    if (requestBody.length() > 0) {
      
      println("Received data: " + requestBody.toString()); // 수신된 데이터 출력
      String number = requestBody.toString();
      String result = getStringAfterPercent(number);
      println("Received data: " + result);////////////////////////////////////////////
      int result_result = int(result);
      displayInfo(result_result);
      result_result = 0;
      
      
      
      
      // CSV 형식으로 데이터 파싱 (UID, 입출고 수량)
      String[] inputs = requestBody.toString().trim().split(","); // 입력을 쉼표로 분리
      
      if (inputs.length > 0) {
        if (uid.isEmpty()) { // UID가 비어 있을 때만 읽기
          uid = inputs[0]; // 첫 번째 칸: UID
          if (uid.length() > 8) {
            uid = uid.substring(uid.length() - 8); // 마지막 8자리 추출
          }
          
          product = getProduct(uid); // UID에 해당하는 제품명 가져오기
        }
        
        if (inputs.length > 1) {
          try {
            incomingQuantity = Integer.parseInt(inputs[1]); // 두 번째 칸: 입출고 수량
          } catch (NumberFormatException e) {
            incomingQuantity = -1; // 숫자가 아닐 경우 비어 있는 상태로 설정
          }
        } else {
          incomingQuantity = -1; // 두 번째 칸이 비어 있을 경우
        }
        
        int quantity = getQuantity(product,0); // 해당 제품의 현재 수량 가져오기
        
        String response;
        
        if (incomingQuantity != -1) { 
          // 두 번째 칸이 채워져 있을 때: 입출고 수량과 수정된 현재 수량 포함하여 응답
          int updatedQuantity = quantity + incomingQuantity; 
          response = product + "," + updatedQuantity + "," + quantity + "," + getCurrentTime();
          
          updateProductFile(product, updatedQuantity); // 파일 수정 로직 호출
          
          updateQuantities(product, updatedQuantity); // quantities 배열 업데이트
        } else {
          // 두 번째 칸이 비어 있을 때: 제품명과 현재 수량만 응답
          response = product + "," + quantity; 
        }
        
        c.write("HTTP/1.1 200 OK\r\n");
        c.write("Content-Type: text/plain\r\n");  // 일반 텍스트로 변경
        c.write("\r\n");
        c.write(response);
        
        c.stop();  // 클라이언트 연결 종료
        
        println("받은 UID: " + uid + " -> 응답: " + response); // 처리된 정보 콘솔에 출력
      }
    }
  }
  
}

void displayInfo(int a) {
  textSize(20);  // 텍스트 크기 설정
  fill(0);  // 텍스트 색상 설정 (검정색)
  text("RFID UID: " + uid, 20, 40);  
  text("Product Name: " + product, 20, 80); 
  int quntity = getQuantity(product,a);
  text("Current Quantity: " +quntity, 20, 120); ////////////////////////////////////////////////////////////////////////////
  
  text("Current Time: " + getCurrentTime(), 20, height - 40); 
}

String getStringAfterPercent(String str) {
    int percentIndex = str.indexOf('%'); // '%' 문자의 인덱스 찾기
    
    if (percentIndex != -1 && percentIndex < str.length() - 1) {
        return str.substring(percentIndex + 1); // '%' 뒤의 문자열 반환
    }
    
    return "없음"; // '%'가 없거나 '%'가 마지막 문자일 경우 "없음" 반환
}

String getProduct(String uid) {
   for (int i = 0; i < uids.length; i++) {
     if (uids[i].equalsIgnoreCase(uid)) {
       return products[i]; 
     }
   }
   return "Unknown"; 
}

int getQuantity(String product,int a) {  ///////////////////////////////////////
   for (int i = 0; i < products.length; i++) {
     if (products[i].equalsIgnoreCase(product)) {
       quantities[i] = quantities[i]+a;
       if(i==0){
           String text = quantities[i] + "";
           appendToFile("C:/temp/49cae429.txt", text);
       }
       else if(i==1){
           String text = quantities[i] + "";
           appendToFile("C:/temp/e6a8c849.txt", text);
       }
       else if(i==2){
           String text = quantities[i] + "";
           appendToFile("C:/temp/20a545a7.txt", text);
       }
       return quantities[i]; 
     }
   }
   return 0; 
}

String getCurrentTime() {
    SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
    return sdf.format(new Date()); 
}

void updateProductFile(String productName, int updatedQuantity) {
    String fileName = productName + ".txt"; 
    
    try {
        FileWriter fw = new FileWriter(fileName);
        BufferedWriter bw = new BufferedWriter(fw);
        
        bw.write("Product Name: " + productName);
        bw.newLine();
        bw.write("Updated Quantity: " + updatedQuantity);
        
        bw.close();
        fw.close();
        
        println("File updated for product: " + productName + ", Updated quantity: " + updatedQuantity);
    } catch (IOException e) {
        e.printStackTrace();
    }
}

void updateQuantities(String productName, int updatedQuantity) {
    for (int i = 0; i < products.length; i++) {
        if (products[i].equalsIgnoreCase(productName)) {
            quantities[i] = updatedQuantity; 
            break;
        }
    }
}

void appendToFile(String filePath, String data) {
  try {
    // FileWriter 두 번째 매개변수로 true 전달하면 append 모드 활성화
    BufferedWriter writer = new BufferedWriter(new FileWriter(filePath, true));
    writer.write(data);
    writer.newLine();  // 줄바꿈
    writer.close();  // 파일 닫기
  } catch (IOException e) {
    println("파일 쓰기 오류: " + e.getMessage());
  }
}
