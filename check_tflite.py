import tensorflow as tf

try:
    with open('assets/model/gemma3n.task', 'rb') as f:
        tflite_model = f.read()
    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    print('TFLITE')
except Exception as e:
    print('NOT_TFLITE:', e) 