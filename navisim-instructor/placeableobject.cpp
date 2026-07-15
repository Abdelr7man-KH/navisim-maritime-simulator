#include "placeableobject.h"

PlaceableObject::PlaceableObject(QObject *parent)
    : QObject{parent}
{
    m_id = s_nextID++;
    m_name = QString("Object %1").arg(m_id);

}
int PlaceableObject::s_nextID = 0;

int PlaceableObject::id() const
{
    return m_id;
}

QPointF PlaceableObject::getCurrentLocation() const
{
    return m_currentLocation;
}

void PlaceableObject::setCurrentLocation(QPointF location)
{
    m_currentLocation = location;
}

QString PlaceableObject::name() const
{
    return m_name;
}

void PlaceableObject::setName(const QString &newName)
{
    m_name = newName;
}

QPointF PlaceableObject::startingPosition() const
{
    return m_startingPosition;
}

void PlaceableObject::setStartingPosition(QPointF newStartingPosition)
{
    m_startingPosition = newStartingPosition;
}

