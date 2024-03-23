/*
    SPDX-FileCopyrightText: 2024 Fushan Wen <qydwhotmail@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mediacontroller as MC

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configRoot

    property bool cfg_multiplexerEnabled
    property bool cfg_useGlobalPreferredPlayer
    property string cfg_localPreferredPlayer

    MC.PlayerHistoryModel {
        id: historyModel
    }

    Component {
        id: nameDialog

        Kirigami.PromptDialog {
            parent: configRoot
            title: i18nc("@title", "Other…")
            standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

            onAccepted: if (textField.text.length > 0) {
                historyModel.rememberPlayer(textField.text);
                configRoot.cfg_localPreferredPlayer = textField.text;
            }
            onClosed: destroy()

            Kirigami.ActionTextField {
                id: textField
                focus: true
                placeholderText: i18nc("@label", "Enter a player name. Example: org.kde.elisa")
            }

            Component.onCompleted: open()
        }
    }

    Kirigami.FormLayout {
        Layout.fillHeight: true

        RowLayout {
            Kirigami.FormData.label: i18nc("@label", "Favorite player:")
            spacing: Kirigami.Units.largeSpacing

            QQC.CheckBox {
                id: multiplexerEnabledCheckBox
                Layout.fillWidth: false
                text: i18nc("@option:check", "Enable")
                checked: configRoot.cfg_multiplexerEnabled
                onToggled: configRoot.cfg_multiplexerEnabled = checked
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18nc("@info:tooltip", "A proxy player that will automatically update based on the player that the user is currently using.")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC.RadioButton {
            id: followGlobalRadioButon
            Kirigami.FormData.label: i18nc("@label", "Choose favorite player from:")
            Layout.fillWidth: false
            enabled: multiplexerEnabledCheckBox.checked
            text: i18nc("@option:radio", "Choose automatically")
            checked: configRoot.cfg_useGlobalPreferredPlayer
            onToggled: configRoot.cfg_useGlobalPreferredPlayer = followGlobalRadioButon.checked
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC.RadioButton {
                id: useLocalRadioButton
                Layout.fillWidth: false
                enabled: multiplexerEnabledCheckBox.checked
                text: i18nc("@option:radio", "Always this one when available:")
                checked: !configRoot.cfg_useGlobalPreferredPlayer
                onToggled: configRoot.cfg_useGlobalPreferredPlayer = !useLocalRadioButton.checked;
            }

            QQC.ComboBox {
                id: playerComboBox
                enabled: useLocalRadioButton.enabled && useLocalRadioButton.checked
                model: historyModel
                textRole: "display"
                valueRole: "identity"
                currentIndex: count, historyModel.indexOf(configRoot.cfg_localPreferredPlayer)

                delegate: QQC.ItemDelegate {
                    width: ListView.view.width
                    text: model.display
                    icon.name: model.decoration
                }

                onActivated: index => {
                    if (index == count - 1) {
                        nameDialog.createObject(configRoot);
                        return;
                    }
                    configRoot.cfg_localPreferredPlayer = currentValue;
                }

                // HACK QQC doesn't support icons, so we just tamper with the desktop style ComboBox's background
                Component.onCompleted: {
                    if (!background || !background.hasOwnProperty("properties")) {
                        //not a KQuickStyleItem
                        return;
                    }
                    const props = background.properties || {};
                    background.properties = Qt.binding(() => {
                        const modelIndex = model.index(currentIndex, 0);
                        const currentIcon = model.data(modelIndex, Qt.DecorationRole);
                        return Object.assign(props, {
                            currentIcon,
                            iconColor: Kirigami.Theme.textColor,
                        });
                    });
                }
            }

            QQC.Button {
                enabled: playerComboBox.enabled && playerComboBox.count > 1
                display: QQC.AbstractButton.IconOnly
                icon.name: "edit-clear-all"
                text: i18nc("@action:button", "Forget all players")
                onClicked: historyModel.forgetAllPlayers()
                QQC.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC.ToolTip.text: text
                QQC.ToolTip.visible: (hovered || activeFocus) && enabled
            }
        }
    }
}
