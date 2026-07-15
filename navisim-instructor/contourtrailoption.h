#ifndef CONTOURTRAILOPTION_H
#define CONTOURTRAILOPTION_H

#include <QObject>
#include "TrailOptions.h"
#include "Graphic.h"
#include "Watercraft.h"
#include <QList>
class ContourTrailOption : public QObject,public TrailOptions
{
    Q_OBJECT
public:
    explicit ContourTrailOption(Watercraft* ship, int maxStamps = 120,QColor color = QColor(255,255,255,180))
        : m_ship(ship), m_maxStamps(maxStamps),m_color(color){}

    void initialize(Esri::ArcGISRuntime::GraphicsOverlay* overlay) override;
    void addPoint(QPointF center, float headingDeg) override;
    void clear() override;
    void setVisibilty(bool vis) override;
private:
    Esri::ArcGISRuntime::GraphicsOverlay* m_overlay = nullptr;
    Watercraft*                            m_ship    = nullptr;
    QList<Esri::ArcGISRuntime::Graphic*>  m_stamps;
    int m_maxStamps = 120;
    QColor m_color;

};

#endif // CONTOURTRAILOPTION_H
