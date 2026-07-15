#include "EnvironmentController.h"

EnvironmentController::EnvironmentController(QObject *parent)
    : QObject(parent)
{
}

void EnvironmentController::publishEnvironment(const QVariantMap& envData)
{
    // 1. Convert the Map (from QML/JS) to a JsonObject
    QJsonObject dataObject = QJsonObject::fromVariantMap(envData);

    // 2. Wrap the data in a standardized message envelope
    QJsonObject payload;
    payload["event"] = "update_environment";
    payload["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    payload["data"] = dataObject;

    // 3. Convert to a JSON string
    QJsonDocument doc(payload);
    QByteArray jsonBytes = doc.toJson(QJsonDocument::Compact); // Use QJsonDocument::Indented for debugging

    qDebug().noquote() << "Sending to Message Broker:\n" << doc.toJson(QJsonDocument::Indented);
    // TODO: Connect your actual message broker here (MQTT, ZeroMQ, WebSockets, etc.)
    // example: m_mqttClient->publish(QString("simulator/instructor/environment"), jsonBytes);

}
