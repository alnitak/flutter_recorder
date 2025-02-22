#ifndef FILTERS_H
#define FILTERS_H

#include "../enums.h"
#include "generic_filter.h"

#include <vector>
#include <string>
#include <memory>

struct FilterObject
{
    RecorderFilterType type;
    std::unique_ptr<GenericFilter> filter;

    FilterObject(RecorderFilterType t, std::unique_ptr<GenericFilter> f)
        : type(t), filter(std::move(f)) {}

    bool operator==(RecorderFilterType const &i)
    {
        return (i == type);
    }
};

/// Class to manage global filters.
class Filters
{
    /// Setting the global filter to NULL will clear the global filter.
    /// The default maximum number of global filters active is 4, but this
    /// can be changed in a global constant in soloud.h (and rebuilding SoLoud).
public:
    Filters(unsigned int samplerate);
    ~Filters();

    /// Return -1 if the filter is not active or its index
    int isFilterActive(RecorderFilterType filter);
    
    CaptureErrors addFilter(RecorderFilterType filterType);
    
    CaptureErrors removeFilter(RecorderFilterType filterType);
    
    std::vector<std::string> getFilterParamNames(RecorderFilterType filterType);
    
    /// If [handle]==0 the operation is done to global filters.
    void setFilterParams(RecorderFilterType filterType, int attributeId, float value);
    
    /// If [handle]==0 the operation is done to global filters.
    float getFilterParams(RecorderFilterType filterType, int attributeId);
    
    unsigned int mSamplerate;

    std::vector<std::unique_ptr<FilterObject>> filters;
};

#endif // PLAYER_H
