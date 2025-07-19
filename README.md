# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
## https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task

i want the model to be loaded from the src/main/assets you will find the .task file and make it load the model create the session and takes the input which is text only or text with image or voice .wav  only or voice .wav with image and give the output exactly as it wanted here is some code examples for reference:Dependencies
Audio Classifier uses the com.google.mediapipe:tasks-audio library. Add this dependency to the build.gradle file of your Android app development project. Import the required dependencies with the following code:


dependencies {
    ...
    implementation 'com.google.mediapipe:tasks-audio:latest.release'
}
Model
The MediaPipe Audio Classifier task requires a trained model that is compatible with this task. For more information on available trained models for Audio Classifier, see the task overview Models section.

Select and download the model, and then store it within your project directory:


<dev-project-root>/src/main/assets
Note: This location is recommended because the Android build system automatically checks this directory for file resources.
Use the BaseOptions.Builder.setModelAssetPath() method to specify the path used by the model. This method is referred to in the code example in the next section.

In the Audio Classifier example code, the model is defined in the AudioClassifierHelper.kt file.

Create the task
You can use the createFromOptions function to create the task. The createFromOptions function accepts configuration options including running mode, display names locale, max number of results, confidence threshold, and a category allow list or deny list. For more information on configuration options, see Configuration Overview.

The Audio Classifier task supports the following input data types: audio clips and audio streams. You need to specify the running mode corresponding to your input data type when creating a task. Choose the tab corresponding to your input data type to see how to create the task and run inference.

Audio clips
Audio stream

AudioClassifierOptions options =
    AudioClassifierOptions.builder()
        .setBaseOptions(
            BaseOptions.builder().setModelAssetPath("model.tflite").build())
        .setRunningMode(RunningMode.AUDIO_CLIPS)
        .setMaxResults(5)
        .build();
audioClassifier = AudioClassifier.createFromOptions(context, options);
    
The Audio Classifier example code implementation allows the user to switch between processing modes. The approach makes the task creation code more complicated and may not be appropriate for your use case. You can see the mode switching code in the initClassifier() function of the AudioClassifierHelper.

Configuration options
This task has the following configuration options for Android apps:

Option Name	Description	Value Range	Default Value
runningMode	Sets the running mode for the task. Audio Classifier has two modes:

AUDIO_CLIPS: The mode for running the audio task on independent audio clips.

AUDIO_STREAM: The mode for running the audio task on an audio stream, such as from microphone. In this mode, resultListener must be called to set up a listener to receive the classification results asynchronously.	{AUDIO_CLIPS, AUDIO_STREAM}	AUDIO_CLIPS
displayNamesLocale	Sets the language of labels to use for display names provided in the metadata of the task's model, if available. Default is en for English. You can add localized labels to the metadata of a custom model using the TensorFlow Lite Metadata Writer API	Locale code	en
maxResults	Sets the optional maximum number of top-scored classification results to return. If < 0, all available results will be returned.	Any positive numbers	-1
scoreThreshold	Sets the prediction score threshold that overrides the one provided in the model metadata (if any). Results below this value are rejected.	[0.0, 1.0]	Not set
categoryAllowlist	Sets the optional list of allowed category names. If non-empty, classification results whose category name is not in this set will be filtered out. Duplicate or unknown category names are ignored. This option is mutually exclusive with categoryDenylist and using both results in an error.	Any strings	Not set
categoryDenylist	Sets the optional list of category names that are not allowed. If non-empty, classification results whose category name is in this set will be filtered out. Duplicate or unknown category names are ignored. This option is mutually exclusive with categoryAllowlist and using both results in an error.	Any strings	Not set
resultListener	Sets the result listener to receive the classification results asynchronously when the Audio Classifier is in the audio stream mode. Can only be used when running mode is set to AUDIO_STREAM	N/A	Not set
errorListener	Sets an optional error listener.	N/A	Not set
Prepare data
Audio Classifier works with audio clips and audio streams. The task handles the data input preprocessing, including resampling, buffering, and framing. However, you must convert the input audio data to a com.google.mediapipe.tasks.components.containers.AudioData object before passing it to the Audio Classifier task.

Audio clips
Audio stream

import com.google.mediapipe.tasks.components.containers.AudioData;

// Load an audio on the user’s device as a float array.

// Convert a float array to a MediaPipe’s AudioData object.
AudioData audioData =
    AudioData.create(
        AudioData.AudioDataFormat.builder()
            .setNumOfChannels(numOfChannels)
            .setSampleRate(sampleRate)
            .build(),
        floatData.length);
audioData.load(floatData);
    
Run the task
You can call the classify function corresponding to your running mode to trigger inferences. The Audio Classifier API returns the possible categories for the audio events recognized within the input audio data.

Audio clips
Audio stream

AudioClassifierResult classifierResult = audioClassifier.classify(audioData);
    "this is the audio part and how you can do it"