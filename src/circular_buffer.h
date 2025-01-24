#ifndef CIRCULAR_BUFFER_H
#define CIRCULAR_BUFFER_H

#include "common.h"
#include <iostream>
#include <vector>
#ifndef _IS_WIN_
#include <algorithm>
#endif

template<typename T = float>
class CircularBuffer
{
private:
    std::vector<T> buffer;
    unsigned int maxSize;
    unsigned int currentSize;
    unsigned int head;
    unsigned int tail;

public:
    CircularBuffer(unsigned int size) : buffer(size),
                                        maxSize(size),
                                        currentSize(0),
                                        head(0),
                                        tail(0) {}

    int size() { return currentSize; }

    void push(const std::vector<T> &values)
    {
        unsigned int numValues = (unsigned int)values.size();

        // Check if the buffer is full
        if (currentSize + numValues > maxSize)
        {
            unsigned int numToRemove = currentSize + numValues - maxSize;
            head = (head + numToRemove) % maxSize;
            currentSize -= numToRemove;
        }

        unsigned int numTail = std::min(numValues, maxSize - tail);

        // Copy values to the tail of the buffer
        std::copy(values.begin(), values.begin() + numTail, buffer.begin() + tail);

        // If there are remaining values, copy them to the head of the buffer
        if (numValues > numTail)
        {
            std::copy(values.begin() + numTail, values.end(), buffer.begin());
        }

        tail = (tail + numValues) % maxSize;
        currentSize = std::min(currentSize + numValues, maxSize);
    }

    std::vector<T> pop(unsigned int numValues)
    {
        numValues = std::min(numValues, currentSize);
        std::vector<T> poppedValues(numValues);

        unsigned int numTail = std::min(numValues, maxSize - head);

        // Copy values from the head of the buffer
        std::copy(buffer.begin() + head, buffer.begin() + head + numTail, poppedValues.begin());

        // If there are remaining values, copy them from the tail of the buffer
        if (numValues > numTail)
        {
            std::copy(buffer.begin(), buffer.begin() + numValues - numTail, poppedValues.begin() + numTail);
        }

        head = (head + numValues) % maxSize;
        currentSize -= numValues;

        return poppedValues;
    }

    void print() const
    {
        std::cout << "N: " << currentSize << " - ";
        for (unsigned int i = 0; i < currentSize; ++i)
        {
            unsigned int index = (head + i) % maxSize;
            std::cout << buffer[index] << " ";
        }
        std::cout << std::endl;
    }
};

#endif // CIRCULAR_BUFFER_H
