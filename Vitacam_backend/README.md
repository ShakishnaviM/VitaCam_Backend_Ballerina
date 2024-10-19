Here’s a `README.md` file to help users set up and run your project, including connecting to MongoDB and getting the Google API key for the GeminiAPI.

---

# Project Setup

This project integrates a Ballerina backend with MongoDB and Google GeminiAPI to handle user data, vitamin information, and perform image analysis using the Gemini API.

## Prerequisites

Before running this project, ensure you have the following:

- **Ballerina** installed on your machine ([Download Ballerina](https://ballerina.io/downloads/)).
- **MongoDB** installed locally or have access to a remote MongoDB instance.
- **Google API Key** for accessing GeminiAPI.

## Setup Instructions

### 1. MongoDB Setup

- Download and install **MongoDB** from [here](https://www.mongodb.com/try/download/community).
- Install **MongoDB Compass** (GUI) from [here](https://www.mongodb.com/products/compass).
- Once MongoDB and Compass are installed, follow the steps below:

1. Open **MongoDB Compass** and connect to your MongoDB instance.
2. Create a **Database** with the name `USERDB`.
3. Inside `USERDB`, create two **Collections**:
    - `users`
    - `vitaminInfo`

This will create a structure for the application to store user data and vitamin information.

### 2. Get Google API Key for GeminiAPI

You will need a Google API Key to interact with the GeminiAPI for image analysis.

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project.
3. Navigate to **APIs & Services** > **Credentials**.
4. Click **Create Credentials** and choose **API Key**.
5. Copy the generated API key.

After getting the API key, update the following line in the code:

```ballerina
const string API_KEY = "<YOUR_API_KEY>"; // Replace <YOUR_API_KEY> with your actual API key
```

### 3. Project Configuration

1. **Clone the repository** or download the project files.

```bash
git clone <repository_url>
cd <project_folder>
```

2. **Update the MongoDB connection settings** in the Ballerina service:

Ensure your MongoDB is running on `localhost:27017` and the `userDB` database is correctly referenced.

```ballerina
mongodb:Client mongoDb = check new ({
    connection: {
        serverAddress: {
            host: "localhost",
            port: 27017
        }
    }
});
```

3. **Run the Ballerina service**:

```bash
bal run
```

This will start the HTTP server on `http://localhost:8080`.

### 4. Usage Instructions

#### 4.1 User API

You can manage user details with the following endpoints:

- `POST /register`: To register a new user.
- `POST /login`: To log in a user.
- `GET /users`: To get the list of all users.

#### 4.2 Vitamin Information API

The application provides information about various vitamins:

- `GET /vitaminInfo?vitamin=<vitamin_name>`: Get details about a specific vitamin (name and consumption sources).

#### 4.3 GeminiAPI Integration (Image Analysis)

To analyze an image and get insights using the **GeminiAPI**:

- `POST /analyzeImage`: Upload an image for analysis. The server will send the image to the GeminiAPI and return results.

Ensure to upload the image file with the key `"file"` in the form data for the API to work.

### 5. Testing the Application

You can test the endpoints using tools like **Postman** or **curl**.

For example, to analyze an image:

```bash
curl -X POST http://localhost:8080/analyzeImage \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/image.jpg"
```

This request will return the image analysis response from GeminiAPI.

---

### Troubleshooting

1. **MongoDB Connection Issues**: 
   - Ensure MongoDB is running on the correct port and the database is created as `USERDB`.

2. **GeminiAPI Issues**:
   - Make sure your Google API key is valid and added correctly to the Ballerina code.

3. **Ballerina Issues**:
   - Ensure that Ballerina is properly installed, and dependencies are up to date.

---

### License

This project is licensed under the MIT License.

---

Feel free to reach out if you encounter any issues during setup or running the application.

