import sys
import pickle
import numpy as np


decimalBits = 17

# Load pickle files into weights in numpy arrays
with open('pickle/weights1.pickle', 'rb') as handle:
    weights1 = pickle.load(handle)

with open('pickle/weights2.pickle', 'rb') as handle:
    weights2 = pickle.load(handle)

with open('pickle/weights3.pickle', 'rb') as handle:
    weights3 = pickle.load(handle)

with open('pickle/image.pickle', 'rb') as handle:
    image = pickle.load(handle)

# Helper functions
# returns the inverse of input
def inverseBin(binary):
    invBin = ""
    for i in range(len(binary)):
        if binary[i] == '0':
            invBin = invBin + '1'
        else:
            invBin = invBin + '0'
    return invBin

# Return the a string of the 2's complement of the input
def twosComplement_(binary):
    binaryC = ""
    lenBinary = len(binary)
    firstOne = -1
    # The trailing 0's and first 1 from the right are not inverted
    for i in range(lenBinary-1, -1, -1):
        if binary[i] == '1':
            firstOne = i
            break
    if firstOne <= 0:
        return binary
    binaryKeep = binary[firstOne:]
    binaryInv = inverseBin(binary[0:firstOne])
    binary2 = binaryInv + binaryKeep
    assert(len(binary2) == len(binary))
    return binary2

# Convert number to binary
def numToBin(number):
    number_mag = abs(number)
    binary = "{0:b}".format(int(number_mag*(2**(decimalBits)))).zfill(32)
    if number < 0:
        binary_ = twosComplement_(binary)
        return binary_
    return binary

# Convert binary to hex, 
def binToHex(binary):
    return hex(int(binary,2))[2:].zfill(8)

# Funciton to convert numpy array to list of hex strings
def npArrayToHEXList(array):
    maxX, maxY = array.shape
    hexArray = []
    for i in range(maxX):
        tempList = []
        for j in range(maxY):
            tempList.append(binToHex(numToBin(array[i][j])))
        hexArray.append(tempList)
    return hexArray

# Converts a 2-d list to a 1-d HEX file
# Rows are parsed first, then columns
def twoDListToHEX(list2D, filename):
    orig_stdout = sys.stdout
    f = open(filename, 'w')
    sys.stdout = f
    rows = len(list2D)
    cols = len(list2D[0])
    for i in range(rows):
        for j in range(cols):
            print(list2D[i][j], end="\n")  
    sys.stdout = orig_stdout
    f.close()

def getIntermediateValues(image):
    inter1 = np.dot(image, weights1)
    inter2 = np.dot(np.maximum(inter1, 0), weights2)
    inter3 = np.dot(np.maximum(inter2, 0), weights3)
    return inter1, inter2, inter3

# Convert weights to HEX text files using helper functions
weights1_hex_list = npArrayToHEXList(weights1.T)
weights2_hex_list = npArrayToHEXList(weights2.T)
weights3_hex_list = npArrayToHEXList(weights3.T)

twoDListToHEX(weights1_hex_list, "weights/weights1.hex")
twoDListToHEX(weights2_hex_list, "weights/weights2.hex")
twoDListToHEX(weights3_hex_list, "weights/weights3.hex")


# Convert Intermediate vlaues to HEX Text files
i1, i2, i3 = getIntermediateValues(image.reshape((-1,784)))


i1_hex_list = npArrayToHEXList(i1)
i2_hex_list = npArrayToHEXList(i2)
i3_hex_list = npArrayToHEXList(i3)

twoDListToHEX(i1_hex_list, "test_values/layer1.hex")
twoDListToHEX(i2_hex_list, "test_values/layer2.hex")
twoDListToHEX(i3_hex_list, "test_values/layer3.hex")
