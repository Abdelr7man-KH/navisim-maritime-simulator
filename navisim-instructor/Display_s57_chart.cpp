#include "Display_s57_chart.h"

#include "EncCell.h"
#include "EncDataset.h"
#include "EncEnvironmentSettings.h"
#include "EncExchangeSet.h"
#include "EncLayer.h"
#include "Envelope.h"
#include "TaskWatcher.h"
#include "LayerListModel.h"
#include "Map.h"
#include "MapQuickView.h"
#include "MapTypes.h"
#include "Viewpoint.h"
#include "AngularUnit.h"
#include "GeodeticDistanceResult.h"
#include "GeometryEngine.h"
#include "GeometryTypes.h"
#include "Graphic.h"
#include "GraphicListModel.h"
#include "GraphicsOverlay.h"
#include "GraphicsOverlayListModel.h"
#include "LinearUnit.h"
#include "Point.h"
#include "PolylineBuilder.h"
#include "SimpleFillSymbol.h"
#include "SimpleLineSymbol.h"
#include "SimpleMarkerSymbol.h"
#include "SpatialReference.h"
#include "SymbolTypes.h"
#include "IdentifyGraphicsOverlayResult.h"
#include "AttributeListModel.h"
#include "CoordinateFormatter.h"
#include "Geometry.h"
#include "EllipticArcSegment.h"
#include "PolygonBuilder.h"

#include <QFuture>
#include <QStandardPaths>
#include <QtMath>
#include <QDebug>
#include <QDir>
#include "IdentifyLayerResult.h"
#include "GeoElement.h"
#include "AttributeListModel.h"
#include <EncFeature.h>

#define MAXSCALE 6000000
using namespace Esri::ArcGISRuntime;

// ── Constructor ──────────────────────────────────────────────────────────────
Display_s57_chart::Display_s57_chart(QObject *parent)
    : QObject(parent)
    , m_map(new Map(this))
{
    QString appDir = QCoreApplication::applicationDirPath();
    QString resourcePath = QString(PROJECT_SOURCE_DIR) + "/ArcGIS_Maps_SDK_Qt_200.8.1/qt200.8.1/resources/hydrography";
    QString sencdataPath = QString(PROJECT_SOURCE_DIR) + "/senc_cache/";
    EncEnvironmentSettings::setResourcePath(resourcePath);
    EncEnvironmentSettings::setSencDataPath(sencdataPath);
}

Display_s57_chart::~Display_s57_chart() = default;

// ── MapView getter ───────────────────────────────────────────────────────────
MapQuickView* Display_s57_chart::mapView() const
{
    return m_mapView;
}

// ── SetMapView ───────────────────────────────────────────────────────────────
void Display_s57_chart::setMapView(MapQuickView* mapView)
{
    if (!mapView || mapView == m_mapView) return;
    m_mapView = mapView;
    m_mapView->setMap(m_map);

    initiateRuler();

    // Unified click handler
    connect(m_mapView, &MapQuickView::mousePressed, this,
            [this](QMouseEvent& mouse)
            {
                if (mouse.button() == Qt::RightButton)
                {
                    if (m_centerModeActive) {
                        deactivateChartCentering();
                        return;
                    }
                    if (m_selectedWatercraft)
                        emit showContextMenu();
                    return;
                }
                // 2. Left-click centers the chart if mode is active
                if (m_centerModeActive)
                {
                    Point clickedPoint = m_mapView->screenToLocation(mouse.position().x(), mouse.position().y());
                    m_mapView->setViewpointCenterAsync(clickedPoint);
                    return; // Remain in centering mode until right-clicked
                }
                if (m_placingWatercraft)
                    updatePlacingShip(mouse.position().x(), mouse.position().y());
                else if (m_replacingWatercraft || m_rotatingWatercraft)
                    confirmPlaceOrRotate(mouse.position().x(), mouse.position().y());
                else
                    trySelectWatercraft(mouse.position().x(), mouse.position().y());
            });

    emit mapViewChanged();

    // Load default chart if it exists
    const QString defaultPath = "D:/ENC_ROOT/LosAngelos/map3/ENC_ROOT/CATALOG.031";
    // const QString defaultPath = "D:/ENC_ROOT/CATALOG.031";
    QFileInfo fi(defaultPath);
    if (fi.exists())
        loadEncChart(defaultPath);
    m_mapView->setViewpointScaleAsync(MAXSCALE);
}

