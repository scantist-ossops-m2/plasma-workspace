/*
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2021 Jan Blackquill <uhhadd@gmail.com>
    SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar

PlasmaComponents3.AbstractButton {
    id: dayStyle

    objectName: {
        switch (dateMatchingPrecision) {
        case Calendar.MatchYear:
            return "calendarCell-" + yearNumber;
        case Calendar.MatchYearAndMonth:
            return "calendarCell-" + yearNumber + "-" + monthNumber;
        case Calendar.MatchYearMonthAndDay:
        default:
            return "calendarCell-" + yearNumber + "-" + monthNumber + "-" + dayNumber;
        }
    }
    hoverEnabled: true
    property var dayModel: null

    signal activated

    readonly property date thisDate: new Date(yearNumber, typeof monthNumber !== "undefined" ? monthNumber - 1 : 0, typeof dayNumber !== "undefined" ? dayNumber : 1)

    Accessible.name: thisDate.toLocaleDateString(Qt.locale(), Locale.LongFormat)
    Accessible.description: {
        const eventDescription = (model.eventCount !== undefined && model.eventCount > 0) ? i18ndp("plasmashellprivateplugin", "%1 event", "%1 events", model.eventCount) : i18nd("plasmashellprivateplugin", "No events");
        const subLabelDescription = model.subLabel || model.subDayLabel || "";
        return `${eventDescription} ${subLabelDescription ? `; ${subLabelDescription}` : ""}`;
    }

    readonly property bool today: {
        const today = root.today;
        let result = true;
        if (dateMatchingPrecision >= Calendar.MatchYear) {
            result = result && today.getFullYear() === thisDate.getFullYear()
        }
        if (dateMatchingPrecision >= Calendar.MatchYearAndMonth) {
            result = result && today.getMonth() === thisDate.getMonth()
        }
        if (dateMatchingPrecision >= Calendar.MatchYearMonthAndDay) {
            result = result && today.getDate() === thisDate.getDate()
        }
        return result
    }
    readonly property bool selected: {
        const current = root.currentDate;
        let result = true;
        if (dateMatchingPrecision >= Calendar.MatchYear) {
            result = result && current.getFullYear() === thisDate.getFullYear()
        }
        if (dateMatchingPrecision >= Calendar.MatchYearAndMonth) {
            result = result && current.getMonth() === thisDate.getMonth()
        }
        if (dateMatchingPrecision >= Calendar.MatchYearMonthAndDay) {
            result = result && current.getDate() === thisDate.getDate()
        }
        return result
    }

    Loader {
        anchors.fill: parent

        active: dayStyle.activeFocus
        asynchronous: true

        sourceComponent: KSvg.FrameSvgItem {
            anchors {
                leftMargin: -margins.left
                topMargin: -margins.top
                rightMargin: -margins.right
                bottomMargin: -margins.bottom
            }
            imagePath: "widgets/button"
            prefix: ["toolbutton-focus", "focus"]
        }
    }

    Loader {
        anchors.fill: parent

        active: today || selected || dayStyle.hovered || dayStyle.activeFocus
        asynchronous: true
        z: -1

        sourceComponent: PlasmaExtras.Highlight {
            hovered: true
            opacity: {
                if (today) {
                    return 1;
                } else if (selected) {
                    return 0.6;
                } else if (dayStyle.hovered) {
                    return 0.3;
                } else if (dayStyle.activeFocus) {
                    return 0.1;
                }
                return 0;
            }
        }
    }

    Loader {
        active: model.eventCount !== undefined && model.eventCount > 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: subDayLabel.item?.implicitHeight ?? Kirigami.Units.smallSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: Row {
            spacing: Kirigami.Units.smallSpacing

            property bool hasSubDayLabel: false

            Repeater {
                model: DelegateModel {
                    model: dayStyle.dayModel
                    delegate: Rectangle {
                        width: hasSubDayLabel ? Kirigami.Units.mediumSpacing : Kirigami.Units.smallSpacing
                        height: width
                        radius: width / 2
                        color: model.eventColor ? Kirigami.ColorUtils.linearInterpolation(model.eventColor, Kirigami.Theme.textColor, 0.2) : Kirigami.Theme.highlightColor
                    }

                    Component.onCompleted: rootIndex = modelIndex(index)
                }
            }
        }

        onLoaded: item.hasSubDayLabel = Qt.binding(() => subDayLabel.active)
    }

    contentItem: Item {
        // ColumnLayout makes scrolling too slow, so use anchors to position labels

        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.text: model.subLabel || ""
        PlasmaComponents3.ToolTip.visible: !!model.subLabel && (Kirigami.Settings.isMobile ? dayStyle.pressed : dayStyle.hovered)

        Kirigami.Heading {
            id: label
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: subDayLabel.top
            }
            font.pixelSize: Math.max(
                Kirigami.Theme.defaultFont.pixelSize * 1.35 /* Level 1 Heading */,
                daysCalendar.cellHeight / (daysCalendar.dateMatchingPrecision === Calendar.MatchYearMonthAndDay ? 3 /* weeksColumn */ : 6))
            font.pointSize: -1 // Avoid QML warnings
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: model.label || dayNumber
            textFormat: Text.PlainText
            opacity: isCurrent ? 1.0 : 0.5
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Loader {
            id: subDayLabel
            active: (!!model.subDayLabel && model.subDayLabel.length > 0)
                 || typeof(model.alternateDayNumber) === "number"
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }
            asynchronous: true
            opacity: 0

            sourceComponent: PlasmaComponents3.Label {
                elide: Text.ElideRight
                font.pixelSize: Math.max(
                    Kirigami.Theme.smallFont.pixelSize,
                    daysCalendar.cellHeight / (daysCalendar.dateMatchingPrecision === Calendar.MatchYearMonthAndDay ? 6 : 12))
                font.pointSize: -1 // Avoid QML warnings
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 1
                opacity: label.opacity
                // Prefer sublabel over day number
                text: model.subDayLabel || model.alternateDayNumber.toString()
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
            }

            states: State {
                when: subDayLabel.status === Loader.Ready && subDayLabel.implicitHeight > 1
                AnchorChanges {
                    target: subDayLabel
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: subDayLabel
                    opacity: 1
                }
            }

            transitions: Transition {
                NumberAnimation {
                    property: "opacity"
                    easing.type: Easing.OutCubic
                    duration: Kirigami.Units.longDuration
                }
                AnchorAnimation {
                    easing.type: Easing.OutCubic
                    duration: Kirigami.Units.longDuration
                }
            }
        }

        Component.onCompleted: {
            if (dayStyle.today) {
                root.todayAuxilliaryText = Qt.binding(() => model.subLabel || "");
            }
        }
    }
}
