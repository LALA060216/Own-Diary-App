# Journal Go

**Team:** The Gawk Team  
**Description:** A digital journal platform powered by Generative AI. The Generative AI are designed serve user as their personal assistant. By analyzing daily diary entries, providing them their current health state, emotion state and his attention focus daily and weekly. Futhermore, it could also act as a searching engine for effortless event retrieval. Besides that, the Generative AI could also catetories user's journal and show it as moments to allow user to recall back.

---

## Project Description

### Summary of our project

Our AI-based diary mitigate this by combining diary with intelligent assistance. Users are allowed to easily record daily experiences by attaching images or generating paragraphs with the help of our AI assistant. The solution is also designed to be inclusive for children and the elderly. AI assistant removes the need for writing skills, making diary writing simple and accessible for all age groups.
---

## Demo Video Link

[Our Demo Video](https://docs.flutter.dev/get-started/codelab)

---

## Project Documentation

### Technical architecture
- Our AI-based diary is built from four main components, **Mobile App**, **Authentication (Firebase Auth)**, **Data Layer (Cloud Firestore & Firebase Storage)** and **AI Layer (Google Gemini via API & optional Cloud Functions/Cloud Run)**. 

- **Mobile App (Flutter)**
This is the user interface where users log in, chat with AI and create diary entries using text, images or short inputs. 

- **Authentication (Firebase Auth)**
Handles secure user sign-in and identity. This ensures every diary and analysis belongs to the correct user and enables access control.

- **Data Layer (Cloud Firestore & Firebase Storage)**
Firestore stores structured data like diary entries, chat history, mood tags and user preferences.
Storage stores uploaded images linked to diary entries. We structured it this way because Firestore is great for fast, scalable app data while Storage is designed for media files.

- **AI Layer (Google Gemini via API & optional Cloud Functions/Cloud Run)**
User inputs (text/images/context) are sent to Gemini for tasks like diary entry generation, mood analysis, health tracking, trend summaries and personalized insights. A backend layer can sit between the app and Gemini to keep API keys secure, enforce permissions and log analytics safely.


### Implementation

- **Flutter:** We chose Flutter as our main mobile application development platform because it allows us to build a single codebase for both Android and iOS. Flutter reduces development time while maintaining high performance and a smooth user interface.

- **Firebase Authentication:** We use Firebase Authentication to manage user login and identity. It simplifies user management and provides built-in security compared to building a custom authentication system from scratch.

- **Cloud Firestore:** Cloud Firestore is used to store diary entries and user activity. We chose Firestore because it offers real-time synchronization, scalability and structured NoSQL storage, which is ideal for user-generated content and growing datasets.

- **Firebase Storage:** Firebase Storage is used to store user-uploaded images safely. It integrates seamlessly with Firebase security rules, making file handling safer and easier compared to third-party storage services.

- **Firebase Analytics:** We use Firebase Analytics to track user engagement, retention rates and feature usage. This helps us measure the effectiveness of AI-assisted journaling and overall app adoption.

- **Google Gemini (via Google AI Studio API):** Gemini powers our AI assistant. We chose it because it provides strong natural language understanding and reasoning capabilities, enabling mood analysis, pattern detection and personalised life insights.

### Challenges

- One significant technical challenge we faced was debugging the new_diary.dart file. This file was complex because it connected multiple systems and files at once for example, Firebase Authentication, Cloud Firestire, Firebase Storage and all other files related to the diary. Since it handled diary creation, update, image uploads, deletion  and streak tracking, even a small mistake could break multiple functions and cause system down.

- The main issue involved streak calculation, creation and deletion of diary and empty diary handling. As we allow users to create multiple diaries per day, the streak logic had to ensure that streaks were updated correctly without being incremented multiple times on the same day. At the same time, if a user created an empty diary, it had to be automatically deleted to prevent false diary counts, incorrect streak updates and empty diary to be shown in the total diary page. 
  
- During debugging, we inspected Firestore documents to check whether streaks were being updated multiple times per day. We added conditional checks to ensure streak updates only occurred when a valid diary was created by introducing and debugging a lastStreakUpdateDate field in Firestore. We compared it with the current date to ensure streaks only increment once per day. We resolved the problem createdDate and lastUpdatedDate by enforcing consistent timestamp creation so that validation checks were added to ensure both fields always exist before rendering.

### Future roadmap
- In the next phase of development, we plan to expand the system by introducing a deeper phone-level integration option. Instead of relying only on manual diary entries, the assistant will be able to integrate more naturally into the user’s smartphone environment (with user permission). This would allow the AI to understand daily patterns more seamlessly and provide smarter, tailored and context-aware insights. At the same time, we aim to solve the major concern for AI–based systems related to privacy and data safety. Therefore, our future direction includes solving the privacy and data safety challenge by shifting toward on-device AI processing. By integrating the AI directly into smartphones and keeping sensitive data stored locally rather than uploading it to cloud servers, we aim to significantly reduce the risk of data exposure and build stronger user trust. 