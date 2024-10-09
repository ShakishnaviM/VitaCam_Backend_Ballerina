import ballerina/http;
import ballerinax/mongodb;
import ballerina/log;

type User record {
    string username;
    string password;
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

// Define the HTTP service with the correct path
service / on new http:Listener(8080) {

    // MongoDB Database and Collection initialization
    mongodb:Database userDb;
    mongodb:Collection userCollection;

    function init() returns error? {
        self.userDb = check mongoDb->getDatabase("userDB");
        self.userCollection = check self.userDb->getCollection("users");
    }

    // POST resource for the `/signup` endpoint
    isolated resource function post signup(http:Caller caller, http:Request req) 
            returns error?  { // Marking the resource function as 'isolated'
        json signuppayload = check req.getJsonPayload();
        User userDetails = check signuppayload.cloneWithType(User);

        // Check if the user already exists
        map<json> filter = {username: userDetails.username};
        stream<User, error?> userStream = check self.userCollection->find(filter);
        if (userStream.next() is record {| User value; |}) {
            log:printError("User already exists");
            http:Response conflictResponse = new;
            conflictResponse.setTextPayload("User already exists");
            check caller->respond(conflictResponse);
            return;
        }

        // Insert the new user into MongoDB
        check self.userCollection->insertOne(userDetails);

        // Send success response
        http:Response response = new;
        response.setTextPayload("User signed up successfully");
        check caller->respond(response);
    }
}
