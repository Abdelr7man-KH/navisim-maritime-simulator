#ifndef TRACK_H
#define TRACK_H

namespace Esri::ArcGISRuntime{}
#include <QObject>
#include "GraphicsOverlay.h"
#include "MapQuickView.h"
#include "DashDotTrailOption.h"
#include "contourtrailoption.h"
#include "watercraft.h"
#include <QFileInfo>
#include "TrailOptions.h"
#include <QElapsedTimer>
class Track : public QObject
{
    Q_OBJECT
public:
public:
    explicit Track(Esri::ArcGISRuntime::GraphicsOverlay* dashDottOverlay,
                   Esri::ArcGISRuntime::GraphicsOverlay* contourOverlay,
                   Watercraft* primaryShip,
                   Esri::ArcGISRuntime::MapQuickView* mapView,
                   QObject *parent = nullptr); // 💡 Fixed: Removed trailing comma before closing paren
    void clearTrail();
    void updateTrackPosition(QPointF position, float heading);
    void recalculateTrailSettings(int* trailMaxStamps,int trailPeriodSeconds,int trailDurationMinutes);

    void setPlotting(int newPlottingPeriodSeconds,int newPlottingDurationMinutes,QColor color);

    void setTrack(int newTrackPeriodSeconds,int newTrackDurationMinutes,QColor color);

    void setTimeStampDurationMinutes(double newTimeStampDurationMinutes);

signals:
private:
    void addTimestampLabel(QPointF location, float headingDeg,
                           double elapsedSeconds);
    Watercraft* m_primaryShip = nullptr;
    Esri::ArcGISRuntime::MapQuickView* m_mapView= nullptr;
    Esri::ArcGISRuntime::GraphicsOverlay* m_dashDottOverlay= nullptr;
    Esri::ArcGISRuntime::GraphicsOverlay* m_contourOverlay= nullptr;

    Esri::ArcGISRuntime::GraphicsOverlay* m_trailLabelOverlay = nullptr;
    QList<Esri::ArcGISRuntime::Graphic*>  m_trailLabelGraphics;
    Esri::ArcGISRuntime::GraphicsOverlay* m_trailerOverlayContour = nullptr;
    Esri::ArcGISRuntime::GraphicsOverlay* m_trailerOverlayDashDotted = nullptr;
    ContourTrailOption*        m_trailStrategyContour;
    DashDotTrailOption*       m_trailStrategyDashDotted;

    int     m_plottingPeriodSeconds   = 1;   // stamp every 30 seconds
    int     m_plottingDurationMinutes = 1;   // keep 60 minutes of history
    int     m_plottingMaxStamps       = 0;    // calculated: duration*60 / period
    QColor  m_PlottingColor = QColor(255,255,255,180);

    int     m_trackPeriodSeconds   = 3;   // stamp every 30 seconds
    int     m_trackDurationMinutes = 1;   // keep 60 minutes of history
    int     m_trackMaxStamps       = 0;    // calculated: duration*60 / period
    QColor  m_TrackColor = QColor(255,255,255,180);

    double m_timeStampDurationMinutes = 0.5;

    QElapsedTimer m_realTimer;
    double m_lastPlotRealTime = 0.0;
    double m_lastTrackRealTime = 0.0;
    double m_lastStampRealTime = 0.0;
    bool m_timerStarted = false;
};

#endif // TRACK_H
