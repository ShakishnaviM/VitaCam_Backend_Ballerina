import ballerina/http;
import ballerina/mime;

const string GEMINI_API_URL = "https://api.gemini.com/analyze";
const string API_KEY = "<YOUR_API_KEY>"; // Replace with your actual API key

function analyzeWithGeminiAPI(byte[] image) returns json|error {
    // Create an HTTP client to send the image to GeminiAPI
    http:Client geminiClient = check new (GEMINI_API_URL);

    // Create a multipart entity to hold the image
    mime:Entity bodyPart = new;
    bodyPart.setByteArray(image);
    bodyPart.setContentType(mime:IMAGE_JPEG);

    // Create a multipart form body
    mime:Entity multipartBody = new;
    multipartBody.setBodyParts([bodyPart]);
    multipartBody.setContentDisposition({ name: "image", filename: "uploaded_image.jpg" });

    // Create the HTTP request
    http:Request req = new;
    req.setEntity(multipartBody);
    req.addHeader("Authorization", "Bearer " + API_KEY);
    req.setContentType(mime:MULTIPART_FORM_DATA);

    // Send the request to the GeminiAPI and get the response
    http:Response res = check geminiClient->post("/analyzeImage", req);

    // Parse the response to JSON and return
    return res.getJsonPayload();
}
