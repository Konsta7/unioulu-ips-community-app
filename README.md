# WeConnect

## Description

**WeConnect** is a mobile application developed for the Information Processing Science (IPS) faculty at the University of Oulu. This app was created as part of an internship project under the supervision of the **INTERACT Research Group**.

The primary aim of this app is to enhance community engagement within the IPS faculty by offering a platform where students and faculty members can share posts, view announcements, and explore upcoming events.

![WeConnect Preview](./design/app-ui.png)

### Key Features:
- **Community Posts**: A space where users can create and engage in posts, add comments, and participate in discussions.
- **Event Management**: Users can browse and explore upcoming events. The app displays the most recent 3 events prominently.
- **Announcements**: Faculty members can post important updates or news for the IPS community to stay informed.

This project is built using **Flutter** for the mobile frontend and **Appwrite** for backend services such as authentication, data storage, and real-time database interaction.

### Architecture

![Architecture Diagram](./design/Architecture%20Diagram.png)

---

## Features

This application includes the following features:

#### 1. Community Posts:
Users can add, view, and interact with community posts. The app allows users to post content, comment, and engage with the community.

#### 2. Announcements:
Users can view and add important announcements. These announcements are displayed prominently and can be updated regularly.

#### 3. Event Management:
The app features an event management section where users can view and manage events. The latest 3 events are displayed in a horizontal list format, allowing for quick access to upcoming activities.

#### 4. Language Support:
The app supports multiple languages, including English, Finnish, and Swedish. Users can switch between languages seamlessly.

#### 5. Like and Comment System:
Users can like and comment on posts, fostering interaction and engagement within the community.

#### 6. Event surveys:
Event surveys are available for users to provide feedback on events they attended. This feature helps in gathering insights and improving future events.

#### 7. Community post polls:
Community post polls allow users to create polls within posts, enabling community members to vote and express their opinions on various topics.

#### Appwrite Integration:
Appwrite is used for backend services such as data storage, user authentication, and API calls. The data for community posts, announcements, and events are securely stored and managed through Appwrite’s database service.

## Contributing

We welcome contributions from the community! To contribute:

1. Fork the repository to your own GitHub account.  
2. Follow the instructions at [SETUP.md](SETUP.md) file to start developing.  
3. Create a new branch for your feature or bug fix:
```bash   
git checkout -b feature-or-bug-name
```
3. Once your changes are complete, commit and push your code:
```bash   
git commit -m "Add new feature or fix a bug"
```
```bash
git push origin feature-or-bug-name
```
4. Submit a pull request to the main repository for review.

### Coding Standards:
- Follow the Dart Style Guide and use meaningful naming conventions for variables and methods.
- Make sure to add documentation and comments where necessary.

## License (Open Source)

This project is licensed under the MIT License.  
For more details, please refer to the LICENSE file.

## Design

The Design documentation for the app can be found in the `design` folder of the repository. It contains all of the Figma design and planning documents related to the app as well as the picture assets.


## Product Roadmap

The product roadmap outlines the future features and improvements planned for the app. It includes ideated of upcoming releases, feature enhancements, and bug fixes.

![Product Roadmap](./design/Product%20roadmap.png)

## Contributors

|Contibutor|Date|
|-------|-------|
|Salman Rahman|Summer 2024|
|Walter Määttä<br>Anssi Savallampi<br>Khizra Ghaffar<br>Kinza Ghaffar|Spring 2025|
|Konsta Launonen<br>Jere Ainasoja<br>Jimi Gustafsson<br>Severi Sarala|Autumn 2025|