void Display_s57_chart::loadEncChart(const QString& catalogPath)
{
    if (!m_mapView) return;

    QString cleanPath = catalogPath;
    cleanPath.remove("file:///");
    cleanPath = QDir::toNativeSeparators(cleanPath);

    if (!QFileInfo(cleanPath).exists())
    {
        emit encLoadFailed("File not found: " + cleanPath);
        return;
    }

    // ── Disconnect and destroy old exchange set ───────────────────────────
    if (m_encExchangeSet)
    {
        disconnect(m_encExchangeSet, nullptr, this, nullptr);
        m_encExchangeSet->deleteLater();
        m_encExchangeSet = nullptr;
    }

    // ── Recreate the map completely — resets spatial reference lock ───────
    if (m_map)
    {
        m_map->deleteLater();
        m_map = nullptr;
    }
    m_map = new Map(this);
    m_mapView->setMap(m_map);  // ← reassign fresh map to view

    // ── Create new exchange set ───────────────────────────────────────────
    m_encExchangeSet = new EncExchangeSet({cleanPath}, this);

    connect(m_encExchangeSet, &EncExchangeSet::loadStatusChanged, this,
            [this](LoadStatus status)
            {
                if (status == LoadStatus::FailedToLoad)
                {
                    qWarning() << "ENC exchange set failed to load";
                    emit encLoadFailed("Failed to load ENC chart.");
                    return;
                }
                if (status != LoadStatus::Loaded) return;

                qInfo() << "ENC exchange set loaded —"
                        << m_encExchangeSet->datasets().size() << "datasets";

                for (EncDataset* dataset : m_encExchangeSet->datasets())
                {
                    EncCell* cell = new EncCell(dataset, this);
                    EncLayer* encLayer = new EncLayer(cell, this);

                    connect(encLayer, &EncLayer::loadStatusChanged, this,
                            [this, encLayer](LoadStatus layerStatus)
                            {
                                if (layerStatus == LoadStatus::FailedToLoad)
                                {
                                    qWarning() << "ENC layer failed to load";
                                    return;
                                }
                                if (layerStatus != LoadStatus::Loaded) return;

                                qInfo() << "ENC layer loaded — extent:"
                                        << encLayer->fullExtent().xMin()
                                        << encLayer->fullExtent().yMin()
                                        << encLayer->fullExtent().xMax()
                                        << encLayer->fullExtent().yMax();

                                m_map->operationalLayers()->append(encLayer);
                                m_mapView->setViewpointAsync(
                                    Viewpoint(encLayer->fullExtent()));
                                emit encLoadSuccess();
                            });

                    encLayer->load();
                }
            });

    m_encExchangeSet->load();
}
// ── ZoomIn/Out ────────────────────────────────────────────────────────
void Display_s57_chart::setMapScale(double scale)
{
    if (!m_mapView) return;
    // if(scale > MAXSCALE)
    //     m_mapView->setViewpointScaleAsync(MAXSCALE);
    else
        m_mapView->setViewpointScaleAsync(scale);
    emit mapScaleChanged();
}
double Display_s57_chart::currentMapScale() const
{
    if (!m_mapView) return 0.0;
    return m_mapView->mapScale();
}
// ── Ruler ────────────────────────────────────────────────────────────────────
void Display_s57_chart::initiateRuler()
{
    // ── Create ERBL overlay ───────────────────────────────────────────────
    m_erblOverlay = new GraphicsOverlay(this);
    m_mapView->graphicsOverlays()->append(m_erblOverlay);

    // ── Pre-create all ERBL graphics — hidden until needed ───────────────

    // Origin crosshair dot
    SimpleMarkerSymbol* originSym = new SimpleMarkerSymbol(
        SimpleMarkerSymbolStyle::Cross,
        QColor(255, 165, 0), 14, this);  // orange cross
    m_erblOriginDot = new Graphic(this);
    m_erblOriginDot->setSymbol(originSym);
    m_erblOriginDot->setVisible(false);
    m_erblOverlay->graphics()->append(m_erblOriginDot);

    // Bearing line
    SimpleLineSymbol* lineSym = new SimpleLineSymbol(
        SimpleLineSymbolStyle::Solid,
        QColor(255, 165, 0), 1.5f, this);  // orange line
    m_erblLine = new Graphic(this);
    m_erblLine->setSymbol(lineSym);
    m_erblLine->setVisible(false);
    m_erblOverlay->graphics()->append(m_erblLine);

    // End point dot
    SimpleMarkerSymbol* endSym = new SimpleMarkerSymbol(
        SimpleMarkerSymbolStyle::Circle,
        QColor(255, 165, 0), 8, this);
    m_erblEndDot = new Graphic(this);
    m_erblEndDot->setSymbol(endSym);
    m_erblEndDot->setVisible(false);
    m_erblOverlay->graphics()->append(m_erblEndDot);

    // Range ring — circle around origin
    SimpleLineSymbol* ringSym = new SimpleLineSymbol(
        SimpleLineSymbolStyle::Dash,
        QColor(255, 165, 0, 150), 4.0f, this);
    m_erblRangRing = new Graphic(this);
    m_erblRangRing->setSymbol(ringSym);
    m_erblRangRing->setVisible(false);
    m_erblOverlay->graphics()->append(m_erblRangRing);
    connect(m_mapView, &MapQuickView::mousePressed, this,
            [this](QMouseEvent& mouse)
            {
                if(mouse.button() == Qt::RightButton){
                    if (m_erblActive)
                        deactivateRuler();
                }
                if (m_erblActive){
                    setERBLOriginalPoint(mouse.position().x(), mouse.position().y());
                }
            });
}
void Display_s57_chart::setERBLOriginalPoint(double screenX, double screenY){
    if (!m_erblActive) return;
    if (!m_erblOriginSet)
    {
        // Set origin on first left click
        m_erblOrigin = m_mapView->screenToLocation(
            screenX, screenY);
        m_erblOriginSet = true;

        // Show origin crosshair
        m_erblOriginDot->setGeometry(m_erblOrigin);
        m_erblOriginDot->setVisible(true);
    }
    else
    {
        // Second click — fix the line, allow new origin
        // Reset for new measurement from current endpoint
        Point newOrigin = m_mapView->screenToLocation(
            screenX, screenY);
        m_erblOrigin    = newOrigin;
        m_erblOriginDot->setGeometry(m_erblOrigin);
    }

}
void Display_s57_chart::updateERBLLine(double screenX, double screenY)
{
    if (!m_erblActive || !m_erblOriginSet) return;
    Point cursorPoint = m_mapView->screenToLocation(screenX, screenY);

    // ── Calculate geodesic distance and bearing ───────────────────────────
    GeodeticDistanceResult result = GeometryEngine::distanceGeodetic(
        m_erblOrigin, cursorPoint,
        LinearUnit(LinearUnitId::Meters),
        AngularUnit(AngularUnitId::Degrees),
        GeodeticCurveType::Geodesic);

    double rangeMeters  = result.distance();
    double rangeNM      = rangeMeters / 1852.0;
    double bearingDeg   = result.azimuth1();
    if (bearingDeg < 0) bearingDeg += 360.0;

    // ── Update bearing line ───────────────────────────────────────────────
    PolylineBuilder lineBuilder(SpatialReference::wgs84());
    lineBuilder.addPoint(m_erblOrigin.x(), m_erblOrigin.y());
    lineBuilder.addPoint(cursorPoint.x(),  cursorPoint.y());
    m_erblLine->setGeometry(lineBuilder.toGeometry());
    m_erblLine->setVisible(true);

    // ── Update end dot ────────────────────────────────────────────────────
    m_erblEndDot->setGeometry(cursorPoint);
    m_erblEndDot->setVisible(true);

    // ── Update range ring — circle at range distance from origin ──────────
    // Approximate circle using 36 points
    PolygonBuilder ringBuilder(SpatialReference::wgs84());
    for (int deg = 0; deg <= 360; deg += 10)
    {
        QList<Point> moved = GeometryEngine::moveGeodetic(
            QList<Point>({m_erblOrigin}),
            rangeMeters,
            LinearUnit::meters(),
            (double)deg,
            AngularUnit::degrees(),
            GeodeticCurveType::Geodesic);

        if (!moved.isEmpty())
            ringBuilder.addPoint(moved.at(0).x(), moved.at(0).y());
    }

    // Use polyline for ring not polygon
    PolylineBuilder ringLineBuilder(SpatialReference::wgs84());
    for (int deg = 0; deg <= 360; deg += 10)
    {
        QList<Point> moved = GeometryEngine::moveGeodetic(
            QList<Point>({m_erblOrigin}),
            rangeMeters,
            LinearUnit::meters(),
            (double)deg,
            AngularUnit::degrees(),
            GeodeticCurveType::Geodesic);

        if (!moved.isEmpty())
            ringLineBuilder.addPoint(moved.at(0).x(), moved.at(0).y());
    }
    m_erblRangRing->setGeometry(ringLineBuilder.toGeometry());
    m_erblRangRing->setVisible(true);

    // ── Emit to QML for display ───────────────────────────────────────────
    emit erblUpdated(rangeNM, rangeMeters, bearingDeg);
}

