#include "watercraft.h"

#include "Graphic.h"
#include "GraphicListModel.h"
#include "GraphicsOverlay.h"
#include "Point.h"
#include "PolygonBuilder.h"
#include "SimpleFillSymbol.h"
#include "SimpleLineSymbol.h"
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include "GeometryEngine.h"
#include "GeometryTypes.h"
#include "LinearUnit.h"
#include "AngularUnit.h"
#include "GeometryTypes.h"

#include <AttributeListModel.h>
#include <QtMath>
#include <QDebug>

#include <QColor>

using namespace Esri::ArcGISRuntime;

Watercraft::Watercraft(Esri::ArcGISRuntime::GraphicsOverlay* overlay,QObject *parent)
    : m_overlay(overlay)
    ,PlaceableObject{parent}
{
    if (!m_overlay) return;

    m_preview = new Graphic(this);

    SimpleFillSymbol* previewSymbol = new SimpleFillSymbol(
        SimpleFillSymbolStyle::Solid,
        QColor(255, 255, 255, 80),   // semi-transparent white
        this);

    SimpleLineSymbol* previewOutline = new SimpleLineSymbol(
        SimpleLineSymbolStyle::Dash,
        QColor("white"),
        1.5f,
        this);
    previewSymbol->setOutline(previewOutline);

    m_preview->setSymbol(previewSymbol);
    m_preview->setVisible(false);
    m_overlay->graphics()->append(m_preview);
}


float Watercraft::speed() const
{
    return m_speed;
}

void Watercraft::setSpeed(float newSpeed)
{
    m_speed = newSpeed;
}

float Watercraft::course() const
{
    return m_course;
}

void Watercraft::setCourse(float newCourse)
{
    m_course = newCourse;
}

void Watercraft::placeObject(QPointF location)
{
    if (!m_graphic)
    {
        // First placement — create the permanent graphic
        SimpleFillSymbol* hullSymbol = new SimpleFillSymbol(
            SimpleFillSymbolStyle::Solid,
            m_color,
            this);

        SimpleLineSymbol* outline = new SimpleLineSymbol(
            SimpleLineSymbolStyle::Solid,
            QColor("white"),
            1.5f,
            this);
        hullSymbol->setOutline(outline);

        m_graphic = new Graphic(this);
        m_graphic->setSymbol(hullSymbol);
        m_graphic->attributes()->insertAttribute("name", name());
        m_graphic->attributes()->insertAttribute("id", id());
        m_graphic->attributes()->insertAttribute("Color", color());
        m_overlay->graphics()->append(m_graphic);
    }

    buildHullGraphic(location, m_course, m_graphic);

    // Hide the preview once placed
    showPreview(false);

    setStartingPosition(location);
    setCurrentLocation(location);

}

void Watercraft::moveObject(QPointF location)
{
    if (!m_graphic) return;
    buildHullGraphic(location, m_course, m_graphic);
    setCurrentLocation(location);
}

void Watercraft::rotateObject(QPointF angle)
{
    m_course = angle.x();   // pass heading as x component
    if (m_graphic)
        buildHullGraphic(getCurrentLocation(), m_course, m_graphic);
}

void Watercraft::deleteObject()
{
    if (m_graphic && m_overlay)
    {
        m_overlay->graphics()->removeOne(m_graphic);
        m_graphic = nullptr;
    }
    if (m_preview && m_overlay)
    {
        m_overlay->graphics()->removeOne(m_preview);
        m_preview = nullptr;
    }
    emit objectRemoved();
}

void Watercraft::objectInformation() const
{
    qDebug() << "Watercraft:" << name()
    << "| ID:"     << id()
    << "| Speed:"  << m_speed
    << "| Course:" << m_course
    << "| Pos:"    << getCurrentLocation();
}

bool Watercraft::watercraftSelected() const
{
    return m_watercraftSelected;
}

