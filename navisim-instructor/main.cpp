// Copyright 2026 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the Sample code usage restrictions document for further information.
//

#include "Display_s57_chart.h"
#include "EnvironmentController.h"
#include "ArcGISRuntimeEnvironment.h"
#include "MapQuickView.h"
#include "networkbridge.h"
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
//------------------------------------------------------------------------------

using namespace Esri::ArcGISRuntime;

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    QGuiApplication app(argc, argv);
    NetworkBridge* bridge = new NetworkBridge(&app);


    ArcGISRuntimeEnvironment::setUseLegacyAuthentication(false);
    // EncEnvironmentSettings::setResourcePath("D:/ArcGIS_Maps_SDK_Qt_200.8.1/qt200.8.1/resources/hydrography/ENC/");
    // EncEnvironmentSettings::setSencDataPath("D:/Projects/Qt_Projects/display_s57_chart/senc_cache/");
    // Use of ArcGIS location services, such as basemap styles, geocoding, and routing services,
    // requires an access token. For more information see
    // https://links.esri.com/arcgis-runtime-security-auth.

    // The following methods grant an access token:

    // 1. User authentication: Grants a temporary access token associated with a user's ArcGIS account.
    // To generate a token, a user logs in to the app with an ArcGIS account that is part of an
    // organization in ArcGIS Online or ArcGIS Enterprise.

    // 2. API key authentication: Get a long-lived access token that gives your application access to
    // ArcGIS location services. Go to the tutorial at https://links.esri.com/create-an-api-key.
    // Copy the API Key access token.

    const QString accessToken = QString("AAPTaVu_4QFsThDx3lk31I49HUg..q8C13Z6PwLMIRxoayAEq1nFoVAHqr9wnkwceesTRGRkKPocBkzFErzBj9EcA8h1u5OaQUjCGMGbQruKxTO6bR6hYA3ss4gHpWsAuWne-ANjbxSk2mTZ--rfmpCBFIbBr3Cgl5E4ku-PIsHJ-gu9gRq4vC-XJgTjXeK5RBF1r1ywcytGEFt6eNtjECLLPY2IT92rARTkhh0NJJiytH2F2H07eQUziGVbBJW6VJO3cPGxg2xvtrsC_FpMn0Lx5AT1_BfUH7kzv");

    if (accessToken.isEmpty()) {
        qWarning()
            << "Use of ArcGIS location services, such as the basemap styles service, requires"
            << "you to authenticate with an ArcGIS account or set the API Key property.";
    } else {
        ArcGISRuntimeEnvironment::setApiKey(accessToken);
    }

    // Production deployment of applications built with ArcGIS Maps SDK requires you to
    // license ArcGIS Maps SDK functionality. For more information see
    // https://links.esri.com/arcgis-runtime-license-and-deploy.

    // ArcGISRuntimeEnvironment::setLicense("Place license string in here");

    // Register the map view for QML
    qmlRegisterType<MapQuickView>("Esri.display_s57_chart", 1, 0, "MapView");

    // Register the Display_s57_chart (QQuickItem) for QML
    qmlRegisterType<Display_s57_chart>("Esri.display_s57_chart", 1, 0, "Display_s57_chart");
    qmlRegisterUncreatableType<Watercraft>("PlaceableObjects.Watercraft", 1, 0, "Watercraft", "Interface only");
    qmlRegisterUncreatableType<NetworkBridge>("NetworkBridge.UDP", 1, 0, "NetworkBridge", "Interface only");

    //qmlRegisterType<EnvironmentController>("Esri.display_s57_chart", 1, 0, "EnvironmentController");

    // Initialize application view
    QQmlApplicationEngine engine;
    EnvironmentController* envController = new EnvironmentController(&app);
    // Add the import Path
    engine.addImportPath(QDir(QCoreApplication::applicationDirPath()).filePath("qml"));
    engine.rootContext()->setContextProperty("physicsBridge", bridge);
    engine.rootContext()->setContextProperty("EnvironmentController", envController);

    // Set the source
    engine.load(QUrl("qrc:/qml/main.qml"));

    return app.exec();
}

//------------------------------------------------------------------------------
