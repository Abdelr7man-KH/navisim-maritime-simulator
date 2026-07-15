#ifndef DOTTRAILOPTION_H
#define DOTTRAILOPTION_H

#include <QObject>
#include "TrailOptions.h"
#include "GraphicsOverlay.h"
#include <QColor>
class DotTrailOption : public QObject,public TrailOptions
{
    Q_OBJECT
public:
    explicit DotTrailOption(int maxPoints = 120, QColor color = QColor(255,255,255,180))
        : m_maxPoints(maxPoints), m_color(color) {}

    void initialize(Esri::ArcGISRuntime::GraphicsOverlay* overlay) override
    {
        m_overlay = overlay;
        clear();
    }

    void addPoint(QPointF center, float headingDeg) override;
    void clear() override;

private:
    Esri::ArcGISRuntime::GraphicsOverlay* m_overlay = nullptr;
    int    m_maxPoints = 120;
    QColor m_color;
};

#endif // DOTTRAILOPTION_H
