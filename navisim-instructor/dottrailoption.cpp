#include "DotTrailOption.h"
#include "Graphic.h"
#include "GraphicListModel.h"
#include "Point.h"
#include "SimpleMarkerSymbol.h"
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include <QColor>

using namespace Esri::ArcGISRuntime;

void DotTrailOption::addPoint(QPointF center, float /*headingDeg*/)
{
    if (!m_overlay) return;

    Point p(center.x(), center.y(), SpatialReference::wgs84());
    SimpleMarkerSymbol* dot = new SimpleMarkerSymbol(
        SimpleMarkerSymbolStyle::Circle, m_color, 4, nullptr);

    Graphic* g = new Graphic(nullptr);
    g->setGeometry(p);
    g->setSymbol(dot);
    m_overlay->graphics()->append(g);

    if (m_overlay->graphics()->size() > m_maxPoints)
        m_overlay->graphics()->removeAt(0);
}

void DotTrailOption::clear()
{
    if (m_overlay)
        m_overlay->graphics()->clear();
}
