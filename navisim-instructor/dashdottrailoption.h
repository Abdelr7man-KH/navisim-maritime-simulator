#ifndef DASHDOTTRAILOPTION_H
#define DASHDOTTRAILOPTION_H

#include <QObject>
#include "TrailOptions.h"
#include "Graphic.h"
#include <QColor>
#include <QList>
class DashDotTrailOption : public QObject,public TrailOptions
{
    Q_OBJECT
public:
    explicit DashDotTrailOption(int maxPoints = 120,QColor color = QColor(255,255,255,180))
        : m_maxPoints(maxPoints),m_color(color){}

    void initialize(Esri::ArcGISRuntime::GraphicsOverlay* overlay) override;
    void addPoint(QPointF center, float headingDeg) override;
    void clear() override;
    void setVisibilty(bool vis) override;

    void setStop(bool newStop);

private:
    Esri::ArcGISRuntime::GraphicsOverlay* m_overlay     = nullptr;
    Esri::ArcGISRuntime::Graphic*         m_lineGraphic = nullptr;
    QList<QPointF>                        m_points;
    QList<Esri::ArcGISRuntime::Graphic*> m_dots;
    int m_maxPoints = 120;
    bool m_stop = false;
    QColor m_color;
};

#endif // DASHDOTTRAILOPTION_H