void Display_s57_chart::clearERBLGraphics()
{
    if (m_erblOriginDot) m_erblOriginDot->setVisible(false);
    if (m_erblLine)      m_erblLine->setVisible(false);
    if (m_erblEndDot)    m_erblEndDot->setVisible(false);
    if (m_erblRangRing)  m_erblRangRing->setVisible(false);
    m_erblOriginSet = false;
    emit erblCleared();
}

void Display_s57_chart::activateRuler()
{
    m_erblActive    = true;
    m_erblOriginSet = false;
    clearERBLGraphics();
}

void Display_s57_chart::deactivateRuler()
{
    m_erblActive    = false;
    m_erblOriginSet = false;
    clearERBLGraphics();
}
bool Display_s57_chart::erblOriginSet() const
{
    return m_erblOriginSet;
}
bool Display_s57_chart::erblActive() const
{
    return m_erblActive;
}
// ── Status bar ────────────────────────────────────────────────────────
QPointF Display_s57_chart::screenToLocation(double x, double y) // Lon - Lat
{
    if (!m_mapView) return QPointF(0, 0);
    Point p = m_mapView->screenToLocation(x, y);
    return QPointF(p.x(), p.y());
}
QString Display_s57_chart::screenToEcdisCoordinate(double x, double y){
    QPointF p= screenToLocation(x,y);
    Point mapPoint(p.x(),p.y());
    Point absolutePoint(GeometryEngine::project(mapPoint, SpatialReference::wgs84()));
    QString ecdisCoords = CoordinateFormatter::toLatitudeLongitude(
        absolutePoint,
        LatitudeLongitudeFormat::DegreesDecimalMinutes,
        3
        );
    return ecdisCoords;
}
void Display_s57_chart::identifyDepthAtScreen(double screenX, double screenY)
{
    if (!m_mapView) return;

    m_mapView->identifyLayersAsync(QPointF(screenX, screenY), 10.0, false, 5)
        .then(this, [this](QList<IdentifyLayerResult*> results)
              {
                  double finalDepth = -9999.0;
                  int highestPriority = -1; // Track the best structural match found

                  for (IdentifyLayerResult* layerResult : results)
                  {
                      for (GeoElement* element : layerResult->geoElements())
                      {
                          // Safe cast to an ENC Feature to look at the S-57 object type
                          EncFeature* encFeature = dynamic_cast<EncFeature*>(element);
                          if (!encFeature) continue;

                          QString acronym = encFeature->acronym().toUpper();
                          AttributeListModel* attrs = encFeature->attributes();

                          // Priority 1: Precise Sounding Spot
                          if (acronym == "SOUNDG" && attrs->containsAttribute("VALSOU") && highestPriority < 3)
                          {
                              finalDepth = attrs->attributeValue("VALSOU").toDouble();
                              highestPriority = 3;
                          }
                          // Priority 2: Depth Contour Line
                          else if (acronym == "DEPCNT" && attrs->containsAttribute("VALDCO") && highestPriority < 2)
                          {
                              finalDepth = attrs->attributeValue("VALDCO").toDouble();
                              highestPriority = 2;
                          }
                          // Priority 3: Coarse Depth Area Polygon (Fallback)
                          else if (acronym == "DEPARE" && attrs->containsAttribute("DRVAL1") && highestPriority < 1)
                          {
                              // You can choose DRVAL1 (min depth) or compute an average
                              finalDepth = attrs->attributeValue("DRVAL1").toDouble();
                              highestPriority = 1;
                          }
                      }
                  }

                  // --- CRUCIAL: Clean up allocated memory to stop the leak ---
                  qDeleteAll(results);

                  // --- EMIT RESULT ---
                  if (highestPriority != -1 && finalDepth != -9999.0)
                  {
                      QString text = QString("%1 m").arg(finalDepth, 0, 'f', 1);
                      emit depthIdentified(text);
                  } else {
                      emit depthIdentified("---");
                  }
              });
}
// ── Place watercraft ──────────────────────────────────────────────────────────
void Display_s57_chart::startPlacingWatercraft(const QString& shipName,const QColor& color)
{
    if (!m_mapView) return;

    if (m_pendingWatercraft)
    {
        m_pendingWatercraft->deleteObject();
        delete m_pendingWatercraft;
        m_pendingWatercraft = nullptr;
    }

    if (!m_watercraftOverlay)
    {
        m_watercraftOverlay = new GraphicsOverlay(this);
        m_mapView->graphicsOverlays()->append(m_watercraftOverlay);
    }
    m_pendingWatercraft = new Watercraft(m_watercraftOverlay, this);
    m_pendingWatercraft->setName(shipName);
    m_pendingWatercraft->setColor(color);
    m_pendingWatercraft->showPreview(true);
    m_placingWatercraft = true;
    emit placingWatercraftChanged();
}
void Display_s57_chart::cancelPlacing()
{
    if (m_pendingWatercraft)
    {
        m_pendingWatercraft->deleteObject();
        delete m_pendingWatercraft;
        m_pendingWatercraft = nullptr;
    }
    m_placingWatercraft = false;
    emit placingWatercraftChanged();
}
void Display_s57_chart::updatePendingPreview(double screenX, double screenY)
{
    if (!m_pendingWatercraft || !m_placingWatercraft) return;
    QPointF geo = screenToLocation(screenX, screenY);
    m_pendingWatercraft->updatePreview(geo);
}
void Display_s57_chart::updatePlacingShip(double screenX, double screenY)
{
    if (!m_pendingWatercraft) return;
    QPointF geo = screenToLocation(screenX, screenY);
    m_pendingWatercraft->placeObject(geo);
    m_watercrafts.append(m_pendingWatercraft);
    m_pendingWatercraft = nullptr;
    m_placingWatercraft = false;
    emit placingWatercraftChanged();
}
// ── Select watercraft ─────────────────────────────────────────────────────────
void Display_s57_chart::trySelectWatercraft(double screenX, double screenY)
{
    if (!m_watercraftOverlay || !m_mapView) return;

    m_mapView->identifyGraphicsOverlayAsync(
                 m_watercraftOverlay,
                 QPointF(screenX, screenY),
                 10.0,
                 false,
                 1
                 ).then(this, [this](IdentifyGraphicsOverlayResult* result)
              {
                  deselectAllWatercrafts();
                  m_selectedWatercraft = nullptr;
                  emit selectedWatercraftChanged();

                  if (!result) return;
                  const QList<Graphic*>& graphics = result->graphics();
                  if (graphics.isEmpty()) return;

                  Graphic* clicked = graphics.first();
                  int clickedId = clicked->attributes()->attributeValue("id").toInt();

                  for (Watercraft* const wc : std::as_const(m_watercrafts))
                  {
                      if (wc->id() == clickedId)
                      {
                          wc->setWatercraftSelected(true);
                          m_selectedWatercraft = wc;
                          emit selectedWatercraftChanged();
                          qInfo() << "Selected:" << wc->name();
                          break;
                      }
                  }
              });
}
void Display_s57_chart::deselectAllWatercrafts()
{
    for (Watercraft* const wc : std::as_const(m_watercrafts))
        wc->setWatercraftSelected(false);
}
// ── PrimaryShip ──────────────────────────────────────────────────────────────────────
void Display_s57_chart::makeMainShip(QString watercraftName)
{
    for(Watercraft* ship: std::as_const(m_watercrafts)){
        if(ship->name() == watercraftName){
            setPrimaryShip(ship);
            break;
        }
    }
    if(!m_trailerOverlayContour)
    {
        m_trailerOverlayContour = new GraphicsOverlay(this);
        m_mapView->graphicsOverlays()->insert(0,m_trailerOverlayContour);
    }
    if(!m_trailerOverlayDashDotted)
    {
        m_trailerOverlayDashDotted = new GraphicsOverlay(this);
        m_mapView->graphicsOverlays()->insert(0,m_trailerOverlayDashDotted);
    }
    if (!m_trendOverlay)
    {
        m_trendOverlay = new GraphicsOverlay(this);
        m_mapView->graphicsOverlays()->append(m_trendOverlay);
    }
    if (m_trend)
    {
        delete m_trend; // Wipe any old, stale configurations out of RAM
    }
    if (m_shipTracker) {
        delete m_shipTracker;
    }
    m_shipTracker = new Track(m_trailerOverlayDashDotted,m_trailerOverlayContour,m_primaryShip,m_mapView);
    m_trend = new ContourTrendOption(m_primaryShip, 2, 5, QColor(255, 255, 255, 120));
    m_trend->initialize(m_trendOverlay);
    m_trend->setEnabled(true);
}
Watercraft *Display_s57_chart::primaryShip() const
{
    return m_primaryShip;
}
void Display_s57_chart::setPrimaryShip(Watercraft *newPrimaryShip)
{
    if (m_primaryShip == newPrimaryShip)
        return;
    m_primaryShip = newPrimaryShip;
    emit primaryShipChanged();
}
// ── Move ──────────────────────────────────────────────────────────────────────
void Display_s57_chart::movingWatercraft(double x, double y, double heading,double surge)
{
    qDebug().nospace() << "Lon: " << qSetRealNumberPrecision(10) << x
                       << " Lat: " << qSetRealNumberPrecision(10) << y;
    // --- ADD THIS SAFETY GUARD ---
    if (!m_mapView || !m_primaryShip) return;

    const double dT = 0.1;
    const double metersPerDegree = 111320.0;

    QPointF current = m_primaryShip->startingPosition();
    double cosLat = qCos(qDegreesToRadians(current.y()));
    double newLat = current.y() + (x / metersPerDegree);
    double newLon = current.x() + (y / (metersPerDegree * cosLat));

    // ← convert once here

    m_primaryShip->moveObject(QPointF(newLon, newLat));
    m_primaryShip->rotateObject(QPointF(heading, 0));
    if (m_shipTracker) {
        // You will want to expose a public update position method inside your Track class
        // to handle the incoming tick offsets cleanly:
        m_shipTracker->updateTrackPosition(QPointF(newLon, newLat), heading);
    }
    if (m_trend){
        QPointF shipTipPos = m_primaryShip->getOffsetPoint(QPointF(newLon, newLat), heading, 75.0, 0.0);

        // 2. Pass the tip position as the calculation root instead of the center
        m_trend->update(shipTipPos, heading, surge);
    }

    emit primaryShipChanged();
}
// ── Trailer ──────────────────────────────────────────────────────────────────────
void Display_s57_chart::setPlotting(int newPlottingPeriodSeconds,int newPlottingDurationMinutes,QColor color)
{
    if (!m_mapView || !m_primaryShip) return;
    m_shipTracker->setPlotting(qBound(1, newPlottingPeriodSeconds, 240),qBound(1, newPlottingDurationMinutes, 120),color);
    // m_shipTracker->recalculateTrailSettings();
    emit trailSettingsChanged();
}

