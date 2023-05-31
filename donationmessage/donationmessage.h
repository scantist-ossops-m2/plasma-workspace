/*
    SPDX-FileCopyrightText: 2023 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
#pragma once

#include <kdedmodule.h>

#include <KConfigWatcher>
#include <KNotification>

class DonationMessage : public KDEDModule
{
    Q_OBJECT
public:
    DonationMessage(QObject *parent, const QList<QVariant> &);

private:
    void showMessage();

    KConfigWatcher::Ptr m_configWatcher;
};
