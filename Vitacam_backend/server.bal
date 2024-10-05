import ballerina/http;
import ballerinax/mongodb;
import ballerina/io;

// MongoDB configuration...
configurable string host = "localhost";
configurable int port = 27017;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;

final mongodb:Client mongoDb = check new (
    {
        connection: {
        serverAddress: {
            host,
            port
        },
        auth: <mongodb:ScramSha256AuthCredential>{
            username,
            password,
            database
        }
    }
    }
);

service on new http:Listener(9091) {
    private final mongodb:Database db;

    function init() returns error? {
        io:println("Connecting to database...");
        self.db = check mongoDb->getDatabase("Users");
        io:println("Connected to database.");
    }

    // Resource for the root path
    resource function get root() returns string {
        return "Welcome to the VitaCam backend!";
    }

    // Resource for customers
    resource function get customers() returns Customer | error {
        io:println("Fetching a single customer...");
        mongodb:Collection customersCollection = check self.db->getCollection("VitaCam_Auth");
        
        // Use findOne to retrieve a single document for testing
        Customer? customer = check customersCollection->findOne({});
        if (customer is ()) {
            return error("No customer found");
        }
        return customer;
    }
}

type Customer record {| 
    string id; 
    string name; 
    string email; 
    string address; 
    string contactNumber; 
|};
