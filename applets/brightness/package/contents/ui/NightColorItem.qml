/*
 * SPDX-FileCopyrightText: 2019 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
 * SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.5
import QtQuick.Layouts 1.15

import org.kde.kcmutils // KCMLauncher
import org.kde.config as KConfig  // KAuthorized.authorizeControlModule
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

import org.kde.plasma.private.nightcolorcontrol 1.0

PlasmaComponents3.ItemDelegate {
    id: root

    contentItem: RowLayout {
        spacing: Kirigami.Units.gridUnit

        Kirigami.Icon {
            id: image
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            source: monitor.running ? "redshift-status-on" : "redshift-status-off"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    id: title
                    Layout.fillWidth: true
                    text: root.text
                }

                PlasmaComponents3.Label {
                    id: status
                    Layout.alignment: Qt.AlignRight
                    text: {
                        if (inhibitor.state === Inhibitor.Inhibited && monitor.enabled) {
                            return i18n("Inhibited");
                        }
                        if (!monitor.available) {
                            return i18n("Unavailable");
                        }
                        if (!monitor.enabled) {
                            return i18n("Disabled");
                        }
                        if (!monitor.running) {
                            return i18n("Not running");
                        }
                        if (monitor.currentTemperature != monitor.targetTemperature) {
                            return i18n("Transitioning (%1K)", monitor.currentTemperature);
                        }
                        return i18n("Transitioning (%1K)", monitor.currentTemperature);
                    }
                }
            }
        }
    }

    function toggleInhibition() {
        if (!monitor.available) {
            return;
        }
        switch (inhibitor.state) {
        case Inhibitor.Inhibiting:
        case Inhibitor.Inhibited:
            inhibitor.uninhibit();
            break;
        case Inhibitor.Uninhibiting:
        case Inhibitor.Uninhibited:
            inhibitor.inhibit();
            break;
        }
    }

    function action_configure() {
        KCMLauncher.openSystemSettings("kcm_nightcolor");
    }

    Inhibitor {
        id: inhibitor
    }

    Monitor {
        id: monitor
    }

    PlasmaCore.Action {
        id: configureAction
        text: i18n("&Configure Night Color…")
        icon.name: "configure"
        visible: KConfig.KAuthorized.authorizeControlModule("kcm_nightcolor")
        shortcut: "alt+d, s"
        onTriggered: KCMLauncher.openSystemSettings("kcm_nightcolor")
    }

}
