import ballerina/http;
import ballerinax/mongodb;
import ballerinax/googleapis.oauth2;

type User record {
    string username;
    string email;
    string password;
};

type Credentials record {
    string email;
    string password;
};

type ProfileEdit record {
    string? username;
    string? email;
    string? password;
};

// Define the structure for Vitamin Info
type VitaminInfo record {
    string vitamin;
    VitaminSource[] sources;
};

type VitaminSource record {
    string name;
    string consumption;
};

// Initialize MongoDB client
mongodb:Client mongoDb = check new ({
    connection: {
        serverAddress: {
            host: "localhost",
            port: 27017
        }
    }
});


// OAuth 2.0 configuration with your Client ID, Client Secret, and Redirect URI.
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string redirectUri = "http://localhost:8080/auth/callback";

// Define OAuth2 provider configurations
oauth2:ProviderConfig googleOAuthProvider = {
    authUrl: "https://accounts.google.com/o/oauth2/auth",
    tokenUrl: "https://oauth2.googleapis.com/token",
    clientId: clientId,
    clientSecret: clientSecret,
    redirectUrl: redirectUri,
    scopes: ["openid", "email", "profile"]
};

// Create OAuth2 client to interact with Google OAuth 2.0
oauth2:Client googleOAuthClient = check new(googleOAuthProvider);

service / on new http:Listener(8080) {

    mongodb:Database userDb;
    mongodb:Collection userCollection;
    mongodb:Collection vitaminInfoCollection;

    function init() returns error? {
        self.userDb = check mongoDb->getDatabase("userDB");
        self.userCollection = check self.userDb->getCollection("users");
        
        // Initialize vitaminInfo collection
        self.vitaminInfoCollection = check self.userDb->getCollection("vitaminInfo");
    }

     // Resource to handle GeminiAPI image analysis
    isolated resource function post analyzeImage(http:Caller caller, http:Request req) returns error? {
        // Extract the image from the request
        byte[] image = check req.getBinaryPayload();

        // Call the GeminiAPI function for analysis
        json analysisResult = check analyzeWithGeminiAPI(image);

        // Respond with the analysis result
        http:Response response = new;
        response.setPayload(analysisResult);
        check caller->respond(response);
    }

    // New resource to fetch vitamin details based on the selected vitamin
    isolated resource function get vitaminInfo(http:Caller caller, http:Request req) returns error? {
        // Extract the vitamin name from the query parameter
        string? vitamin = req.getQueryParamValue("vitamin");

        if vitamin is () {
            http:Response badRequestResponse = new;
            badRequestResponse.setTextPayload("Vitamin name is required");
            check caller->respond(badRequestResponse);
            return;
        }

        // Create a filter to search the vitaminInfo collection by vitamin name
        map<json> filter = { "vitamin": vitamin };

        // Fetch the corresponding vitamin information from the database
        stream<VitaminInfo, error?> vitaminInfoStream = check self.vitaminInfoCollection->find(filter);

        record {| VitaminInfo value; |}? vitaminInfoResult = check vitaminInfoStream.next();

        if (vitaminInfoResult is ()) {
            // If no vitamin info is found, return a "not found" response
            http:Response notFoundResponse = new;
            notFoundResponse.setTextPayload("Vitamin information not found");
            check caller->respond(notFoundResponse);
            return;
        }

        // Convert VitaminInfo to json
        json vitaminInfoJson = vitaminInfoResult.value.toJson();

        // Send the vitamin info as the response
        http:Response response = new;
        response.setPayload(vitaminInfoJson);
        check caller->respond(response);
    }
}
