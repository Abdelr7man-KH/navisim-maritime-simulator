#ifndef DISPLAY_S57_CHART_H
#define DISPLAY_S57_CHART_H

namespace Esri::ArcGISRuntime {
class Map;
class MapQuickView;
} // namespace Esri::ArcGISRuntime

#include <EncExchangeSet.h>
#include <QObject>
#include "GraphicsOverlay.h"
#include "Point.h"
#include "watercraft.h"
#include <QFileInfo>
#include "TrailOptions.h"
#include "DashDotTrailOption.h"
#include "contourtrailoption.h"
#include "track.h"
#include "contourtrendoption.h"
Q_MOC_INCLUDE("MapQuickView.h")

class Display_s57_chart : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Esri::ArcGISRuntime::MapQuickView* mapView READ mapView WRITE setMapView NOTIFY mapViewChanged)
    Q_PROPERTY(bool placingWatercraft READ placingWatercraft NOTIFY placingWatercraftChanged)
    Q_PROPERTY(bool replacingWatercraft READ replacingWatercraft NOTIFY replacingWatercraftChanged)
    Q_PROPERTY(bool rotatingWatercraft READ rotatingWatercraft NOTIFY rotatingWatercraftChanged)
    Q_PROPERTY(bool hasSelectedWatercraft READ hasSelectedWatercraft NOTIFY selectedWatercraftChanged)
    Q_PROPERTY(Watercraft* selectedWatercraft READ selectedWatercraft NOTIFY selectedWatercraftChanged)
    Q_PROPERTY(Watercraft* primaryShip READ primaryShip WRITE setPrimaryShip NOTIFY primaryShipChanged FINAL)
    Q_PROPERTY(bool cameraLock READ cameraLock WRITE setCameraLock NOTIFY cameraSettingsChanged FINAL)
    Q_PROPERTY(double currentMapScale READ currentMapScale NOTIFY mapScaleChanged)
    Q_PROPERTY(bool erblActive READ erblActive NOTIFY erblActiveChanged FINAL)
    Q_PROPERTY(bool erblOriginSet READ erblOriginSet NOTIFY erblOriginSetChanged FINAL)
    Q_PROPERTY(bool centerModeActive READ centerModeActive WRITE setCenterModeActive NOTIFY centerModeActiveChanged)
