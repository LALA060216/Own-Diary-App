
class AIChatModel {
  final String prompt;
  final String model; 

  AIChatModel({
    required this.prompt,
    required this.model,
  });

  Map<String, dynamic> mapInputToModel() {
    return {
      'prompt': prompt,
      'model': model,
    };
  }
}
    
