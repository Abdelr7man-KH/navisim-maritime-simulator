#include "ContourTrendOption.h"

#include "Geometry.h"
#include "GraphicListModel.h"
#include "PolygonBuilder.h"
#include "SimpleFillSymbol.h"
#include "SimpleLineSymbol.h"
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include "Geometry.h"

#include <Point.h>
#include <QtMath>
#include <TextSymbol.h>

using namespace Esri::ArcGISRuntime;

void ContourTrendOption::initialize(GraphicsOverlay* overlay)
{
    m_overlay = overlay;
    clear();
}

void ContourTrendOption::update(QPointF currentPos,
                                double headingDeg,
                                double speedMs)
{
    // ── Wipe every frame — trend is always recalculated from scratch ──────
    clear();
    // ── DIAGNOSTIC LOGS ──────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────────────
    if (!m_enabled || !m_overlay || !m_ship) return;
    if (speedMs < 0.01) return;  // ship not moving — no trend

    const double metersPerDegree = 111320.0;
    double cosLat     = qCos(qDegreesToRadians(currentPos.y()));
    double headingRad = qDegreesToRadians(headingDeg);

    double totalSeconds = m_minutes * 60.0;
    double stepSeconds  = totalSeconds / m_steps;

    for (int i = 1; i <= m_steps; i++)
    {
        double t = i * stepSeconds;

        // ── Dead reckoning — constant speed + heading ─────────────────────
        double dNorth = speedMs * qCos(headingRad) * t;
        double dEast  = speedMs * qSin(headingRad) * t;

        double futureLat = currentPos.y() + (dNorth / metersPerDegree);
        double futureLon = currentPos.x() + (dEast  / (metersPerDegree * cosLat));

        QPointF futurePos(futureLon, futureLat);

        // ── Fade: first stamp = most opaque, last = most transparent ─────
        double fadeFactor = 1.0 - (double(i - 1) / m_steps) * 0.75;
        int alpha = (int)(m_color.alpha() * fadeFactor);

        QColor stepColor(m_color.red(), m_color.green(),
                         m_color.blue(), alpha);

        // ── Draw hull contour at future position ──────────────────────────
        stampHull(futurePos, headingDeg, stepColor);

        // ── Label at midpoint and final step ─────────────────────────────
        if (i == m_steps || i == m_steps / 2)
            addLabel(futurePos, headingDeg, t);
    }

}

void ContourTrendOption::stampHull(QPointF pos,
                                   double headingDeg,
                                   QColor color)
{
    if (!m_overlay || !m_ship) return;

    QList<QPointF> hull = m_ship->getHullPoints();
    PolygonBuilder builder(SpatialReference::wgs84());

    double halfLength = 75.0; // Must match the exact displacement used in step 1
    for (const QPointF& pt : hull)
    {
        QPointF geo = m_ship->getOffsetPoint(pos, headingDeg,
                                             pt.x()-halfLength, pt.y());
        builder.addPoint(geo.x(), geo.y());
    }
    // Inside ContourTrendOption::stampHull
    SimpleLineSymbol* outline = new SimpleLineSymbol(
        SimpleLineSymbolStyle::Solid,
        color,
        1.5f,
        m_overlay
        );

    // FIX: Added 'outline' as the 3rd argument to match the SDK signature perfectly
    SimpleFillSymbol* fill = new SimpleFillSymbol(
        SimpleFillSymbolStyle::Null,
        QColor(0,0,0,0),
        outline,                     // <--- Missing parameter added here
        m_overlay
        );

    Graphic* stamp = new Graphic(m_overlay);
    stamp->setGeometry(builder.toGeometry());
    stamp->setSymbol(fill);

    m_overlay->graphics()->append(stamp);
    m_graphics.append(stamp);
}

void ContourTrendOption::addLabel(QPointF pos,
                                  double headingDeg,
                                  double seconds)
{
    if (!m_overlay || !m_ship) return;

    // Offset label 80m to starboard of the hull
    QPointF labelPos = m_ship->getOffsetPoint(pos, headingDeg, 0, 80);
    Point labelPoint(labelPos.x(), labelPos.y(), SpatialReference::wgs84());

    QString labelText = seconds < 60
                            ? QString("+%1s").arg((int)seconds)
                            : QString("+%1 min").arg((int)(seconds / 60.0));

    TextSymbol* text = new TextSymbol(nullptr);
    text->setText(labelText);
    text->setColor(QColor(66, 245, 176));
    text->setSize(11.0f);
    text->setHorizontalAlignment(HorizontalAlignment::Left);
    text->setVerticalAlignment(VerticalAlignment::Middle);

    Graphic* label = new Graphic(nullptr);
    label->setGeometry(labelPoint);
    label->setSymbol(text);

    m_overlay->graphics()->append(label);
    m_graphics.append(label);
}

void ContourTrendOption::clear()
{
    if (m_overlay)
    {
        for (Graphic* g : std::as_const(m_graphics)) {
            m_overlay->graphics()->removeOne(g);
            delete g;
        }
    }
    m_graphics.clear();
}
void ContourTrendOption::setVisibilty(bool vis){
    m_overlay->setVisible(vis);
}

