#ifndef ENVIRONMENTCONTROLLER_H
#define ENVIRONMENTCONTROLLER_H



#pragma once

#include <QObject>
#include <QJsonObject>
#include <QVariantMap>
#include <QJsonDocument>
#include <QQmlEngine>
#include <QDebug>
#include <QDateTime>

class EnvironmentController : public QObject
{
    Q_OBJECT
    QML_ELEMENT      // Exposes this class to QML automatically
    QML_SINGLETON    // Makes it a global singleton in QML


public:
    explicit EnvironmentController(QObject *parent = nullptr);

    // Q_INVOKABLE makes this callable directly from your QML button
    //Q_INVOKABLE void publishEnvironment(const QJsonObject& envData);
    Q_INVOKABLE void publishEnvironment(const QVariantMap& envData);
};
#endif // ENVIRONMENTCONTROLLER_H
