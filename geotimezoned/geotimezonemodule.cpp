/*
 * SPDX-FileCopyrightText: 2023 Kai Uwe Broulik <ghqalpha@broulik.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "geotimezonemodule.h"

#include <KPluginFactory>

#include <QDBusPendingCallWatcher>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QScopedPointer>
#include <QStandardPaths>

#include <NetworkManagerQt/ActiveConnection>
#include <NetworkManagerQt/Manager>

#include <chrono>

#include "geotimezoned_debug.h"
#include "timedated_interface.h"

K_PLUGIN_CLASS_WITH_JSON(KdedGeoTimeZonePlugin, "geotimezoned.json")

// TODO use our own endpoint.
static const QUrl s_geoIpEndpoint{QStringLiteral("https://geoip.kde.org/v1/calamares")};

static constexpr QLatin1String s_timedateService{"org.freedesktop.timedate1"};
static constexpr QLatin1String s_timedatePath{"/org/freedesktop/timedate1"};

KdedGeoTimeZonePlugin::KdedGeoTimeZonePlugin(QObject *parent, const QVariantList &args)
    : KDEDModule(parent)
{
    Q_UNUSED(args);

    m_nam.setRedirectPolicy(QNetworkRequest::NoLessSafeRedirectPolicy);
    m_nam.setStrictTransportSecurityEnabled(true);
    m_nam.enableStrictTransportSecurityStore(true, QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QLatin1String("/kded/hsts/"));

    connect(NetworkManager::notifier(), &NetworkManager::Notifier::connectivityChanged, this, &KdedGeoTimeZonePlugin::checkTimeZone);
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::meteredChanged, this, &KdedGeoTimeZonePlugin::checkTimeZone);
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::primaryConnectionChanged, this, &KdedGeoTimeZonePlugin::checkTimeZone);

    checkTimeZone();
}

bool KdedGeoTimeZonePlugin::shouldCheckTimeZone() const
{
    using namespace std::chrono_literals;
    if (m_timer.isValid() && std::chrono::milliseconds{m_timer.elapsed()} < 1h) {
        return false;
    }

    const auto connectivity = NetworkManager::connectivity();
    if (connectivity == NetworkManager::Connectivity::NoConnectivity || connectivity == NetworkManager::Connectivity::Portal
        || connectivity == NetworkManager::Connectivity::Limited) {
        return false;
    }

    const auto metered = NetworkManager::metered();
    if (metered == NetworkManager::Device::MeteredStatus::Yes || metered == NetworkManager::Device::MeteredStatus::GuessYes) {
        return false;
    }

    const auto connection = NetworkManager::primaryConnection();
    return connection && !connection->vpn();
}

void KdedGeoTimeZonePlugin::checkTimeZone()
{
    if (!shouldCheckTimeZone()) {
        return;
    }

    QNetworkRequest request(s_geoIpEndpoint);
    request.setPriority(QNetworkRequest::LowPriority);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);

    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("kded/geotimezoned/") + qApp->applicationVersion());

    auto *reply = m_nam.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        QScopedPointer<QNetworkReply, QScopedPointerDeleteLater> replyPtr(reply);
        if (replyPtr->error() != QNetworkReply::NoError) {
            qCWarning(GEOTIMEZONED_DEBUG) << "Failed to load time zone from" << replyPtr->url() << replyPtr->errorString();
            return;
        }

        const QJsonObject replyObject = QJsonDocument::fromJson(replyPtr->readAll()).object();
        const QString timeZone = replyObject.value(QLatin1String("time_zone")).toString();
        if (timeZone.isEmpty()) {
            qCWarning(GEOTIMEZONED_DEBUG) << "Received no or an invalid time zone object" << replyObject;
            return;
        }

        qCInfo(GEOTIMEZONED_DEBUG) << "Received time zone" << timeZone;
        setGeoTimeZone(timeZone.toLatin1());
        m_timer.restart();
    });
}

void KdedGeoTimeZonePlugin::setGeoTimeZone(const QByteArray &geoTimeZoneId)
{
    // No change since we last asked.
    if (m_geoTimeZoneId == geoTimeZoneId) {
        qCDebug(GEOTIMEZONED_DEBUG) << "Time zone didn't change from" << m_geoTimeZoneId << "from last check";
        return;
    }

    org::freedesktop::timedate1 timedateInterface{s_timedateService, s_timedatePath, QDBusConnection::systemBus()};

    const QString currentTimeZoneId = timedateInterface.timezone();
    if (currentTimeZoneId.isEmpty()) {
        qCWarning(GEOTIMEZONED_DEBUG) << "Failed to get current system time zone from timedated";
        return;
    }

    if (currentTimeZoneId == geoTimeZoneId) {
        qCDebug(GEOTIMEZONED_DEBUG) << "Time zone" << geoTimeZoneId << "is the same as the current time zone";
        return;
    }

    qCInfo(GEOTIMEZONED_DEBUG) << "Automatically changing time zone to" << geoTimeZoneId << "based on current location";
    auto reply = timedateInterface.SetTimezone(QString::fromLatin1(geoTimeZoneId), false /*interactive*/);
    auto *watcher = new QDBusPendingCallWatcher(reply, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, geoTimeZoneId](QDBusPendingCallWatcher *watcher) {
        watcher->deleteLater();

        QDBusPendingReply<> reply = *watcher;
        if (reply.isError()) {
            qCWarning(GEOTIMEZONED_DEBUG) << "Failed to set time zone to" << geoTimeZoneId << reply.error().message();
            return;
        }

        m_geoTimeZoneId = geoTimeZoneId;
    });
}

#include "geotimezonemodule.moc"
