#include "filters.h"
#include "autogain.h"
#include "echo_cancellation.h"

#include <vector>
#include <string>
#include <memory>

Filters::Filters(unsigned int samplerate) : mSamplerate(samplerate) {}

Filters::~Filters() {}

void Filters::setSampleRate(unsigned int samplerate)
{
    if (mSamplerate == samplerate)
        return;
    mSamplerate = samplerate;
    for (auto &fo : filters)
    {
        switch (fo->type)
        {
        case autogain:
            fo->filter = std::make_unique<AutoGain>(mSamplerate);
            break;
        case echoCancellation:
            fo->filter = std::make_unique<EchoCancellation>(mSamplerate);
            break;
        default:
            break;
        }
        if (fo->filter)
        {
            auto it = mStoredParams.find(fo->type);
            if (it != mStoredParams.end())
            {
                for (const auto &[attrId, val] : it->second)
                {
                    fo->filter->setParamValue(attrId, val);
                }
            }
        }
    }
}

int Filters::isFilterActive(RecorderFilterType filter)
{
    for (size_t i = 0; i < filters.size(); i++)
    {
        if (filters[i].get()->type == filter)
            return static_cast<int>(i);
    }
    return -1;
}

std::vector<std::string> Filters::getFilterParamNames(RecorderFilterType filterType)
{
    std::vector<std::string> ret;
    switch (filterType)
    {
    case RecorderFilterType::autogain:
    {
        AutoGain f;
        int nParams = f.getParamCount();
        for (int i = 0; i < nParams; i++)
            ret.push_back(f.getParamName(i));
    }
    break;
    case RecorderFilterType::echoCancellation:
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

CaptureErrors Filters::addFilter(RecorderFilterType filterType)
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

    auto it = mStoredParams.find(filterType);
    if (it != mStoredParams.end())
    {
        for (const auto &[attrId, val] : it->second)
        {
            newFilter->setParamValue(attrId, val);
        }
    }

    std::unique_ptr<FilterObject> nfo = std::make_unique<FilterObject>(filterType, std::move(newFilter));
    /// In [filters] we add the new filter to the list. All these filters must be processed inside the callback.
    filters.push_back(std::move(nfo));

    return CaptureErrors::captureNoError;
}

CaptureErrors Filters::removeFilter(RecorderFilterType filterType)
{
    int index = isFilterActive(filterType);
    if (index < 0)
        return CaptureErrors::filterNotFound;

    filters[index].get()->filter.reset();

    /// remove the filter from the list
    filters.erase(filters.begin() + index);

    return CaptureErrors::captureNoError;
}

void Filters::setFilterParams(RecorderFilterType filterType, int attributeId, float value)
{
    mStoredParams[filterType][attributeId] = value;
    int index = isFilterActive(filterType);
    if (index >= 0)
    {
        filters[index].get()->filter.get()->setParamValue(attributeId, value);
    }
}

float Filters::getFilterParams(RecorderFilterType filterType, int attributeId)
{
    int index = isFilterActive(filterType);
    if (index >= 0)
    {
        return filters[index].get()->filter.get()->getParamValue(attributeId);
    }

    auto it = mStoredParams.find(filterType);
    if (it != mStoredParams.end())
    {
        auto itParam = it->second.find(attributeId);
        if (itParam != it->second.end())
        {
            return itParam->second;
        }
    }

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

void Filters::feedPlaybackData(const void *pData, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    int index = isFilterActive(RecorderFilterType::echoCancellation);
    if (index >= 0 && filters[index]->filter)
    {
        auto *ec = dynamic_cast<EchoCancellation *>(filters[index]->filter.get());
        if (ec != nullptr)
        {
            ec->feedPlaybackData(pData, frameCount, channels, format);
        }
    }
}
