import ballerina/http;
import ballerinax/mongodb;
import ballerina/log;

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

    // Existing signup, signin, logout, and editProfile functions here...

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

        // Send the vitamin info as the response
        http:Response response = new;
        response.setPayload(vitaminInfoResult.value);
        check caller->respond(response);
    }
}
