#include "DashDotTrailOption.h"
#include "GraphicListModel.h"
#include "PolylineBuilder.h"
#include "SimpleLineSymbol.h"
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include "Geometry.h"
using namespace Esri::ArcGISRuntime;

void DashDotTrailOption::initialize(GraphicsOverlay* overlay)
{
    m_overlay = overlay;
    clear();

    SimpleLineSymbol* sym = new SimpleLineSymbol(
        SimpleLineSymbolStyle::DashDotDot,
        m_color, 4, nullptr);

    m_lineGraphic = new Graphic(nullptr);
    m_lineGraphic->setSymbol(sym);
    m_overlay->graphics()->append(m_lineGraphic);
}

void DashDotTrailOption::addPoint(QPointF center, float /*headingDeg*/)
{
    if (!m_overlay || !m_lineGraphic) return;

    m_points.append(center);

    if (m_points.size() >= 2)
    {
        PolylineBuilder builder(SpatialReference::wgs84());
        for (const QPointF& pt : std::as_const(m_points))
            builder.addPoint(pt.x(), pt.y());
        m_lineGraphic->setGeometry(builder.toGeometry());
    }
}

void DashDotTrailOption::clear()
{
    m_points.clear();
    if (m_overlay)
        m_overlay->graphics()->clear();
    m_lineGraphic = nullptr;
}
void DashDotTrailOption::setVisibilty(bool vis){
    m_overlay->setVisible(vis);
}


