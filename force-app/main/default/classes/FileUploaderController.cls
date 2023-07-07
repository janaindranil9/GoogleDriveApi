public with sharing class FileUploaderController {
  public static String getAccessToken() {
    // Implement your authentication process to retrieve the access token
    // This could involve calling an authentication service or making a HTTP request to retrieve the token
    // Return the access token once obtained
  
    // Example implementation using Named Credentials in Salesforce
    // Replace 'Google_Drive_Named_Credential' with your actual Named Credential name
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:GoogleDriveApi/oauth2/token');
    request.setMethod('POST');
    HttpResponse response = http.send(request);
    String accessToken = '';
    
    if (response.getStatusCode() == 200) {
      Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
      accessToken = (String) jsonResponse.get('access_token');
    }
    
    return accessToken;
  }  
    @AuraEnabled
  public static Map<String, String> uploadFileToGoogleDrive(String fileName, String base64Data) {
    // Call Google Drive API to upload the file and obtain the fileId
    // Implement the logic to interact with Google Drive API here
    // Return the fileId and any other relevant information
    // Define the Google Drive API endpoint for file uploads
    String googleDriveUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';

    // Construct the request body with the file metadata and content
    String boundary = '----------------------------' + Datetime.now().getTime();
    String requestBody = '--' + boundary + '\r\n' +
                         'Content-Type: application/json\r\n\r\n' +
                         '{"name":"' + fileName + '"}\r\n' +
                         '--' + boundary + '\r\n' +
                         'Content-Type: application/octet-stream\r\n\r\n' +
                         base64Data + '\r\n' +
                         '--' + boundary + '--';

    // Make the HTTP request to Google Drive API
    HttpRequest request = new HttpRequest();
    request.setEndpoint(googleDriveUrl);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'multipart/related; boundary=' + boundary);
    request.setHeader('Authorization', 'Bearer ' + getAccessToken()); // Use your method to get the access token
    request.setBody(requestBody);
    HttpResponse response = new Http().send(request);

    // Parse the response to obtain the fileId
    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    String fileId = (String) jsonResponse.get('id');

    // Return the fileId and any other relevant information
    Map<String, String> result = new Map<String, String>();
    result.put('fileId', fileId);
    // Add more relevant information to the result if needed
    return result;
  }
  @AuraEnabled
  public static Map<String, Object> getFileDetailsFromGoogleDrive(String fileId) {
    // Define the Google Drive API endpoint for file details
    String googleDriveUrl = 'https://www.googleapis.com/drive/v3/files/' + fileId;

    // Make the HTTP request to Google Drive API
    HttpRequest request = new HttpRequest();
    request.setEndpoint(googleDriveUrl);
    request.setMethod('GET');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Authorization', 'Bearer ' + getAccessToken()); // Use your method to get the access token

    HttpResponse response = new Http().send(request);

    // Parse the response to obtain the file details
    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

    return jsonResponse;
  }

  @AuraEnabled
  public static void createChildRecords(String parentId, String fileId) {
    // Implement the logic to create child records for each selected parent record
    // Store the Google Drive file details (fileId, fileName, etc.) in the child records
    List<CustomChildObject__c> childRecords = new List<CustomChildObject__c>();

    // Retrieve the selected parent records
    List<ParentObject__c> parentRecords = [SELECT Id, Name FROM ParentObject__c WHERE Id = :parentId];

    // Create child records for each selected parent record
    for (ParentObject__c parent : parentRecords) {
      CustomChildObject__c childRecord = new CustomChildObject__c();
      childRecord.Parent__c = parent.Id;
      childRecord.FileId__c = fileId;
      childRecord.Name =(String) (getFileDetailsFromGoogleDrive(fileId).get('name'));
       // Replace with your method to retrieve file details from Google Drive
      // Set any other relevant fields in the child record

      childRecords.add(childRecord);
    }

    // Insert the child records
    if (!childRecords.isEmpty()) {
      insert childRecords;
    }
  }
}
