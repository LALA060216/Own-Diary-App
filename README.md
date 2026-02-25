# Journal Go

**Team:** The Gawk Team  
**Description:** A digital journal platform powered by Generative AI. The Generative AI are designed serve user as their personal assistant. By analyzing daily diary entries, providing them their current health state, emotion state and his attention focus daily and weekly. Futhermore, it could also act as a searching engine for effortless event retrieval. Besides that, the Generative AI could also catetories user's journal and show it as moments to allow user to recall back.

---

## Project Description

### Summary of our project

Our AI-based diary mitigate this by combining diary with intelligent assistance. Users are allowed to easily record daily experiences by attaching images or generating paragraphs with the help of our AI assistant. The solution is also designed to be inclusive for children and the elderly. AI assistant removes the need for writing skills, making diary writing simple and accessible for all age groups.

### Problem statement

Many people nowadays, especially students and busy young adults, struggle to consistently record their thoughts, emotions and daily experience because a traditional diary requires time, discipline and writing effort. As a result, personal memories, emotional health and important life reflection are often lost or forgotten.

---

## Demo Video Link

[Our Demo Video](https://docs.flutter.dev/get-started/codelab)

---

## Project Documentation

### Technical Implementation Overview of technologies used
- Firebase Analysitcs
- Cloud FireStore
- Firebase Authentication
- Firebase Storage
- Flutter
- Google Gemini via Google AI Studio

### Implementation, innovation and challenges faced

#### Implementation

- **Flutter:** We chose Flutter as our main mobile application development platform because it allows us to build a single codebase for both Android and iOS. Flutter reduces development time while maintaining high performance and a smooth user interface.

- **Firebase Authentication:** We use Firebase Authentication to manage user login and identity. It simplifies user management and provides built-in security compared to building a custom authentication system from scratch.

- **Cloud Firestore:** Cloud Firestore is used to store diary entries and user activity. We chose Firestore because it offers real-time synchronization, scalability and structured NoSQL storage, which is ideal for user-generated content and growing datasets.

- **Firebase Storage:** Firebase Storage is used to store user-uploaded images safely. It integrates seamlessly with Firebase security rules, making file handling safer and easier compared to third-party storage services.

- **Firebase Analytics:** We use Firebase Analytics to track user engagement, retention rates and feature usage. This helps us measure the effectiveness of AI-assisted journaling and overall app adoption.

- **Google Gemini (via Google AI Studio API):** Gemini powers our AI assistant. We chose it because it provides strong natural language understanding and reasoning capabilities, enabling mood analysis, pattern detection and personalised life insights.

#### Innovation

- We implemented AI into our diary app which transforms it from a simple digital diary into an intelligent personal life companion. Without AI, the app would only function as a storage platform where users manually write and review entries. It would not be able to understand, analyze or provide insights based on user data. With AI assistant, the system can:
  

- **Analyze Emotional Patterns**  
The AI detects emotional changes in diary entries and identifies mood trends over time even if users’ current mood is not directly mentioned in the diary. For example, if a user shows increasing stress-related language across several days, the AI assistant can highlight this phenomenon and suggest reflection or strategies.

- **Provide Personalized Insights**  
Instead of just storing image and text, the AI summarizes weekly reflections, identifies recurring themes such as financial worries, productivity struggles and provides personalised suggestions for improvement.

- **Lower Writing Barriers**  
Users can input short phrases or upload images then the AI assistant expands them into structured diary entries. This makes journaling accessible to children elderly users or individuals who lack strong writing skills and also time for writing self reflection.

- **Life Assistance Beyond Journaling**  
AI assistant can interpret diary data to give guidance on emotional stability, habit formation, productivity and basic wealth management awareness.

#### Challenges

- One significant technical challenge we faced was debugging the new_diary.dart file. This file was complex because it connected multiple systems and files at once for example, Firebase Authentication, Cloud Firestire, Firebase Storage and all other files related to the diary. Since it handled diary creation, update, image uploads, deletion  and streak tracking, even a small mistake could break multiple functions and cause system down.