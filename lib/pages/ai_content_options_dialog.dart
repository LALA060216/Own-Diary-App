import 'package:flutter/material.dart';

class AiContentOptions {
  String? emotionStatus;
  String? peopleInvolved;
  String? tone;
  String? activity;
  String? location;
  String? weather;
  bool photoIsImportant;
  String? userDescription;

  AiContentOptions({
    this.emotionStatus,
    this.peopleInvolved,
    this.tone,
    this.activity,
    this.location,
    this.weather,
    this.photoIsImportant = false,
    this.userDescription,
  });

  String buildPrompt({String? imageDescription}) {
    final buffer = StringBuffer();
    buffer.writeln('You are a helpful diary writing assistant. Generate a natural first-person diary entry based ONLY on the information provided below.');
    buffer.writeln();
    buffer.writeln('CRITICAL RULES:');
    buffer.writeln('- Write ONLY about what is explicitly mentioned in the description or shown in the image');
    buffer.writeln('- Do NOT invent activities, meals, places, or events not mentioned');
    buffer.writeln('- Do NOT add assumptions or make up details');
    buffer.writeln('- Stay strictly within the given context - no extra content');
    buffer.writeln('- Be authentic and personal, but stick to the facts provided');
    buffer.writeln();
    
    if (imageDescription != null && imageDescription.isNotEmpty) {
      buffer.writeln('IMAGE CONTENT: $imageDescription');
      buffer.writeln('(Base the diary entry around what is shown in the image)');
      buffer.writeln();
    }
    
    if (userDescription != null && userDescription!.trim().isNotEmpty) {
      buffer.writeln('USER DESCRIPTION: ${userDescription!.trim()}');
      buffer.writeln();
    }

    if (emotionStatus != null) buffer.writeln('Emotional state: $emotionStatus');
    if (peopleInvolved != null) buffer.writeln('People involved: $peopleInvolved');
    if (activity != null) buffer.writeln('Activity: $activity');
    if (location != null) buffer.writeln('Location/Setting: $location');
    if (weather != null) buffer.writeln('Weather/Atmosphere: $weather');

    buffer.writeln();
    if (tone != null) buffer.writeln('Writing tone: $tone');
    buffer.writeln();
    buffer.writeln('Write in first person. Be natural and conversational. Maximum 300 words. No markdown, bullets, or headings. Do NOT include the date.');

    return buffer.toString();
  }
}

class AiContentOptionsDialog extends StatefulWidget {
  final String? currentTitle;
  final String? currentContext;

  const AiContentOptionsDialog({
    super.key,
    this.currentTitle,
    this.currentContext,
  });

  @override
  State<AiContentOptionsDialog> createState() => _AiContentOptionsDialogState();
}

class _AiContentOptionsDialogState extends State<AiContentOptionsDialog> {
  final _userDescriptionController = TextEditingController();

  String? _selectedEmotionStatus;
  String? _selectedPeople;
  String? _selectedTone;
  String? _selectedActivity;
  String? _selectedLocation;
  String? _selectedWeather;
  bool _photoIsImportant = false;

  final List<String> _emotionStatuses = [
    "Happy", "Overjoyed", "Loved", "Excited", "Grateful", "Proud", "Peaceful",
    "Neutral", "Calm", "Relaxed", "Content", "Hopeful",
    "Sad", "Depressed", "Lonely", "Disappointed", "Heartbroken", "Gloomy",
    "Angry", "Furious", "Annoyed", "Frustrated", "Irritated",
    "Exhausted", "Tired", "Drained", "Overwhelmed", "Stressed", "Anxious",
    "Embarrassed", "Shocked", "Awkward", "Confused", "Worried", "Scared",
    "Chill", "Bored", "Restless", "Terrible"
  ];

  final List<String> _peopleOptions = [
    'Alone', 'Family', 'Friends', 'Partner', 'Classmates', 'Colleagues', 'Stranger/Customer'
  ];

  final List<String> _toneOptions = [
    'Casual', 'Neutral', 'Poetic', 'Funny', 'Short & simple', 'Detailed'
  ];

  final List<String> _activityOptions = [
    'Eating/Dining', 'Studying/Learning', 'Working', 'Exercising/Sports',
    'Traveling', 'Shopping', 'Cooking', 'Reading', 'Gaming',
    'Watching movie/show', 'Listening to music', 'Meeting/Socializing',
    'Relaxing/Resting', 'Celebrating', 'Hobby/Craft', 'Outdoor activity',
    'House chores', 'Self-care', 'Planning', 'Creating/Making'
  ];

  final List<String> _locationOptions = [
    'Home', 'School/University', 'Office/Workplace', 'Restaurant/Cafe',
    'Park/Outdoor', 'Gym/Sports facility', 'Library', 'Shopping mall',
    'Friend\'s place', 'Beach/Lake', 'Mountains', 'City center',
    'Transportation', 'Hospital/Clinic', 'Cinema/Theater', 'Museum/Gallery',
    'Hotel/Resort', 'Street/Neighborhood', 'Concert/Event venue'
  ];

  final List<String> _weatherOptions = [
    'Sunny', 'Cloudy', 'Rainy', 'Stormy', 'Snowy', 'Foggy',
    'Windy', 'Hot', 'Warm', 'Cool', 'Cold', 'Humid', 'Dry',
    'Clear night', 'Overcast', 'Drizzling', 'Perfect weather'
  ];

  @override
  void dispose() {
    _userDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xffF9F6EE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Content Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Your description',
                      TextField(
                        controller: _userDescriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Briefly describe what happened today...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    _buildSection(
                      'Photo context',
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Should image be involved in diary?'),
                        value: _photoIsImportant,
                        onChanged: (val) => setState(() => _photoIsImportant = val ?? false),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        'Optional Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildSection(
                      'Emotion status',
                      _buildDropdown(
                        _emotionStatuses,
                        _selectedEmotionStatus,
                        'Select emotion status',
                        (val) => setState(() => _selectedEmotionStatus = val),
                      ),
                    ),
                    _buildSection(
                      'People involved',
                      _buildDropdown(
                        _peopleOptions,
                        _selectedPeople,
                        'Select people',
                        (val) => setState(() => _selectedPeople = val),
                      ),
                    ),
                    _buildSection(
                      'Activity',
                      _buildDropdown(
                        _activityOptions,
                        _selectedActivity,
                        'Select activity',
                        (val) => setState(() => _selectedActivity = val),
                      ),
                    ),
                    _buildSection(
                      'Location',
                      _buildDropdown(
                        _locationOptions,
                        _selectedLocation,
                        'Select location',
                        (val) => setState(() => _selectedLocation = val),
                      ),
                    ),
                    _buildSection(
                      'Weather',
                      _buildDropdown(
                        _weatherOptions,
                        _selectedWeather,
                        'Select weather',
                        (val) => setState(() => _selectedWeather = val),
                      ),
                    ),
                    _buildSection(
                      'Tone',
                      _buildDropdown(
                        _toneOptions,
                        _selectedTone,
                        'Select tone',
                        (val) => setState(() => _selectedTone = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xffF9F6EE),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final options = AiContentOptions(
                        emotionStatus: _selectedEmotionStatus,
                        peopleInvolved: _selectedPeople,
                        tone: _selectedTone,
                        activity: _selectedActivity,
                        location: _selectedLocation,
                        weather: _selectedWeather,
                        photoIsImportant: _photoIsImportant,
                        userDescription: _userDescriptionController.text.trim(),
                      );
                      Navigator.of(context).pop(options);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff8B7355),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff8B7355),
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown(
    List<String> options,
    String? selected,
    String hint,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