public:
    explicit Display_s57_chart(QObject *parent = nullptr);
    ~Display_s57_chart() override;

    // ── Zoom Area ────────────────────────────────────────────────────────────
    Q_INVOKABLE void activateZoomArea();
    Q_INVOKABLE void deactivateZoomArea();

    // ── zoom box ─────────────────────────────────────────────────────
    Q_INVOKABLE void startZoomBox(double screenX, double screenY);
    Q_INVOKABLE void updateZoomBox(double screenX, double screenY);
    Q_INVOKABLE void finishZoomBox(double screenX, double screenY);
    //──chart centering─────────────────────────────────────────────────────
    Q_INVOKABLE void activateChartCentering();
    Q_INVOKABLE void deactivateChartCentering();
    Q_INVOKABLE void panMapCenter(int dx, int dy);


    // ── Getters ──────────────────────────────────────────────────────────────
    bool placingWatercraft()    const { return m_placingWatercraft; }
    bool replacingWatercraft()     const { return m_replacingWatercraft; }
    bool rotatingWatercraft()   const { return m_rotatingWatercraft; }
    bool hasSelectedWatercraft() const { return m_selectedWatercraft != nullptr; }
    Watercraft* selectedWatercraft() const { return m_selectedWatercraft; }  // ← moved here

    // ── Load charts ──────────────────────────────────────────────────────────────
    Q_INVOKABLE void loadEncChart(const QString& catalogPath);
    // ── Ruler ────────────────────────────────────────────────────────────────
    Q_INVOKABLE void activateRuler();
    Q_INVOKABLE void deactivateRuler();
    Q_INVOKABLE void setERBLOriginalPoint(double screenX, double screenY);
    Q_INVOKABLE void updateERBLLine(double screenX, double screenY);
    bool erblActive() const;
    bool erblOriginSet() const;
    // ── Map utils ────────────────────────────────────────────────────────────
    Q_INVOKABLE QPointF screenToLocation(double x, double y);
    Q_INVOKABLE QString screenToEcdisCoordinate(double x, double y);
    Q_INVOKABLE void setMapScale(double scale);
    double currentMapScale() const;
    Q_INVOKABLE void identifyDepthAtScreen(double screenX, double screenY);
    // ── Watercraft placement ──────────────────────────────────────────────────
    Q_INVOKABLE void startPlacingWatercraft(const QString& name,const QColor& color);
    Q_INVOKABLE void cancelPlacing();
    Q_INVOKABLE void updatePendingPreview(double screenX, double screenY);
    Q_INVOKABLE void updatePlacingShip(double screenX, double screenY);
    // ── Watercraft selection ──────────────────────────────────────────────────
    Q_INVOKABLE void trySelectWatercraft(double screenX, double screenY);

    // ── Watercraft replace / rotate ──────────────────────────────────────────────
    Q_INVOKABLE void startReplacingWatercraft();
    Q_INVOKABLE void startRotatingWatercraft();
    Q_INVOKABLE void updateReplacingOrRotating(double screenX, double screenY);
    Q_INVOKABLE void confirmPlaceOrRotate(double screenX, double screenY);
    Q_INVOKABLE void selectedWatercraftInfo();
    // ── Watercraft moving ──────────────────────────────────────────────
    Q_INVOKABLE void movingWatercraft(double lat , double lon,double heading,double surge);
    // ── Trend options ──────────────────────────────────────────────
    Q_INVOKABLE void setTrendSteps(int steps);
    Q_INVOKABLE void setTrendMinutes(int minutes);
    Q_INVOKABLE void setTrend(int steps,int minutes,QColor);
    Q_INVOKABLE void setVisibiltyTrend(bool vis);
    // ── Trailer options ──────────────────────────────────────────────
    Q_INVOKABLE void setPlotting(int newPlottingPeriodSeconds,int newPlottingDurationMinutes,QColor color);
    Q_INVOKABLE void setTrack(int newTrackPeriodSeconds,int newTrackDurationMinutes,QColor color);
    Q_INVOKABLE void setTimeStampDurationMinutes(double newTimeStampDurationMinutes);
    Q_INVOKABLE void setVisibiltyPlot(bool vis);
    Q_INVOKABLE void setVisibiltyTrack(bool vis);
    // Q_INVOKABLE void clearTrail();
    // void activateTrailStrategy(int option);
    int trailPeriodSeconds() const { return m_trailPeriodSeconds; }
    int trailDurationMinutes() const { return m_trailDurationMinutes; }
    // ── Main Watercraft ──────────────────────────────────────────────
    Q_INVOKABLE void makeMainShip(QString watercraftName);
    Watercraft *primaryShip() const;
    void setPrimaryShip(Watercraft *newPrimaryShip);
    // ── Camera ──────────────────────────────────────────────
    Q_INVOKABLE void lockCamera();
    bool cameraLock() const;
    void setCameraLock(bool newCameraLock);
    bool centerModeActive() const { return m_centerModeActive; }
    void setCenterModeActive(bool active) {
        if (m_centerModeActive == active) return;
        m_centerModeActive = active;
        emit centerModeActiveChanged();
    }

signals:
    void mapViewChanged();
    void erblActiveChanged();
    void erblOriginSetChanged();
    void erblUpdated(double rangNM, double rangeMeters, double bearingDeg);
    void erblCleared();
    void rulerMeasured(double meters, double nauticalMiles);
    void placingWatercraftChanged();
    void replacingWatercraftChanged();
    void rotatingWatercraftChanged();
    void selectedWatercraftChanged();
    void watercraftInfoReady(QString info);
    void showContextMenu();
    void encLoadSuccess();
    void encLoadFailed(QString message);
    void primaryShipChanged();
    void cameraSettingsChanged();
    void mapScaleChanged();
    void depthIdentified(QString depthText);
    void trailSettingsChanged();
    void trendChanged();
    void centerModeActiveChanged();