void Display_s57_chart::setTrack(int newTrackPeriodSeconds,int newTrackDurationMinutes,QColor color)
{
    if (!m_mapView || !m_primaryShip) return;
    m_shipTracker->setTrack(qBound(1, newTrackPeriodSeconds, 240),qBound(1, newTrackDurationMinutes, 120),color);
    emit trailSettingsChanged();
}
void Display_s57_chart::setTimeStampDurationMinutes(double newTimeStampDurationMinutes){
    if (!m_mapView || !m_primaryShip) return;
    m_shipTracker->setTimeStampDurationMinutes(newTimeStampDurationMinutes);
}
void Display_s57_chart:: setVisibiltyPlot(bool vis){
    m_trailerOverlayDashDotted->setVisible(vis);
    qInfo() << "visible: " << vis;
    emit trailSettingsChanged();
}
void Display_s57_chart:: setVisibiltyTrack(bool vis){
    m_trailerOverlayContour->setVisible(vis);
    emit trailSettingsChanged();
}
// ── Trend ──────────────────────────────────────────────────────────────────────
void Display_s57_chart::setVisibiltyTrend(bool vis){
    m_trend->setVisibilty(vis);
    emit trailSettingsChanged();
}
void Display_s57_chart::setTrend(int steps,int minutes,QColor color)
{
    if (!m_mapView || !m_primaryShip) return;
    if (m_trend)
    {
        delete m_trend; // Wipe any old, stale configurations out of RAM
    }
    m_trendOverlay->graphics()->clear();
    m_trend = new ContourTrendOption(m_primaryShip, 2, 5, color);
    m_trend->setMinutes(minutes);
    m_trend->setSteps(steps);
    m_trend->initialize(m_trendOverlay);
}