void Watercraft::setWatercraftSelected(bool selected)
{
    if (m_watercraftSelected == selected) return;
    m_watercraftSelected = selected;

    if (m_graphic)
    {
        SimpleFillSymbol* hullSymbol = new SimpleFillSymbol(
            SimpleFillSymbolStyle::Solid,
            selected ? QColor(0, 180, 255, 180)  // ← bright blue when selected
                     : m_color,                   // ← normal color when deselected
            this);

        SimpleLineSymbol* outline = new SimpleLineSymbol(
            SimpleLineSymbolStyle::Solid,
            selected ? QColor("cyan") : QColor("white"),
            selected ? 2.5f : 1.5f,
            this);

        hullSymbol->setOutline(outline);
        m_graphic->setSymbol(hullSymbol);
    }

    emit watercraftSelectedChanged(selected);
}

QColor Watercraft::color() const
{
    return m_color;
}

void Watercraft::setColor(QColor newColor)
{
    m_color = newColor;
}

QList<QPointF> Watercraft::kvlcc2HullPoints() const
{
    return {
        {  160.0,    0.0 },   // bow tip
        {  150.0,   10.0 },   // bow starboard shoulder
        {  120.0,   25.0 },   // forward starboard
        {   80.0,   29.0 },   // mid-forward starboard
        {    0.0,   29.0 },   // midship starboard
        {  -80.0,   29.0 },   // mid-aft starboard
        { -120.0,   27.0 },   // aft starboard
        { -145.0,   18.0 },   // stern starboard quarter
        { -155.0,    8.0 },   // stern starboard
        { -160.0,    0.0 },   // stern center
        { -155.0,   -8.0 },   // stern port
        { -145.0,  -18.0 },   // stern port quarter
        { -120.0,  -27.0 },   // aft port
        {  -80.0,  -29.0 },   // mid-aft port
        {    0.0,  -29.0 },   // midship port
        {   80.0,  -29.0 },   // mid-forward port
        {  120.0,  -25.0 },   // forward port
        {  150.0,  -10.0 },   // bow port shoulder
        {  160.0,    0.0 },   // back to bow tip (close)
    };
}

QPointF Watercraft::offsetPoint(QPointF center, float headingDeg,
                                float forwardMeters, float lateralMeters) const
{
    Point start(center.x(), center.y(), SpatialReference::wgs84());

    // Move forward along heading
    QList<Point> afterFwd = GeometryEngine::moveGeodetic(
        QList<Point>({start}),
        (double)forwardMeters,
        LinearUnit::meters(),
        (double)headingDeg,
        AngularUnit::degrees(),
        GeodeticCurveType::Geodesic);

    // Move laterally (starboard = heading + 90)
    float lateralBearing = headingDeg + 90.0f;
    QList<Point> latResult = GeometryEngine::moveGeodetic(
        {afterFwd},
        (double)lateralMeters,
        LinearUnit::meters(),
        (double)lateralBearing,
        AngularUnit::degrees(),
        GeodeticCurveType::Geodesic);

    Point final = latResult.first();
    return QPointF(final.x(), final.y());
}
void Watercraft::buildHullGraphic(QPointF location, float headingDeg,
                                  Graphic* target)
{
    QList<QPointF> hull = kvlcc2HullPoints();
    PolygonBuilder builder(SpatialReference::wgs84());

    for (const QPointF& pt : hull)
    {
        QPointF geo = offsetPoint(location, headingDeg, pt.x(), pt.y());
        builder.addPoint(geo.x(), geo.y());
    }

    target->setGeometry(builder.toGeometry());
}

int Watercraft::trailerOption() const
{
    return m_trailerOption;
}

void Watercraft::setTrailerOption(int newTrailerOption)
{
    m_trailerOption = newTrailerOption;
}

QColor Watercraft::trailerColor() const
{
    return m_trailerColor;
}

void Watercraft::setTrailerColor(const QColor &newTrailerColor)
{
    m_trailerColor = newTrailerColor;
}

void Watercraft::updatePreview(QPointF location)
{
    buildHullGraphic(location, m_course, m_preview);
}

void Watercraft::showPreview(bool visible)
{
    if (m_preview)
        m_preview->setVisible(visible);
}