private:
    Esri::ArcGISRuntime::MapQuickView* mapView() const;
    void setMapView(Esri::ArcGISRuntime::MapQuickView* mapView);
    void initiateRuler();
    void deselectAllWatercrafts();

    // ── Map ───────────────────────────────────────────────────────────────────
    Esri::ArcGISRuntime::Map*            m_map             = nullptr;
    Esri::ArcGISRuntime::MapQuickView*   m_mapView         = nullptr;
    Esri::ArcGISRuntime::EncExchangeSet* m_encExchangeSet  = nullptr;


    // ── Ruler ─────────────────────────────────────────────────────────────────
    Esri::ArcGISRuntime::GraphicsOverlay* m_rulerOverlay        = nullptr;
    Esri::ArcGISRuntime::Point            m_firstPoint;
    bool m_rulerActive            = false;
    bool m_waitingForSecondPoint  = false;

    bool  m_erblActive         = false;
    bool  m_erblOriginSet      = false;
    Esri::ArcGISRuntime::Point m_erblOrigin;

    // ERBL graphics
    Esri::ArcGISRuntime::GraphicsOverlay* m_erblOverlay    = nullptr;
    Esri::ArcGISRuntime::Graphic*         m_erblOriginDot  = nullptr;
    Esri::ArcGISRuntime::Graphic*         m_erblLine       = nullptr;
    Esri::ArcGISRuntime::Graphic*         m_erblEndDot     = nullptr;
    Esri::ArcGISRuntime::Graphic*         m_erblRangRing   = nullptr;

    void initERBL();
    void clearERBLGraphics();
    // ── Watercraft ────────────────────────────────────────────────────────────
    Esri::ArcGISRuntime::GraphicsOverlay* m_watercraftOverlay  = nullptr;
    QList<Watercraft*>                    m_watercrafts;
    Watercraft*                           m_pendingWatercraft  = nullptr;
    Watercraft*                           m_selectedWatercraft = nullptr;
    QPointF                               m_rotationAnchor;
    Watercraft*                           m_primaryShip = nullptr;  //────── Main ship ──────
    bool m_placingWatercraft   = false;
    bool m_replacingWatercraft    = false;
    bool m_rotatingWatercraft  = false;
    // ── Trailer ────────────────────────────────────────────────────────────
    // Time-based trail
    int     m_trailPeriodSeconds   = 30;   // stamp every 30 seconds
    int     m_trailDurationMinutes = 60;   // keep 60 minutes of history
    int     m_trailMaxStamps       = 0;    // calculated: duration*60 / period
    double  m_elapsedSeconds       = 0.0;  // time since last stamp
    double  m_totalElapsedSeconds  = 0.0;  // total time since trail started
    // Timestamp labels
    Esri::ArcGISRuntime::GraphicsOverlay* m_trailLabelOverlay = nullptr;
    QList<Esri::ArcGISRuntime::Graphic*>  m_trailLabelGraphics;
    // void recalculateTrailSettings();
    // void addTimestampLabel(QPointF location, float headingDeg, double elapsedSeconds);
    Esri::ArcGISRuntime::GraphicsOverlay* m_trailerOverlay = nullptr;
    std::unique_ptr<TrailOptions>        m_trailStrategy;

    Track* m_shipTracker = nullptr;

    Esri::ArcGISRuntime::GraphicsOverlay* m_trailerOverlayContour = nullptr;
    Esri::ArcGISRuntime::GraphicsOverlay* m_trailerOverlayDashDotted = nullptr;
    DashDotTrailOption*       m_trailStrategyContour = nullptr;
    ContourTrendOption*       m_trailStrategyDashDotted = nullptr;

    QPointF                               m_lastTrailPoint;
    int                                   m_currentTrail = 0;
    //───────────────Trend───────────────
    Esri::ArcGISRuntime::GraphicsOverlay* m_trendOverlay = nullptr;
    QList<Esri::ArcGISRuntime::Graphic*>  m_trendGraphics;
    ContourTrendOption* m_trend = nullptr;
    // ── Camera ────────────────────────────────────────────────────────────
    bool m_cameraLock                                       = false;

    //──zooms area ────────────────────────────────────────────────────────────
    Esri::ArcGISRuntime::GraphicsOverlay* m_zoomOverlay = nullptr;
    Esri::ArcGISRuntime::Graphic* m_zoomGraphic = nullptr;
    Esri::ArcGISRuntime::Point m_zoomStartPoint;
    bool m_zoomAreaActive = false;
    bool m_centerModeActive = false;
};

#endif // DISPLAY_S57_CHART_H