void Display_s57_chart::setTrendMinutes(int minutes)
{
    if (m_trend) m_trend->setMinutes(minutes);
    emit trendChanged();
}

void Display_s57_chart::setTrendSteps(int steps)
{
    if (m_trend) m_trend->setSteps(steps);
    emit trendChanged();
}

// ── Replace ──────────────────────────────────────────────────────────────────────
void Display_s57_chart::startReplacingWatercraft()
{
    if (!m_selectedWatercraft) return;
    m_replacingWatercraft = true;
    m_selectedWatercraft->showPreview(true);
    emit replacingWatercraftChanged();
}

// ── Rotate ────────────────────────────────────────────────────────────────────
void Display_s57_chart::startRotatingWatercraft()
{
    if (!m_selectedWatercraft) return;
    m_rotationAnchor = m_selectedWatercraft->startingPosition();
    m_rotatingWatercraft = true;
    emit rotatingWatercraftChanged();
}

// ── Update move / rotate on mouse move ───────────────────────────────────────
void Display_s57_chart::updateReplacingOrRotating(double screenX, double screenY)
{
    QPointF geo = screenToLocation(screenX, screenY);

    if (m_replacingWatercraft && m_selectedWatercraft)
    {
        m_selectedWatercraft->updatePreview(geo);
    }
    else if (m_rotatingWatercraft && m_selectedWatercraft)
    {
        double dx = geo.x() - m_rotationAnchor.x();
        double dy = geo.y() - m_rotationAnchor.y();

        // Angle from north clockwise (nautical heading)
        double headingRad = qAtan2(dx, dy);
        double headingDeg = qRadiansToDegrees(headingRad);
        if (headingDeg < 0) headingDeg += 360.0;

        m_selectedWatercraft->rotateObject(QPointF(headingDeg, 0));
    }
}

