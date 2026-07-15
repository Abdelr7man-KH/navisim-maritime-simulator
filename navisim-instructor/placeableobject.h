#ifndef PLACEABLEOBJECT_H
#define PLACEABLEOBJECT_H

#include <QObject>
#include <QPointF>
#include <QColor>

class PlaceableObject : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged FINAL)
    Q_PROPERTY(int id READ id CONSTANT)
    Q_PROPERTY(QPointF currentLocation READ getCurrentLocation WRITE setCurrentLocation NOTIFY locationChanged FINAL)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged FINAL)
    Q_PROPERTY(QPointF startingPosition READ startingPosition WRITE setStartingPosition NOTIFY startingPositionChanged FINAL)
public:
    explicit PlaceableObject(QObject *parent = nullptr);
    virtual ~PlaceableObject() = default;
    int id() const;
    QPointF getCurrentLocation() const;
    void setCurrentLocation(QPointF location);

    virtual void placeObject(QPointF location) = 0;
    virtual void moveObject(QPointF location) = 0;
    virtual void rotateObject(QPointF angle) = 0;
    virtual void deleteObject() = 0;
    virtual void objectInformation() const = 0;


    QString name() const;
    void setName(const QString &newName);

    QColor color() const { return m_color; }
    void setColor(const QColor &newColor) {
        if (m_color == newColor) return;
        m_color = newColor;
        emit colorChanged();
    }

    QPointF startingPosition() const;
    void setStartingPosition(QPointF newStartingPosition);

signals:
    void locationChanged();
    void objectHasMoved(QPointF newLocation);
    void objectRemoved();
    void nameChanged();
    void colorChanged();
    void startingPositionChanged();
private:
    QString m_name;
    int m_id;
    static int s_nextID;
    QPointF m_currentLocation;
    QPointF m_startingPosition;
    QColor m_color;

};

#endif // PLACEABLEOBJECT_H
