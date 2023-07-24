/*
 * SPDX-FileCopyrightText: 2023 Kai Uwe Broulik <ghqalpha@broulik.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <KDEDModule>

#include <QByteArray>
#include <QElapsedTimer>
#include <QNetworkAccessManager>

class KdedGeoTimeZonePlugin : public KDEDModule
{
    Q_OBJECT

public:
    KdedGeoTimeZonePlugin(QObject *parent, const QVariantList &args);

private:
    bool shouldCheckTimeZone() const;
    void checkTimeZone();
    void setGeoTimeZone(const QByteArray &geoTimeZoneId);

    QNetworkAccessManager m_nam;
    QElapsedTimer m_timer;
    QByteArray m_geoTimeZoneId;
};
