#include "networkBridge.h"
#include <QDebug>


NetworkBridge::NetworkBridge(QObject *parent) : QObject(parent) {
    m_udpSocket = new QUdpSocket(this);

    // Bind to the specific port the Broker is sending to
    // If testing on one PC, use QHostAddress::LocalHost
    m_udpSocket->bind(QHostAddress::Any, m_listenPort);

    connect(m_udpSocket, &QUdpSocket::readyRead, this, &NetworkBridge::processDatagrams);
}

void NetworkBridge::processDatagrams() {
    while (m_udpSocket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpSocket->receiveDatagram();
        QJsonDocument doc = QJsonDocument::fromJson(datagram.data());
        QJsonObject res = doc.object();

        // Update internal variables based on the JSON keys in your Python Broker
        m_x = res["x"].toDouble();
        m_y = res["y"].toDouble();
        m_heading = res["heading"].toDouble();
        m_speed = res["surge"].toDouble(); // Surge = forward speed
        qint64 sentTime = res["sent_time"].toVariant().toLongLong();
        qint64 receiveTime = QDateTime::currentMSecsSinceEpoch();
        m_latency = receiveTime - sentTime;
        // Notify QML that new data has arrived
        emit positionChanged();
    }
}

void NetworkBridge::sendSessionCommand(int state) {
    // 1. Create the JSON message
    QJsonObject obj;
    obj["command"] = "session_control"; // Helps the broker know what this is
    QJsonDocument doc(obj);
    QByteArray data = doc.toJson(QJsonDocument::Compact);

    // 2. Send it via UDP
    // Replace "127.0.0.1" with the Broker's IP if it's on a different PC
    // Replace 9001 with the port your Broker listens to for COMMANDS
    m_udpSocket->writeDatagram(data, QHostAddress::LocalHost, 9001);

    qDebug() << "Sent session command:" << state << "to Broker on port 9001";
}

void NetworkBridge::sendControlCommand(QString state) {
    // 1. Create the JSON message
    QJsonObject obj;
    obj["command"] = state; // Helps the broker know what this is
    QJsonDocument doc(obj);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    m_udpSocket->writeDatagram(data, QHostAddress::LocalHost, 5556);
    qDebug() << "Sent session command:" << state << "to Broker on port 5556";
}
void NetworkBridge::sendScenarioCommand(QString state,QString filename) {
    // 1. Create the JSON message
    QJsonObject obj;
    obj["command"] = state; // Helps the broker know what this is
    obj["filename"] = filename;
    QJsonDocument doc(obj);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    m_udpSocket->writeDatagram(data, QHostAddress::LocalHost, 5556);
    qDebug() << "Sent session command:" << state << "to Broker on port 5556";
}
void NetworkBridge::publishEnvironment(QString state,const QVariantMap& envData)
{
    // 1. Convert the Map (from QML/JS) to a JsonObject
    QJsonObject dataObject = QJsonObject::fromVariantMap(envData);

    // 2. Wrap the data in a standardized message envelope
    QJsonObject payload;
    payload["command"] = state;
    payload["data"] = dataObject;
    // 3. Convert to a JSON string
    QJsonDocument doc(payload);
    QByteArray data = doc.toJson(QJsonDocument::Compact); // Use QJsonDocument::Indented for debugging
    m_udpSocket->writeDatagram(data, QHostAddress::LocalHost, 5556);
    qDebug().noquote() << "Sending to Message Broker:\n" << doc.toJson(QJsonDocument::Indented);
    // TODO: Connect your actual message broker here (MQTT, ZeroMQ, WebSockets, etc.)
    // example: m_mqttClient->publish(QString("simulator/instructor/environment"), jsonBytes);

}
void NetworkBridge::send()
{
    QJsonObject obj;
    obj["command"] = "Test";
    QJsonDocument doc(obj);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    m_udpSocket->writeDatagram(data,QHostAddress::LocalHost,9000);
    qDebug() << "Sent session command:"<< "to Broker on port 9000";
}
