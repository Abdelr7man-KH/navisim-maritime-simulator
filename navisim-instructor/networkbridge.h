#ifndef NETWORKBRIDGE_H
#define NETWORKBRIDGE_H

#include <QObject>
#include <QUdpSocket>
#include <QNetworkDatagram>
#include <QJsonDocument>
#include <QJsonObject>
class NetworkBridge : public QObject {
    Q_OBJECT
    // Properties the Instructor UI will "bind" to
    Q_PROPERTY(double shipX READ shipX NOTIFY positionChanged)
    Q_PROPERTY(double shipY READ shipY NOTIFY positionChanged)
    Q_PROPERTY(double shipHeading READ shipHeading NOTIFY positionChanged)
    Q_PROPERTY(double shipSpeed READ shipSpeed NOTIFY positionChanged)
    Q_PROPERTY(double recievedLatency READ recievedLatency NOTIFY positionChanged)
public:
    explicit NetworkBridge(QObject *parent = nullptr);


    Q_INVOKABLE void sendSessionCommand(int state);
    Q_INVOKABLE void send();
    Q_INVOKABLE void sendControlCommand(QString state);
    Q_INVOKABLE void sendScenarioCommand(QString state,QString filename);
    Q_INVOKABLE void publishEnvironment(QString state,const QVariantMap& envData);
    double shipX() const { return m_x; }
    double shipY() const { return m_y; }
    double shipHeading() const { return m_heading; }
    double shipSpeed() const { return m_speed; }
    double recievedLatency() const {return m_latency;}

signals:
    void positionChanged();

private slots:
    void processDatagrams();

private:
    QUdpSocket *m_udpSocket;
    // The port MUST match the INSTRUCTOR_PORT in your Python Broker (e.g., 9000)
    quint16 m_listenPort = 9000;

    double m_x = 0, m_y = 0, m_heading = 0, m_speed = 0, m_latency = 0;
};
#endif
