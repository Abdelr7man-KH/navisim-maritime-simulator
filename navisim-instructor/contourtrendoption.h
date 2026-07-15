#ifndef CONTOURTRENDOPTION_H
#define CONTOURTRENDOPTION_H

#include "Watercraft.h"
#include "GraphicsOverlay.h"
#include "Graphic.h"
#include <QColor>
#include <QList>
#include <QPointF>

namespace Esri::ArcGISRuntime {
class GraphicsOverlay;
class Graphic;
}

class ContourTrendOption
{
public:
    explicit ContourTrendOption(Watercraft* ship,
                                int steps      = 6,
                                int minutes    = 3,
                                QColor color   = QColor(0, 0, 0, 0))
        : m_ship(ship)
        , m_steps(steps)
        , m_minutes(minutes)
        , m_color(color)
    {}

    // Call once to set the overlay
    void initialize(Esri::ArcGISRuntime::GraphicsOverlay* overlay);

    // Call every frame — wipes and redraws completely
    void update(QPointF currentPos, double headingDeg, double speedMs);

    // Wipe all trend graphics
    void clear();

    // Setters — call when UI sliders change
    void setSteps(int steps)     { m_steps   = qBound(1, steps, 12); }
    void setMinutes(int minutes) { m_minutes = qBound(1, minutes, 6); }
    void setColor(QColor color)  { m_color   = color; }
    void setEnabled(bool enabled){ m_enabled = enabled; if (!enabled) clear(); }

    void setVisibilty(bool vis);
    bool isEnabled() const { return m_enabled; }

private:
    void stampHull(QPointF pos, double headingDeg, QColor color);
    void addLabel(QPointF pos, double headingDeg, double seconds);

    Esri::ArcGISRuntime::GraphicsOverlay* m_overlay = nullptr;
    Watercraft*                            m_ship    = nullptr;

    QList<Esri::ArcGISRuntime::Graphic*>  m_graphics;  // all trend graphics

    int    m_steps   = 6;
    int    m_minutes = 3;
    bool   m_enabled = true;
    QColor m_color   = QColor(0, 0, 0, 0);
};

#endif // CONTOURTRENDOPTION_H
