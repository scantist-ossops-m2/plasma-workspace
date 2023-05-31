/*
    SPDX-FileCopyrightText: 2023 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "donationmessage.h"

#include <KConfigWatcher>
#include <KLocalizedString>
#include <KNotification>
#include <KPluginFactory>

K_PLUGIN_CLASS_WITH_JSON(DonationMessage, "donationmessage.json")

DonationMessage::DonationMessage(QObject *parent, const QList<QVariant> &)
    : KDEDModule(parent)
{
    m_configWatcher = KConfigWatcher::create(KSharedConfig::openConfig(QStringLiteral("plasmashellrc")));
    showMessage();
}

void DonationMessage::showMessage()
{
    KConfigGroup *group = new KConfigGroup(m_configWatcher->config(), QStringLiteral("DonationMessage"));
    const bool enabled = group->readEntry(QStringLiteral("enabled"), true);
    if (enabled) {
        KNotification *notification = new KNotification(QStringLiteral("ShowDonationMessage"));
        notification->setComponentName(QStringLiteral("donationmessage"));

        notification->setFlags(KNotification::NotificationFlag::Persistent);

        const QString donateAction = i18n("Donate Now");
        const QString dontShowAgainAction = i18n("Don't Show Again");
        notification->setActions({dontShowAgainAction, donateAction});
        notification->setDefaultAction(donateAction);

        // "Don't show again" button clicked
        connect(notification, &KNotification::action1Activated, this, [group, notification]() {
            group->writeEntry(QStringLiteral("enabled"), false);
            notification->close();
        });

        // "Donate" button clicked
        connect(notification, &KNotification::action1Activated, this, [group, notification]() {
            group->writeEntry(QStringLiteral("enabled"), false);
            notification->close();
        });

        notification->sendEvent();
    }
}

#include "donationmessage.moc"