// ── Confirm move / rotate on click ───────────────────────────────────────────
void Display_s57_chart::confirmPlaceOrRotate(double screenX, double screenY)
{
    QPointF geo = screenToLocation(screenX, screenY);

    if (m_replacingWatercraft && m_selectedWatercraft)
    {
        m_selectedWatercraft->placeObject(geo);
        m_selectedWatercraft->showPreview(false);
        m_replacingWatercraft = false;
        emit replacingWatercraftChanged();
    }
    else if (m_rotatingWatercraft && m_selectedWatercraft)
    {
        m_rotatingWatercraft = false;
        emit rotatingWatercraftChanged();
    }
}

// ── Info ──────────────────────────────────────────────────────────────────────
void Display_s57_chart::selectedWatercraftInfo()
{
    if (!m_selectedWatercraft) return;

    m_selectedWatercraft->objectInformation();

    QString info = QString("Name:   %1\nID:     %2\nSpeed:  %3 kn\nCourse: %4°\nLon:    %5\nLat:    %6")
                       .arg(m_selectedWatercraft->name())
                       .arg(m_selectedWatercraft->id())
                       .arg(m_selectedWatercraft->speed(), 0, 'f', 1)
                       .arg(m_selectedWatercraft->course(), 0, 'f', 1)
                       .arg(m_selectedWatercraft->getCurrentLocation().x(), 0, 'f', 6)
                       .arg(m_selectedWatercraft->getCurrentLocation().y(), 0, 'f', 6);

    emit watercraftInfoReady(info);
}
// ── Camera ──────────────────────────────────────────────────────────────────────
bool Display_s57_chart::cameraLock() const
{
    return m_cameraLock;
}
void Display_s57_chart::setCameraLock(bool newCameraLock)
{
    m_cameraLock = newCameraLock;
}
void Display_s57_chart::lockCamera()
{
    if(!m_primaryShip)
        return;
    m_mapView->setViewpointAsync(Viewpoint(Point(m_primaryShip->getCurrentLocation().x(),m_primaryShip->getCurrentLocation().y()), 5000.0));
}

