#include "ContourTrailOption.h"
#include "GraphicListModel.h"
#include "PolygonBuilder.h"
#include "SimpleFillSymbol.h"
#include "SimpleLineSymbol.h"
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include "Geometry.h"
using namespace Esri::ArcGISRuntime;

void ContourTrailOption::initialize(GraphicsOverlay* overlay)
{
    m_overlay = overlay;
    setVisibilty(true);
    clear();
}

void ContourTrailOption::addPoint(QPointF center, float headingDeg)
{
    if (!m_overlay || !m_ship) return;

    if (m_stamps.size() > m_maxStamps)
        return;
    QList<QPointF> hull = m_ship->getHullPoints();
    PolygonBuilder builder(SpatialReference::wgs84());

    for (const QPointF& pt : hull)
    {
        QPointF geo = m_ship->getOffsetPoint(center, headingDeg, pt.x(), pt.y());
        builder.addPoint(geo.x(), geo.y());
    }

    SimpleLineSymbol* outline = new SimpleLineSymbol(
        SimpleLineSymbolStyle::Dash,
        m_color, 2.0f, nullptr);

    SimpleFillSymbol* fill = new SimpleFillSymbol(SimpleFillSymbolStyle::Null, QColor(0, 0, 0, 0), this);
    fill->setOutline(outline);

    Graphic* stamp = new Graphic(nullptr);
    stamp->setGeometry(builder.toGeometry());
    stamp->setSymbol(fill);
    m_overlay->graphics()->append(stamp);
    m_stamps.append(stamp);


}

void ContourTrailOption::clear()
{
    if (m_overlay)
        m_overlay->graphics()->clear();
    m_stamps.clear();
}
void ContourTrailOption::setVisibilty(bool vis){
    m_overlay->setVisible(vis);
}
