import tensorflow as tf

# Create converter from saved model
converter = tf.lite.TFliteConverter.from_saved_model(r"C:\Users\anasb\AndroidStudioProjects\testtt\assets\model\gemma3n.task")

# Set optimizations
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Convert the model
tflite_model = converter.convert()

# Save the converted model
with open("converted_model.tflite", "wb") as f:
    f.write(tflite_model)