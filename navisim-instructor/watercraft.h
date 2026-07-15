#ifndef WATERCRAFT_H
#define WATERCRAFT_H

#include "placeableobject.h"
#include "Graphic.h"
#include "GraphicsOverlay.h"
#include <QColor>

namespace Esri::ArcGISRuntime {
class Graphic;
class GraphicsOverlay;
}

class Watercraft : public PlaceableObject
{
    Q_OBJECT
    Q_PROPERTY(float speed READ speed WRITE setSpeed NOTIFY speedChanged FINAL)
    Q_PROPERTY(float course READ course WRITE setCourse NOTIFY courseChanged FINAL)
    Q_PROPERTY(bool watercraftSelected READ watercraftSelected WRITE setWatercraftSelected NOTIFY watercraftSelectedChanged FINAL)
    Q_PROPERTY(int trailerOption READ trailerOption WRITE setTrailerOption NOTIFY trailerChanged FINAL)
    Q_PROPERTY(QColor trailerColor READ trailerColor WRITE setTrailerColor NOTIFY trailerChanged FINAL)
public:
    explicit Watercraft(Esri::ArcGISRuntime::GraphicsOverlay* overlay,QObject *parent = nullptr);
    float speed() const;
    void setSpeed(float newSpeed);

    float course() const;
    void setCourse(float newCourse);

    void updatePreview(QPointF location);
    void showPreview(bool visible);

    QColor color() const;
    void setColor(QColor newColor);
signals:
    void speedChanged(float speed);
    void courseChanged(float course);
    void watercraftSelectedChanged(bool watercraftSelected);
    void trailerChanged();
public:
    // PlaceableObject interface
    Q_INVOKABLE void placeObject(QPointF location);
    Q_INVOKABLE void moveObject(QPointF location);
    Q_INVOKABLE void rotateObject(QPointF angle);
    Q_INVOKABLE void deleteObject();
    Q_INVOKABLE void objectInformation() const;

    bool watercraftSelected() const;
    void setWatercraftSelected(bool newWatercraftSelected);


    // ── Trailer options ────────────────────────────────────────────────────────────
    QColor trailerColor() const;
    void setTrailerColor(const QColor &newtrailerColor);

    int trailerOption() const;
    void setTrailerOption(int newTrailerOption);

    // ── Ship Hull ────────────────────────────────────────────────────────────
    QList<QPointF> getHullPoints() const { return kvlcc2HullPoints(); }
    QPointF getOffsetPoint(QPointF center, float heading,
                           float fwd, float lat) const {
        return offsetPoint(center, heading, fwd, lat);
    }
private:
    float m_speed = 0.0f;
    float m_course = 0.0f;
    QColor m_color = QColor(50, 222, 218);
    bool m_watercraftSelected;
    QList<QPointF> kvlcc2HullPoints() const;
    QPointF offsetPoint(QPointF center, float headingDeg,
                        float forwardMeters, float lateralMeters) const;
    void buildHullGraphic(QPointF location, float headingDeg,
                          Esri::ArcGISRuntime::Graphic* target);

    Esri::ArcGISRuntime::GraphicsOverlay* m_overlay  = nullptr;
    Esri::ArcGISRuntime::Graphic*         m_graphic  = nullptr;  // placed ship
    Esri::ArcGISRuntime::Graphic*         m_preview  = nullptr;  // mouse preview

    // ── Trailer ────────────────────────────────────────────────────────────
    int m_trailerOption = 3;  /* 1:dotted 2:dash-dot 3:contour */
    QColor m_trailerColor;

    //TODO: PROPERTIES OF THE SHIP

};

#endif // WATERCRAFT_H