// ── Zoom Area Implementation ──────────────────────────────────────────────
void Display_s57_chart::activateZoomArea()
{
    m_zoomAreaActive = true;

    // Lazy initialize the drawing overlay the first time the tool is clicked
    if (!m_zoomOverlay && m_mapView) {
        m_zoomOverlay = new GraphicsOverlay(this);
        m_mapView->graphicsOverlays()->append(m_zoomOverlay);

        // Create a semi-transparent blue box with a solid blue border
        SimpleLineSymbol* lineSymbol = new SimpleLineSymbol(SimpleLineSymbolStyle::Solid, QColor(Qt::blue), 2.0f, this);
        SimpleFillSymbol* fillSymbol = new SimpleFillSymbol(SimpleFillSymbolStyle::Solid, QColor(0, 0, 255, 50), lineSymbol, this);

        m_zoomGraphic = new Graphic(this);
        m_zoomGraphic->setSymbol(fillSymbol);
        m_zoomOverlay->graphics()->append(m_zoomGraphic);
    }

    if (m_zoomGraphic) {
        m_zoomGraphic->setVisible(true);
    }
}

void Display_s57_chart::deactivateZoomArea()
{
    m_zoomAreaActive = false;

    // Hide and clear the box when the tool is disabled
    if (m_zoomGraphic) {
        m_zoomGraphic->setGeometry(Geometry());
        m_zoomGraphic->setVisible(false);
    }
}

