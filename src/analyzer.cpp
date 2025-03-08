#include "analyzer.h"
#include "fft/soloud_fft.h"

#include <math.h>
#include <cstring>
#include <iostream>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

Analyzer::Analyzer(int windowSize, float sampleRate)
    : mWindowSize(windowSize),
      sampleRate(sampleRate),
      alpha(0.16f),
      a0(0.5f * (1 - alpha)),
      a1(0.5f),
      a2(0.5f * alpha),
      fftSmoothing(0.8)
{
    for (float &i : FFTData)
        i = 0.0f;
    for (float &i : temp)
        i = 0.0f;
}

Analyzer::~Analyzer() = default;

/// Blackman windowing (used by ShaderToy).
void Analyzer::blackmanWindow(float *samples, const float *waveData) const
{
    for (int i = 0; i < 256; i++) {
        float multiplier = a0 - a1 * cosf(2 * M_PI * i / mWindowSize) + a2 * cosf(4 * M_PI * i / mWindowSize);
        samples[i*2] = waveData[i] * multiplier;
        samples[i*2+1] = 0;
        samples[i+512] = 0;
        samples[i+768] = 0;
    }
}

/// Hann windowing
void Analyzer::hanningWindow(float *samples, const float *waveData) const
{
    for (int i = 0; i < 256; i++)
    {
        samples[i * 2] = waveData[i] * 0.5f * (1.0f - cosf(2.0f * M_PI * (float)(i) / (float)(mWindowSize - 1)));
        samples[i * 2 + 1] = 0.0f;
        samples[i + 512] = 0.0f;
        samples[i + 768] = 0.0f;
    }
}

/// Hamming windowing
void Analyzer::hammingWindow(float *samples, const float *waveData) const
{
    for (int i = 0; i < 256; i++)
    {
        samples[i * 2] = waveData[i] * (0.54f - 0.46f * cosf(2.0f * M_PI * i / (mWindowSize - 1)));
        samples[i * 2 + 1] = 0.0f;
        samples[i + 512] = 0.0f;
        samples[i + 768] = 0.0f;
    }
}

void Analyzer::plainWindow(float *samples, const float *waveData) const
{
    // First clear the entire buffer
    memset(samples, 0, sizeof(float) * 1024);
    
    // Apply window function to first 256 samples and interleave with zeros for complex FFT
    for (int i = 0; i < 256; i++) {
        samples[i * 2] = waveData[i];     // Real part
        samples[i * 2 + 1] = 0.0f;        // Imaginary part
    }
}

int Analyzer::freqToBin(float frequency) const {
    // Simpler linear mapping
    return static_cast<int>((frequency * 256.0f) / maxFreq);
}

int Analyzer::mapFrequencyToFFTDataIndex(float freq) const {
    // Map frequency to 0-255 range
    return static_cast<int>(255.0f * (freq - minFreq) / (maxFreq - minFreq));
}

float Analyzer::mapFFTDataIndexToFrequency(int index) const {
    // Map 0-255 range back to frequency
    return minFreq + (index * (maxFreq - minFreq) / 255.0f);
}

float* Analyzer::calcFFT(float* waveData, float minFrequency, float maxFrequency)
{
    if (waveData == nullptr)
        return nullptr;

    blackmanWindow(temp, waveData);
    // hanningWindow(temp, waveData);
    // hammingWindow(temp, waveData);
    // plainWindow(temp, waveData);

    FFT::fft1024(temp);

    for (int i = 0; i < 256; i++)
    {
        float real = temp[i * 2];
        float imag = temp[i * 2 + 1];
        float mag = sqrtf(real*real+imag*imag);
        // The "+ 1.0" is to make sure I don't get negative values,
        float t = 20.0f * log10f(mag+0.995f);

        if (t > 1.0f) t = 1.0f;
        else if (t < 0.00001) t = 0.0f;
        if (t >= FFTData[i])
            FFTData[i] = t;
        else {
            // smooth when decreasing the new value with the previous
            FFTData[i] = fftSmoothing * FFTData[i] + (1.0f-fftSmoothing) * t;
        }
    }

    return FFTData;
}

float Analyzer::getBinFrequency(int binIndex) const {
    // Consider Nyquist frequency
    return binIndex * (sampleRate * 0.5f / 256.0f);
}

void Analyzer::setWindowsSize(int fftWindowSize)
{
    mWindowSize = fftWindowSize;
}

void Analyzer::setSmoothing(float smooth)
{
    if (smooth < 0.0f || smooth > 1.0f)
        return;
    fftSmoothing = smooth;
}