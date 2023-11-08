/*
 * SPDX-FileCopyrightText: 2019 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "nightcolormonitor.h"
#include "nightcolormonitor_p.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>

static const QString s_serviceName = QStringLiteral("org.kde.NightColor");
static const QString s_nightColorPath = QStringLiteral("/ColorCorrect");
static const QString s_nightColorInterface = QStringLiteral("org.kde.kwin.ColorCorrect");
static const QString s_propertiesInterface = QStringLiteral("org.freedesktop.DBus.Properties");

NightColorMonitorPrivate::NightColorMonitorPrivate(QObject *parent)
    : QObject(parent)
{
    QDBusConnection bus = QDBusConnection::sessionBus();

    // clang-format off
    const bool connected = bus.connect(s_serviceName,
                                       s_nightColorPath,
                                       s_propertiesInterface,
                                       QStringLiteral("PropertiesChanged"),
                                       this,
                                       SLOT(handlePropertiesChanged(QString,QVariantMap,QStringList)));
    // clang-format on
    if (!connected) {
        return;
    }

    QDBusMessage message = QDBusMessage::createMethodCall(s_serviceName, s_nightColorPath, s_propertiesInterface, QStringLiteral("GetAll"));
    message.setArguments({s_nightColorInterface});

    QDBusPendingReply<QVariantMap> properties = bus.asyncCall(message);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(properties, this);

    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *self) {
        self->deleteLater();

        const QDBusPendingReply<QVariantMap> properties = *self;
        if (properties.isError()) {
            return;
        }

        updateProperties(properties.value());
    });
}

NightColorMonitorPrivate::~NightColorMonitorPrivate()
{
}

void NightColorMonitorPrivate::handlePropertiesChanged(const QString &interfaceName,
                                                       const QVariantMap &changedProperties,
                                                       const QStringList &invalidatedProperties)
{
    Q_UNUSED(interfaceName)
    Q_UNUSED(invalidatedProperties)

    updateProperties(changedProperties);
}

int NightColorMonitorPrivate::currentTemperature() const
{
    return m_currentTemperature;
}

int NightColorMonitorPrivate::targetTemperature() const
{
    return m_targetTemperature;
}

void NightColorMonitorPrivate::updateProperties(const QVariantMap &properties)
{
    const QVariant available = properties.value(QStringLiteral("available"));
    if (available.isValid()) {
        setAvailable(available.toBool());
    }

    const QVariant enabled = properties.value(QStringLiteral("enabled"));
    if (enabled.isValid()) {
        setEnabled(enabled.toBool());
    }

    const QVariant running = properties.value(QStringLiteral("running"));
    if (running.isValid()) {
        setRunning(running.toBool());
    }

    const QVariant currentTemperature = properties.value(QStringLiteral("currentTemperature"));
    if (currentTemperature.isValid()) {
        setCurrentTemperature(currentTemperature.toInt());
    }

    const QVariant targetTemperature = properties.value(QStringLiteral("targetTemperature"));
    if (targetTemperature.isValid()) {
        setTargetTemperature(targetTemperature.toInt());
    }
}

void NightColorMonitorPrivate::setCurrentTemperature(int temperature)
{
    if (m_currentTemperature == temperature) {
        return;
    }
    m_currentTemperature = temperature;
    Q_EMIT currentTemperatureChanged();
}

void NightColorMonitorPrivate::setTargetTemperature(int temperature)
{
    if (m_targetTemperature == temperature) {
        return;
    }
    m_targetTemperature = temperature;
    Q_EMIT targetTemperatureChanged();
}

bool NightColorMonitorPrivate::isAvailable() const
{
    return m_isAvailable;
}

void NightColorMonitorPrivate::setAvailable(bool available)
{
    if (m_isAvailable == available) {
        return;
    }
    m_isAvailable = available;
    Q_EMIT availableChanged();
}

bool NightColorMonitorPrivate::isEnabled() const
{
    return m_isEnabled;
}

void NightColorMonitorPrivate::setEnabled(bool enabled)
{
    if (m_isEnabled == enabled) {
        return;
    }
    m_isEnabled = enabled;
    Q_EMIT enabledChanged();
}

bool NightColorMonitorPrivate::isRunning() const
{
    return m_isRunning;
}

void NightColorMonitorPrivate::setRunning(bool running)
{
    if (m_isRunning == running) {
        return;
    }
    m_isRunning = running;
    Q_EMIT runningChanged();
}

NightColorMonitor::NightColorMonitor(QObject *parent)
    : QObject(parent)
    , d(new NightColorMonitorPrivate(this))
{
    connect(d, &NightColorMonitorPrivate::availableChanged, this, &NightColorMonitor::availableChanged);
    connect(d, &NightColorMonitorPrivate::enabledChanged, this, &NightColorMonitor::enabledChanged);
    connect(d, &NightColorMonitorPrivate::runningChanged, this, &NightColorMonitor::runningChanged);
    connect(d, &NightColorMonitorPrivate::currentTemperatureChanged, this, &NightColorMonitor::currentTemperatureChanged);
    connect(d, &NightColorMonitorPrivate::targetTemperatureChanged, this, &NightColorMonitor::targetTemperatureChanged);
}

NightColorMonitor::~NightColorMonitor()
{
}

bool NightColorMonitor::isAvailable() const
{
    return d->isAvailable();
}

bool NightColorMonitor::isEnabled() const
{
    return d->isEnabled();
}

bool NightColorMonitor::isRunning() const
{
    return d->isRunning();
}

int NightColorMonitor::currentTemperature() const
{
    return d->currentTemperature();
}

int NightColorMonitor::targetTemperature() const
{
    return d->targetTemperature();
}