// Triggered when the user clicks down
// Triggered when the user clicks down
void Display_s57_chart::startZoomBox(double screenX, double screenY)
{
    if (!m_zoomAreaActive || !m_mapView) return;

    m_zoomStartPoint = m_mapView->screenToLocation(screenX, screenY);
}

// Triggered when the user drags the mouse
void Display_s57_chart::updateZoomBox(double screenX, double screenY)
{
    if (!m_zoomAreaActive || !m_mapView || m_zoomStartPoint.isEmpty()) return;

    Point currentPoint = m_mapView->screenToLocation(screenX, screenY);
    Envelope env(m_zoomStartPoint, currentPoint);

    // Safeguard: Ensure geometry envelope contains valid data before changing visual graphics
    if (!env.isEmpty()) {
        m_zoomGraphic->setGeometry(env);
    }
}

// Triggered when the user lets go of the mouse
void Display_s57_chart::finishZoomBox(double screenX, double screenY)
{
    if (!m_zoomAreaActive || !m_mapView || m_zoomStartPoint.isEmpty()) return;

    Point currentPoint = m_mapView->screenToLocation(screenX, screenY);
    Envelope env(m_zoomStartPoint, currentPoint);

    // CRITICAL CRASH FIX: Guard against single-clicks or micro-drags.
    // If the envelope width or height is negligible, cancel the operation instead of crashing.
    if (env.isEmpty() || env.width() <= 0.0001 || env.height() <= 0.0001) {
        if (m_zoomGraphic) m_zoomGraphic->setGeometry(Geometry());
        m_zoomStartPoint = Point();
        return;
    }

    // Apply the zoom safely now that envelope boundaries are verified
    m_mapView->setViewpointGeometryAsync(env, 50);

    // Clear the visual graphic and reset the starting point
    if (m_zoomGraphic) m_zoomGraphic->setGeometry(Geometry());
    m_zoomStartPoint = Point();
}

// ── Chart Centering ────────────────────────────────────────────────────────
void Display_s57_chart::activateChartCentering()
{
    m_centerModeActive = true;
    // You can emit a signal here if you want to change the QML cursor to the crosshair icon
    qInfo() << "Chart Centering Activated";
}

void Display_s57_chart::deactivateChartCentering()
{
    m_centerModeActive = false;
    qInfo() << "Chart Centering Deactivated";
}

void Display_s57_chart::panMapCenter(int dx, int dy)
{
    if (!m_mapView) return;

    // Get the current center of the screen
    double centerX = m_mapView->width() / 2.0;
    double centerY = m_mapView->height() / 2.0;

    // Shift by a fixed pixel amount (which naturally scales geodetically with the current zoom level)
    // 50 pixels is a smooth increment. Adjust if you want faster/slower panning.
    double shiftPixels = 50.0;

    // Calculate new screen coordinates
    double newScreenX = centerX + (dx * shiftPixels);
    double newScreenY = centerY + (dy * shiftPixels);

    // Convert the new shifted screen coordinate to map geometry and center it
    Point newCenter = m_mapView->screenToLocation(newScreenX, newScreenY);
    m_mapView->setViewpointCenterAsync(newCenter);
}
