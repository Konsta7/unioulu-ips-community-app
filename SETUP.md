# Installation

To contribute to the **WeConnect**, follow these steps to set up the project locally on your machine. This guide will walk you through setting up the **Appwrite server** for backend services and **Flutter** for the mobile app.

### Prerequisites

Before you begin, make sure you have the following installed:

1. **Docker**: For running the Appwrite server.
2. **Flutter**: The mobile development framework.
3. **Git**: Version control to clone the repository.
4. **Visual Studio Code** or any preferred IDE.
5. **Python**: For running the database configuration script.

---

### 1. Clone the Project


1. Open your terminal or command prompt.
2. Navigate to the directory where you want to store the project.
3. Run the following command to clone the repository:

```bash
git clone ##TODO: ADD LINK 
```
Navigate to the project:
```bash
cd unioulu-ips-community-app
```

---


### 2. Install and Set Up Appwrite (Self-Hosted)

We are using a self-hosted **Appwrite** instance. Follow the steps below to set up **Appwrite** on your machine using Docker.

#### Docker Installation

* **Docker CLI**: Make sure you have Docker installed on your machine. You can download it from [Docker's official site](https://www.docker.com/products/docker-desktop). We recommend using the desktop version.

#### Run the Appwrite Server

Copy the appwrite env file from https://appwrite.io/install/env and place it in the appwrite folder with name `.env`. 

Fill out the SMTP variables in the `.env` file with the the following instructions. First you need to have a Google account. (Might also work with other systems, but we recommend Google)

#### Googles end

1. Follow this link [Google account security](https://myaccount.google.com/security) and login if needed. 
2. From there enable 2FA.
3. Then navigate to home from the menu on the left.
4. From there search for *Application passwords* and navigate to there.
5. Create a application password and copy it 

For more help in creating the password check [this tutorial](https://youtu.be/MkLX85XU5rU?si=ofN-pIZRj_SOuFaK)

```bash
_APP_SMTP_HOST=smtp.gmail.com
_APP_SMTP_PORT=587
_APP_SMTP_SECURE=tls
_APP_SMTP_USERNAME=your.email.address@gmail.com
_APP_SMTP_PASSWORD=password-you-just-created
```

If you do not want to use Docker Compose, the appwrite docs have a guide for other methods: https://appwrite.io/docs/advanced/self-hosting

After installing Docker, navigate to appwrite folder in terminal and run the following command to start the Appwrite server:

```bash
docker compose up -d
```
For detailed instructions, refer to the [Appwrite self-hosting documentation](https://appwrite.io/docs/advanced/self-hosting) or watch the [YouTube tutorial](https://youtu.be/aO4mw8smXkI?si=8qp5IWHNkY-74J5v).

#### Setting up Appwrite

Once the server is up and running, you can access the Appwrite dashboard at `http://localhost` in your browser. You will be prompted to create an account and set up your project.

You need to register a new account, create a new organization, add a platform and create a new project. Once the project is created, you will need to create an API key that you will use to interact with the Appwrite API.

Adding a bucket through the Storage section is optional, but is needed to add new events in admin role. You can name the bucket anything you like, but make sure to update the `APPWRITE_BUCKET_ID` in your `.env` file accordingly. Don't create database yet, because later on a script(appwrite_init.py) does it automatically with some tables included.

In order to view event poster photos while using the app, you must set bucket settings so that anyone has permission to read.

To enable the email verification you need a google account. You also need to fill out some settings in Appwrite console. Instructions to these can be found below. 

Add these to the end of your `.env` file:
```bash
APPWRITE_API_KEY=your_api_key  # This will be created next and is found at appwrite console at localhost
APPWRITE_URL=http://localhost/v1
APPWRITE_PROJECT_ID=your_project_id  # After you create a project, project id is found at appwrite console at localhost.
APPWRITE_DATABASE_ID=community
APPWRITE_BUCKET_ID=bucket  
```

#### Creating an API Key

You can create an API key by following these steps:

1. Go to the Appwrite Overview dashboard.
2. Under "Integrate with your server" select "API key".
3. Select a name and an expiry date.
4. Select scopes; for development purposes, you can select all scopes.
5. Click "Create" to generate the API key.
6. Copy the API key and add it to your project's appwrite `.env` file.  !!!FIX ME!!!

#### Adding a Platform

Appwrite requires you to add a platform to your project for CORS. You can add a platform by following these steps:

1. Go to the Appwrite Overview dashboard.
2. Under "Integrations" select "Add platform".
3. Select the platform type (e.g., Flutter app).
4. Select the correct platform and fill out the details (the package name should be the same as your Flutter app's package name. Current name is "community" and it is defined in pubspec.yaml).
5. Click through the optional steps and press "Go to dashboard".

#### Enabling SMTP for email verification

1. Go to the Appwrite Overview dashboard.
2. Navigate to the settings in bottom left corner.
3. Navigate to SMTP and fill out the information:
    1. Sender name: *WeConnect*
    2. Sender email, Reply to and Username: *The email address used in previous steps*
    3. Server host: *smtp.gmail.com*
    4. Server port: *587*
    5. Password: *The one created on the [Googles end](####Googles-end)*
![alt text](image.png)


#### Appwrite configuration with appwrite_init.py

To automate the Appwrite configuration process, we have provided a Python script (appwrite_init.py) that sets up the necessary collections and attributes in your Appwrite database.

Start with installing requirements:  
!!! FIRST CHANGE THE APPWRITE VERSION IN THE REQUIREMENTS.TXT TO 1.2.0 !!! It was changed to 3.0.0 so Dependabot would not alert.

```bash
pip install -r requirements.txt
```
Make sure you have filled the required fields in the .env file. Then run the script:

```bash
python appwrite_init.py
```

This script creates necessary collections and attributes for your Appwrite database, including collections like:

- **Events**
- **Topics**
- **Posts**
- **Comments**
- **Announcements**

For each collection, it defines the necessary attributes (e.g., title, content, datetime, etc.) and injects sample data to get you started.

What the Script Creates
- **Collections**: Events, Topics, Posts, Comments, Announcements.
- **Attributes**: For each collection, attributes like title, content, dateTime, authorName, and more are created.

For example, the Events collection will include attributes like:
- **title_en**
- **location_en**
- **date**
- **time**
- **posterPhotoUrl**

This setup ensures that your database is structured correctly for the application to work smoothly.

---
### 3. Install Flutter

Once Appwrite is set up, the next step is to install **Flutter** on your machine. Follow the official Flutter installation guide for your operating system:

- **Flutter Installation Guide**: [Get Started with Flutter](https://docs.flutter.dev/get-started/install)
- **YouTube Tutorial** for Windows: [Install Flutter on Windows](https://youtu.be/VFDbZk2xhO4?si=n3k9nqJ2sa8kIxi4)
- **YouTube Tutorial** for macOS: [Install Flutter on macOS](https://youtu.be/KdO9B_CZmzo?si=iYMvJ0ao_HHwKhfq)

#### Verify Installation

After installing Flutter, verify that Flutter and Dart have been installed successfully by running the following command in your terminal:

```bash
flutter doctor
```
This command will display any missing dependencies or issues that need to be resolved before proceeding. Make sure to resolve any issues if prompted.

---

### 4. Run the Application

First time running you must get the dependencies for the flutter using the following command:

```bash
flutter pub get
```

Now, you can run the Flutter app on your preferred device or emulator. Ensure your device is connected or the emulator is running, then use the following command:


```bash
flutter run
```

#### On computer:
* You must have platform created on appwrite for computer's operating system. When you run the app, choose your operating system by inserting the correct number from the menu. This will build and launch the app on an emulator.
#### On mobile:
* First of all you must be on the same local network and the mobile device must be connected to your computer via cable (USB recommended).
* Now when running the app, it doesn't ask the number anymore, it should open the application on the mobile device automatically.
---

For further assistance with running or debugging the project, please refer to the official Flutter documentation or check the project's issue tracker on GitHub.

---
## Project Structure

This project follows CLEAN architecture principles combined with BLoC state management to maintain separation of concerns and keep the code modular, scalable, and testable. Here’s an overview of the folder structure:
```bash
lib/
│
├── core/                       # Core functionalities shared across the app
│   ├── fonts/                  # Font files for the app
│   ├── pages/                  # Core pages (e.g., splash screen)
│   ├── services/               # Services like dependency injection
│   ├── theme/                  # Theme-related files
│   └── utils/                  # Utility classes (e.g., responsive design)
│
├── features/                   # Feature-specific code
│   ├── auth/                   # Authentication feature
│   │   ├── data/               # Data layer for authentication
│   │   │   ├── datasources/    # Data sources (remote, local)
│   │   │   ├── models/         # Data models
│   │   │   └── repositories/   # Repository implementations
│   │   ├── domain/             # Domain layer for authentication
│   │   │   ├── entities/       # Core entities (e.g., User)
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Use cases (business logic)
│   │   └── presentation/       # Presentation layer for authentication
│   │       ├── bloc/           # BLoC for authentication
│   │       ├── pages/          # UI pages (e.g., login, register)
│   │       └── widgets/        # Smaller UI components (e.g., forms)
│   │
│   ├── community/              # Community feature (similar structure as auth)
│   ├── events/                 # Events feature (similar structure as auth)
│   ├── home/                   # Home feature (similar structure as auth)
│   ├── language/               # Language feature for localization
│   └── theme/                  # Theme feature for theming
│
├── l10n/                       # Localization files
│   ├── intl_en.arb             # English localization
│   ├── intl_fi.arb             # Finnish localization
│   ├── intl_sv.arb             # Swedish localization
│
└── main.dart                   # Application entry point
