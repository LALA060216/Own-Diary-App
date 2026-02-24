const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {GoogleGenerativeAI} = require("@google/generative-ai");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

/**
 * Initialize Gemini AI with the API key
 * @param {string} apiKey - The Gemini API key
 * @return {GoogleGenerativeAI} Initialized Gemini AI instance
 */
function initializeGemini(apiKey) {
  return new GoogleGenerativeAI(apiKey);
}

// Cloud function to classify diary images using Gemini
exports.classifyDiaryImage = onRequest(
    {secrets: [GEMINI_API_KEY]},
    async (req, res) => {
      try {
        const {imageData, mimeType} = req.body;

        if (!imageData || typeof imageData !== "string") {
          return res.status(400).json({
            error: "imageData (base64) is required",
          });
        }

        const genAI = initializeGemini(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({
          model: "gemini-2.5-flash",
        });

        const base64Image = imageData;
        const contentType = mimeType || "image/jpeg";

        // Classification prompt
        const classificationPrompt = (
          "You are an image classifier for diary moments. " +
            "Look at the image and classify what you see. " +
            "Return exactly ONE category from: " +
            "food_buddy, funny_moment, travel_memory, study_day, " +
            "work_life, fitness, family_time, friend_vibes, romance, " +
            "pet_time, night_thoughts, music_movie, nature_walk, " +
            "self_growth, or moments. Be confident. " +
            "Output only the category key, no explanation."
        );

        // Classify the image using Gemini
        const response = await model.generateContent([
          {
            inlineData: {
              data: base64Image,
              mimeType: contentType,
            },
          },
          {
            text: classificationPrompt,
          },
        ]);

        const classification =
            (response.response.text() || "").trim() || "moments";

        res.status(200).json({category: classification});
      } catch (error) {
        console.error("Error classifying image:", error);
        res.status(500).json({error: error.message});
      }
    },
);

// Cloud function for simple chat
exports.chat = onRequest(
    {secrets: [GEMINI_API_KEY]},
    async (req, res) => {
      try {
        const {message, prompt, model: modelName} = req.body;

        if (!message || !prompt || !modelName) {
          return res.status(400).json({
            error: "message, prompt, and model are required",
          });
        }

        const genAI = initializeGemini(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({model: modelName});

        const chat = model.startChat({
          history: [{role: "user", parts: [{text: prompt}]}],
        });

        const response = await chat.sendMessage(message);
        const responseText =
        response.response.text() || "Sorry, I couldn't generate a response.";

        res.status(200).json({response: responseText});
      } catch (error) {
        console.error("Error in chat:", error);
        res.status(500).json({error: error.message});
      }
    },
);

// Cloud function for chat with history
exports.chatWithHistory = onRequest(
    {secrets: [GEMINI_API_KEY]},
    async (req, res) => {
      try {
        const {message, history, prompt, model: modelName} = req.body;

        if (!message || !history || !prompt || !modelName) {
          return res.status(400).json({
            error: "message, history, prompt, and model are required",
          });
        }

        const genAI = initializeGemini(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({model: modelName});

        const chat = model.startChat({history});

        const response = await chat.sendMessage(message);
        const responseText =
        response.response.text() || "Sorry, I couldn't generate a response.";

        res.status(200).json({response: responseText});
      } catch (error) {
        console.error("Error in chatWithHistory:", error);
        res.status(500).json({error: error.message});
      }
    },
);

// Cloud function for mood analysis
exports.moodAnalysis = onRequest(
    {secrets: [GEMINI_API_KEY]},
    async (req, res) => {
      try {
        const {diaryEntry, prompt, model: modelName} = req.body;

        if (!diaryEntry || !prompt || !modelName) {
          return res.status(400).json({
            error: "diaryEntry, prompt, and model are required",
          });
        }

        const trimmedEntry = diaryEntry.trim();
        if (trimmedEntry.length === 0) {
          return res.status(400).json({error: "Empty diary entry"});
        }

        const genAI = initializeGemini(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({model: modelName});

        const response = await model.generateContent([
          {
            text: `${prompt}\nDiary entry:\n${trimmedEntry}`,
          },
        ]);

        const analysis = response.response.text() || "";

        res.status(200).json({analysis});
      } catch (error) {
        console.error("Error in moodAnalysis:", error);
        res.status(500).json({error: error.message});
      }
    },
);

// Cloud function for attention analysis
exports.attentionAnalysis = onRequest(
    {secrets: [GEMINI_API_KEY]},
    async (req, res) => {
      try {
        const {diaryEntry, prompt, model: modelName} = req.body;

        if (!diaryEntry || !prompt || !modelName) {
          return res.status(400).json({
            error: "diaryEntry, prompt, and model are required",
          });
        }

        const trimmedEntry = diaryEntry.trim();
        if (trimmedEntry.length === 0) {
          return res.status(400).json({error: "Empty diary entry"});
        }

        const genAI = initializeGemini(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({model: modelName});

        const fullPrompt = `${prompt}\nDiary entry:\n${trimmedEntry}`;

        const response = await model.generateContent([{text: fullPrompt}]);

        const analysis = response.response.text() || "{}";

        res.status(200).json({analysis});
      } catch (error) {
        console.error("Error in attentionAnalysis:", error);
        res.status(500).json({error: error.message});
      }
    },
);

// Cloud function for chat with diary entries
exports.chatWithDiaryEntry = onRequest(
    {secrets: [GEMINI_API_KEY]},
    async (req, res) => {
      try {
        const {message, previousMessage, contexts, prompt, model: modelName} =
        req.body;

        if (!message || !contexts || !prompt || !modelName) {
          return res.status(400).json({
            error: "message, contexts, prompt, and model are required",
          });
        }

        const genAI = initializeGemini(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({model: modelName});

        // Build history with prompt and contexts
        const history = [{role: "user", parts: [{text: prompt}]}];
        for (const context of contexts) {
          history.push({
            role: "user",
            parts: [{text: `Diary entry: ${context}`}],
          });
        }

        const chat = model.startChat({history});

        const fullMessage =
            previousMessage && Array.isArray(previousMessage) ?
              `Previous message: ${JSON.stringify(previousMessage)}\n` +
                `Current message: ${message}` :
              message;

        const response = await chat.sendMessage(fullMessage);
        const responseText =
        response.response.text() || "Sorry, I couldn't generate a response.";

        res.status(200).json({response: responseText});
      } catch (error) {
        console.error("Error in chatWithDiaryEntry:", error);
        res.status(500).json({error: error.message});
      }
    },
);
