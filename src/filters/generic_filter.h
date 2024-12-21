#ifndef GENERIC_FILTERS_H
#define GENERIC_FILTERS_H

#include "../miniaudio.h"

#include <string>

// Abstract Base Class for Generic Filters
class GenericFilter {
public:
    virtual ~GenericFilter() = default;

    // Methods for managing parameters
    virtual int getParamCount() const = 0;
    virtual float getParamMax(int param) const = 0;
    virtual float getParamMin(int param) const = 0;
    virtual float getParamDef(int param) const = 0;
    virtual std::string getParamName(int param) const = 0;
    virtual void setParamValue(int param, float value) = 0;
    virtual float getParamValue(int param) const = 0;

    // Pure virtual method to apply the filter (to be implemented by derived classes)
    virtual void process(void* pInput, ma_uint32 frameCount, unsigned int channels, ma_format format) = 0;
};

#endif // GENERIC_FILTERS_H