
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import numpy as np
import sys

# return the a string of the 2's complement of the input
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

def numToBin(number):
    decimalBits = 17
    number_mag = abs(number)
    binary = "{0:b}".format(int(number_mag*(2**(decimalBits)))).zfill(32)
    if number < 0:
        binary_ = twosComplement_(binary)
        return binary_
    return binary

def binToHex(binary):
    return hex(int(binary,2))[2:].zfill(8)

# Funciton to convert numpy array to list of binary strings
def npArrayToHexList(array):
    maxX, maxY = array.shape
    hexArray = []
    for i in range(maxX):
        tempList = []
        for j in range(maxY):
            tempList.append(binToHex(numToBin(array[i][j])))
        hexArray.append(tempList)
    return hexArray

def twoDListToFile(list2D, filename):
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

def numToHex(num):
    return hex(int(num*255))[2:].zfill(2)

def npArrayTo2BitHexList(array):
    maxX, maxY = array.shape
    hexArray = []
    for i in range(maxX):
        tempList = []
        for j in range(maxY):
            tempList.append(numToHex(array[i][j]))
        hexArray.append(tempList)
    return hexArray

images = {}

for i in range(10):
    images[str(i)] = np.around(mpimg.imread("images/png/" + str(i) + '.png')[:,:,1])
    # making sure the size of image is the same
    assert images[str(i)].shape == (28, 28)

for i in range(10):
    twoDListToFile(npArrayTo2BitHexList(images[str(i)]), "images/hex/" + str(i) + '.hex')
