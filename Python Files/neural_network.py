import tensorflow as tf
from tensorflow.examples.tutorials.mnist import input_data
import numpy as np
import pickle

mnist = input_data.read_data_sets("MNIST_data/", one_hot=True)

# Training and load weights into numpy arrays
# Change reuse=None to reuse=True when running for the second time
# Neural network has no bias, only weights

# 3 Layers
# 1st Hidden Layer: 64 Nodes
# 2nd Hidden Layer: 32 Nodes
# Output layer:     10 
with tf.variable_scope("foo", reuse=None):
    x = tf.placeholder(tf.float32, [None, 784])
    W1 = tf.get_variable("W1", shape=[784, 64], dtype=tf.float32, initializer=tf.contrib.layers.xavier_initializer())
    W2 = tf.get_variable("W2", shape=[64, 32], dtype=tf.float32, initializer=tf.contrib.layers.xavier_initializer())
    W3 = tf.get_variable("W3", shape=[32, 10], dtype=tf.float32, initializer=tf.contrib.layers.xavier_initializer())

Z1 = tf.matmul(x, W1)
A1 = tf.nn.relu(Z1)
Z2 = tf.matmul(A1, W2)
A2 = tf.nn.relu(Z2)
y = tf.matmul(A2, W3)
# Define loss and optimizer
y_ = tf.placeholder(tf.float32, [None, 10])

cross_entropy = tf.reduce_mean(
tf.nn.softmax_cross_entropy_with_logits(labels=y_, logits=y))
train_step = tf.train.GradientDescentOptimizer(0.5).minimize(cross_entropy)

sess = tf.InteractiveSession()
tf.global_variables_initializer().run()

# Train
for _ in range(1000):
    batch_xs, batch_ys = mnist.train.next_batch(300)
    sess.run(train_step, feed_dict={x: batch_xs, y_: batch_ys})

# Test trained model
correct_prediction = tf.equal(tf.argmax(y, 1), tf.argmax(y_, 1))
accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))

print("\nTesting accuracy: " + str(sess.run(accuracy, feed_dict={x: mnist.test.images,
                                      y_: mnist.test.labels})))

# Save weights to numpy arrays
weights1 = np.array(sess.run(W1))
weights2 = np.array(sess.run(W2))
weights3 = np.array(sess.run(W3))

image = mnist.train.images[0].reshape(28,28)

# Save weights to pickle files
with open('pickle/weights1.pickle', 'wb') as handle:
    pickle.dump(weights1, handle)

with open('pickle/weights2.pickle', 'wb') as handle:
    pickle.dump(weights2, handle)

with open('pickle/weights3.pickle', 'wb') as handle:
    pickle.dump(weights3, handle)

with open('pickle/image.pickle', 'wb') as handle:
    pickle.dump(image, handle)

# Observing max and min values of weights
print("\nShapes: ")
print("Weights1: " + str(weights1.shape))
print("Weights2: " + str(weights2.shape))
print("Weights3: " + str(weights3.shape), end="\n\n")

print("Max:")
print("Weights1: " + str(weights1.max()))
print("Weights2: " + str(weights2.max()))
print("Weights3: " + str(weights3.max()), end="\n\n")

print("Min:")
print("Weights1: " + str(weights1.min()))
print("Weights2: " + str(weights2.min()))
print("Weights3: " + str(weights3.min()))

