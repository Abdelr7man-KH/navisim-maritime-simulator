#include "track.h"
#include "watercraft.h"
#include "Graphic.h"
#include "GraphicListModel.h"
#include "GraphicsOverlay.h"
#include <GraphicsOverlayListModel.h>
#include <TextSymbol.h>
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include "Point.h"
Track::Track(Esri::ArcGISRuntime::GraphicsOverlay* dashDottOverlay,
             Esri::ArcGISRuntime::GraphicsOverlay* contourOverlay,
             Watercraft* primaryShip,
             Esri::ArcGISRuntime::MapQuickView* mapView,
             QObject *parent)
    : QObject{parent},
    m_dashDottOverlay(dashDottOverlay),
    m_contourOverlay(contourOverlay),
    m_primaryShip(primaryShip),
    m_mapView(mapView)
{
    m_timerStarted       = false;
    m_lastStampRealTime  = 0.0;

    recalculateTrailSettings(&m_plottingMaxStamps,m_plottingPeriodSeconds,m_plottingDurationMinutes);  // ← must be called BEFORE creating strategies
    recalculateTrailSettings(&m_trackMaxStamps,m_trackPeriodSeconds,m_trackDurationMinutes);
    qInfo() << "activateTrack — maxStamps:" << m_plottingMaxStamps
            << "contourOverlay:" << (contourOverlay ? "ok" : "NULL")
            << "dashDotOverlay:" << (dashDottOverlay ? "ok" : "NULL")
            << "ship:" << (primaryShip ? primaryShip->name() : "NULL");

    qInfo() << "activateTrack — maxStamps:" << m_trackMaxStamps
            << "contourOverlay:" << (contourOverlay ? "ok" : "NULL")
            << "dashDotOverlay:" << (dashDottOverlay ? "ok" : "NULL")
            << "ship:" << (primaryShip ? primaryShip->name() : "NULL");

    if (!contourOverlay || !dashDottOverlay || !primaryShip)
    {
        qWarning() << "activateTrack — null parameter, aborting";
        return;
    }

    m_trailStrategyDashDotted = new DashDotTrailOption(120);
    m_trailStrategyDashDotted->initialize(dashDottOverlay);

    m_trailStrategyContour = new ContourTrailOption(primaryShip, 120);
    m_trailStrategyContour->initialize(contourOverlay);

    qInfo() << "activateTrack — strategies created successfully";
}
void Track::addTimestampLabel(QPointF location, float headingDeg,
                                          double elapsedSeconds)
{
    // Show label at 0, 30s, 1min, 2min, 5min, 10min intervals
    QString labelText = QTime::currentTime().toString("hh:mm:ss");
    bool shouldLabel = false;

    // Create label overlay if needed
    if (!m_trailLabelOverlay)
    {
        m_trailLabelOverlay = new Esri::ArcGISRuntime::GraphicsOverlay(this);
        m_mapView->graphicsOverlays()->append(m_trailLabelOverlay);
    }

    // Offset label slightly to the side of the ship
    QPointF labelPos = m_primaryShip->getOffsetPoint(
        location, headingDeg, 0, 80);  // 80m to starboard

    Esri::ArcGISRuntime::Point labelPoint(labelPos.x(), labelPos.y(), Esri::ArcGISRuntime::SpatialReference::wgs84());

    Esri::ArcGISRuntime::TextSymbol* text = new Esri::ArcGISRuntime::TextSymbol(this);
    text->setText(labelText);
    text->setColor(QColor(255, 220, 0));   // yellow
    text->setSize(12.0f);
    text->setHorizontalAlignment(Esri::ArcGISRuntime::HorizontalAlignment::Left);
    text->setVerticalAlignment(Esri::ArcGISRuntime::VerticalAlignment::Middle);

    Esri::ArcGISRuntime::Graphic* labelGraphic = new Esri::ArcGISRuntime::Graphic(this);
    labelGraphic->setGeometry(labelPoint);
    labelGraphic->setSymbol(text);
    m_trailLabelOverlay->graphics()->append(labelGraphic);
    m_trailLabelGraphics.append(labelGraphic);

    if (m_trailLabelGraphics.size() > m_plottingMaxStamps)
    {
        Esri::ArcGISRuntime::Graphic* oldestLabel = m_trailLabelGraphics.takeFirst();
        m_trailLabelOverlay->graphics()->removeOne(oldestLabel);
        delete oldestLabel; // Safely free up the pointer resource
    }
}

void Track::setTimeStampDurationMinutes(double newTimeStampDurationMinutes)
{
    m_timeStampDurationMinutes = newTimeStampDurationMinutes;
    clearTrail();
}

void Track::setTrack(int newTrackPeriodSeconds,int newTrackDurationMinutes,QColor color)
{
    m_trackDurationMinutes = newTrackDurationMinutes;
    m_trackPeriodSeconds = newTrackPeriodSeconds;
    m_TrackColor = color;
    clearTrail();

}

void Track::setPlotting(int newPlottingPeriodSeconds,int newPlottingDurationMinutes,QColor color)
{
    m_plottingDurationMinutes = newPlottingDurationMinutes;
    m_plottingPeriodSeconds = newPlottingPeriodSeconds;
    m_PlottingColor = color;
    clearTrail();
}


