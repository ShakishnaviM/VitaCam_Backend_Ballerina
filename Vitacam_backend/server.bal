import ballerina/http;
import ballerinax/mongodb;
import ballerina/log;

// Define the user record with username, email, and password fields
type User record {
    string username;
    string email;
    string password;
};

// Define the credentials record for sign-in
type Credentials record {
    string email;
    string password;
};

// Define the profile edit payload
type ProfileEdit record {
    string? username;
    string? email;
    string? password;
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

// Define the HTTP service with the correct base path `/auth`
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
            returns error? {
        json signupPayload = check req.getJsonPayload();
        User userDetails = check signupPayload.cloneWithType(User);

        // Check if the user already exists by username or email
        map<json> filter = { "$or": [{username: userDetails.username}, {email: userDetails.email}] };
        stream<User, error?> userStream = check self.userCollection->find(filter);
        
        if (userStream.next() is record {| User value; |}) {
            log:printError("User with the same username or email already exists");
            http:Response conflictResponse = new;
            conflictResponse.setTextPayload("User with the same username or email already exists");
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

    // POST resource for the `/signin` endpoint
    isolated resource function post signin(http:Caller caller, http:Request req) 
            returns error? {
        json signinPayload = check req.getJsonPayload();
        Credentials credentials = check signinPayload.cloneWithType(Credentials);

        // Check if the user exists by email
        map<json> emailFilter = {}; // Explicitly initialize the map
        emailFilter["email"] = credentials.email;

        stream<User, error?> userStream = check self.userCollection->find(emailFilter);

        // Retrieve the first result from the stream
        record {| User value; |}? userResult = check userStream.next();
        
        if (userResult is ()) {
            // If the email is not found, return user not found
            log:printError("User not found");
            http:Response userNotFoundResponse = new;
            userNotFoundResponse.setTextPayload("User not found");
            check caller->respond(userNotFoundResponse);
            return;
        } else {
            // Extract the user from the result
            User user = userResult.value;

            // If the user exists, check the password
            if (user.password != credentials.password) {
                log:printError("Invalid credentials");
                http:Response invalidCredsResponse = new;
                invalidCredsResponse.setTextPayload("Invalid credentials");
                check caller->respond(invalidCredsResponse);
                return;
            }

            // If credentials are valid, send success response
            http:Response response = new;
            response.setTextPayload("User signed in successfully");
            check caller->respond(response);
        }
    }

    // POST resource for the `/logout` endpoint
    isolated resource function post logout(http:Caller caller) returns error? {
        // This is a simple logout response for now (assuming no session management)
        http:Response response = new;
        response.setTextPayload("User logged out successfully");
        check caller->respond(response);
    }

    // PATCH resource for `/editProfile` endpoint
    isolated resource function patch editProfile(http:Caller caller, http:Request req) 
            returns error? {
        json editPayload = check req.getJsonPayload();
        ProfileEdit editDetails = check editPayload.cloneWithType(ProfileEdit);

        // Get the user email from the payload for identification
        if (editDetails.email is ()) {
            log:printError("Email is required to update profile");
            http:Response badRequestResponse = new;
            badRequestResponse.setTextPayload("Email is required to update profile");
            check caller->respond(badRequestResponse);
            return;
        }

        // Check if the user exists by email
        map<json> emailFilter = {}; // Explicitly initialize the map
        emailFilter["email"] = editDetails.email;

        stream<User, error?> userStream = check self.userCollection->find(emailFilter);
        record {| User value; |}? userResult = check userStream.next();
        
        if (userResult is ()) {
            // If the email is not found, return user not found
            log:printError("User not found");
            http:Response userNotFoundResponse = new;
            userNotFoundResponse.setTextPayload("User not found");
            check caller->respond(userNotFoundResponse);
            return;
        }

        // Update user details based on the provided data
        map<json> updateFields = {}; // Explicitly initialize the map
        if (editDetails.username is string) {
            updateFields["username"] = editDetails.username;
        }
        if (editDetails.password is string) {
            updateFields["password"] = editDetails.password;
        }

        // Apply the update to the user collection
        _ = check self.userCollection->updateOne(emailFilter, { "$set": updateFields });

        // Send success response
        http:Response response = new;
        response.setTextPayload("Profile updated successfully");
        check caller->respond(response);
    }
}
