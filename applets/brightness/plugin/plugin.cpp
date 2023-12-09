/*
 * SPDX-FileCopyrightText: 2019 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "nightlightinhibitor.h"
#include "nightlightmonitor.h"

#include <QQmlEngine>
#include <QQmlExtensionPlugin>

class Plugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<NightLightInhibitor>(uri, 1, 0, "NightLightInhibitor");
        qmlRegisterType<NightLightMonitor>(uri, 1, 0, "NightLightMonitor");
    }
};

#include "plugin.moc"
