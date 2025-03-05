class AiService {
  // This is a mock function simulating an AI prediction model.
  // Replace this with your actual AI model or API call.
  static String predictStress(double temperature, int stepCount) {
    // Simple logic to simulate prediction (you should replace this with your real AI logic)
    double score = (temperature * 0.3 + stepCount * 0.7) / 2;

    if (score > 50) {
      return "High probability";
    } else if (score > 25) {
      return "Moderate probability";
    } else {
      return "Low probability";
    }
  }
}