void Track::clearTrail()
{
    if (m_trailStrategyContour && m_trailStrategyDashDotted){
        m_trailStrategyContour->clear();
        m_trailStrategyDashDotted->clear();
    }

    if (m_trailLabelOverlay)
        m_trailLabelOverlay->graphics()->clear();

    m_trailLabelGraphics.clear();
    m_realTimer.restart();
    m_lastStampRealTime  = 0.0;
    m_lastPlotRealTime = 0.0;
    m_lastTrackRealTime = 0.0;
    recalculateTrailSettings(&m_plottingMaxStamps,m_plottingPeriodSeconds,m_plottingDurationMinutes);  // ← must be called BEFORE creating strategies
    recalculateTrailSettings(&m_trackMaxStamps,m_trackPeriodSeconds,m_trackDurationMinutes);
    if (m_dashDottOverlay)
    {
        delete m_trailStrategyDashDotted;
        m_trailStrategyDashDotted = new DashDotTrailOption(m_plottingMaxStamps,m_PlottingColor);
        m_trailStrategyDashDotted->initialize(m_dashDottOverlay);
    }

    if (m_contourOverlay && m_primaryShip)
    {
        delete m_trailStrategyContour;
        m_trailStrategyContour = new ContourTrailOption(m_primaryShip, m_trackMaxStamps,m_TrackColor);
        m_trailStrategyContour->initialize(m_contourOverlay);
    }
}

// void Track::updateTrackPosition(QPointF position, float heading, Esri::ArcGISRuntime::MapQuickView* mapView, Watercraft* primaryShip)
// {
//     const double dT = 0.1; // Match your simulation step rate
//     m_elapsedSeconds += dT;
//     m_totalElapsedSeconds += dT;
//     static int callCount = 0;
//     callCount++;
//     if (callCount % 100 == 0)
//         qInfo() << "Track tick — elapsed:" << m_elapsedSeconds
//                 << "/ period:" << m_trailPeriodSeconds
//                 << "/ total:" << m_totalElapsedSeconds
//                 << "/ maxDuration:" << m_trailDurationMinutes * 60.0;
//     double maxDurationSeconds = m_trailDurationMinutes * 60.0;

//     if (m_elapsedSeconds >= m_trailPeriodSeconds) {
//         if (m_totalElapsedSeconds <= maxDurationSeconds) {

//             qInfo() << "STAMP at elapsed:" << m_elapsedSeconds
//                     << "period:" << m_trailPeriodSeconds;
//             // Render to whatever strategy paths are selected/available
//             if (m_trailStrategyDashDotted) {
//                 m_trailStrategyDashDotted->addPoint(position, heading);
//             }
//             if (m_trailStrategyContour) {
//                 m_trailStrategyContour->addPoint(position, heading);
//             }

//             // Add chronological time indicator badge
//             addTimestampLabel(position, heading, m_totalElapsedSeconds, mapView, primaryShip);
//         }

//         m_elapsedSeconds -= m_trailPeriodSeconds;
//     }
// }
void Track::updateTrackPosition(QPointF position, float heading)
{
    if (!m_timerStarted)
    {
        m_realTimer.start();
        m_timerStarted = true;
    }

    double realSecondsElapsed = m_realTimer.elapsed() / 1000.0;

    double plottingMaxDurationSeconds = m_plottingDurationMinutes * 60.0;
    double trackMaxDurationSeconds = m_trackDurationMinutes * 60.0;
    double timeStampMaxDurationSeconds = m_timeStampDurationMinutes * 60;

    double currentPlotSecondElapsed = realSecondsElapsed - m_lastPlotRealTime;
    if (currentPlotSecondElapsed >= m_plottingPeriodSeconds)
    {
        if (realSecondsElapsed <= plottingMaxDurationSeconds+1)
        {
            if (m_trailStrategyDashDotted)
                m_trailStrategyDashDotted->addPoint(position, heading);
            m_lastPlotRealTime = realSecondsElapsed;
            qInfo() << "Plot STAMP  at real time:" << m_lastPlotRealTime << "s";
        }
        else
        {
            static bool logged = false;
            if (!logged) { qInfo() << "Plotting complete."; logged = true; }
        }
    }

    double currentTrackSecondElapsed = realSecondsElapsed - m_lastTrackRealTime;
    // ← use REAL time, not simulation dT
    if (currentTrackSecondElapsed >= m_trackPeriodSeconds)
    {
        if (realSecondsElapsed <= trackMaxDurationSeconds+1)
        {
            if (m_trailStrategyContour)
                m_trailStrategyContour->addPoint(position, heading);
            m_lastTrackRealTime = realSecondsElapsed;
        }
        else
        {
            static bool logged = false;
            if (!logged) { qInfo() << "Track complete."; logged = true; }
        }
    }
    double currentStampSecondElapsed = realSecondsElapsed - m_lastStampRealTime;
    if (currentStampSecondElapsed >= timeStampMaxDurationSeconds && currentStampSecondElapsed <= timeStampMaxDurationSeconds+1)
    {
        qInfo() << "Track STAMP  at real time:" << realSecondsElapsed << "s";
            addTimestampLabel(position, heading, realSecondsElapsed);
            m_lastStampRealTime = realSecondsElapsed;
    }
}

void Track::recalculateTrailSettings(int* trailMaxStamps,int trailPeriodSeconds,int trailDurationMinutes)
{
    // Number of contours = duration(seconds) / period
    int durationSeconds = trailDurationMinutes * 60;
    *trailMaxStamps    = durationSeconds / trailPeriodSeconds;
    qInfo() << "Trail: period=" << trailPeriodSeconds
            << "s  duration=" << trailDurationMinutes
            << "min  maxStamps=" << *trailMaxStamps;
}
