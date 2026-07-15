#ifndef TRAILOPTIONS_H
#define TRAILOPTIONS_H
#include <QObject>
#include <QPointF>
#include "GraphicsOverlay.h"

namespace Esri::ArcGISRuntime { class GraphicsOverlay; }

class TrailOptions
{
public:
    virtual ~TrailOptions() = default;

    // Called once when this trail type is activated
    virtual void initialize(Esri::ArcGISRuntime::GraphicsOverlay* overlay) = 0;

    // Called every time the ship moves enough
    virtual void addPoint(QPointF center, float headingDeg) = 0;

    // Clear all graphics
    virtual void clear() = 0;

    virtual void setVisibilty(bool vis) = 0;
};
#endif // TRAILOPTIONS_H
