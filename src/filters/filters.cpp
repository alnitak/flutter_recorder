#include "filters.h"
#include "autogain.h"
#include "echo_cancellation.h"

#include <vector>
#include <string>
#include <memory>

Filters::Filters(unsigned int samplerate) : mSamplerate(samplerate) {}

Filters::~Filters() {}

int Filters::isFilterActive(FilterType filter)
{
    for (int i = 0; i < filters.size(); i++)
    {
        if (filters[i].get()->type == filter)
            return i;
    }
    return -1;
}

std::vector<std::string> Filters::getFilterParamNames(FilterType filterType)
{
    std::vector<std::string> ret;
    switch (filterType)
    {
    case FilterType::autogain:
    {
        AutoGain f;
        int nParams = f.getParamCount();
        for (int i = 0; i < nParams; i++)
            ret.push_back(f.getParamName(i));
    }
    break;
    case FilterType::echoCancellation:
    {
        EchoCancellation f;
        int nParams = f.getParamCount();
        for (int i = 0; i < nParams; i++)
            ret.push_back(f.getParamName(i));
    }
    break;
    default:
        break;
    }

    return ret;
}

CaptureErrors Filters::addFilter(FilterType filterType)
{
    // Check if the new filter is already here.
    // Only one kind of filter allowed.
    if (isFilterActive(filterType) >= 0)
        return CaptureErrors::filterAlreadyAdded;

    std::unique_ptr<GenericFilter> newFilter;
    switch (filterType)
    {
    case autogain:
        newFilter = std::make_unique<AutoGain>(mSamplerate);
        break;
    case echoCancellation:
        newFilter = std::make_unique<EchoCancellation>(mSamplerate);
        break;
    default:
        return CaptureErrors::filterNotFound;
    }

    std::unique_ptr<FilterObject> nfo = std::make_unique<FilterObject>(filterType, std::move(newFilter));
    /// In [filters] we add the new filter to the list. All these filters must be processed inside the callback.
    filters.push_back(std::move(nfo));

    return CaptureErrors::captureNoError;
}

CaptureErrors Filters::removeFilter(FilterType filterType)
{
    int index = isFilterActive(filterType);
    if (index < 0)
        return CaptureErrors::filterNotFound;

    filters[index].get()->filter.reset();

    /// remove the filter from the list
    filters.erase(filters.begin() + index);

    return CaptureErrors::captureNoError;
}

void Filters::setFilterParams(FilterType filterType, int attributeId, float value)
{
    int index = isFilterActive(filterType);
    if (index < 0)
        return;
    filters[index].get()->filter.get()->setParamValue(attributeId, value);
}

float Filters::getFilterParams(FilterType filterType, int attributeId)
{
    int index = isFilterActive(filterType);
    // If not active return its default value
    if (index < 0) {
        switch (filterType)
        {
        case autogain:
            return AutoGain(0).getParamDef(attributeId);
        case echoCancellation:
            return EchoCancellation(0).getParamDef(attributeId);
        default:
            return 9999.f;
        }
    }

    float ret = filters[index].get()->filter.get()->getParamValue(attributeId);

    return ret;
}
