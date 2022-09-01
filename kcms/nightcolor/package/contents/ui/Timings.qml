/*
    SPDX-FileCopyrightText: 2022 Bharadwaj Raju <bharadwaj.raju777@protonmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

import org.kde.kirigami 2.15 as Kirigami

import org.kde.private.kcms.nightcolor 1.0

Item {
    id: root
    property int sliderWidth: 500

    property bool interactive: kcm.nightColorSettings.mode === NightColorMode.Timings
    property bool sameTransitionDurations: !(kcm.nightColorSettings.mode === NightColorMode.Automatic || kcm.nightColorSettings.mode === NightColorMode.Location)

    implicitHeight: Kirigami.Units.gridUnit * 2
    implicitWidth: sliderWidth

    // from Breeze
    readonly property string blue: "#93cee9"
    readonly property string orange: "#f67400"

    property alias startTime: startTimeSlider.value
    property alias startFinishTime: startFinTimeSlider.value
    property alias endTime: endTimeSlider.value
    property alias endFinishTime: endFinTimeSlider.value

    property int endTimeBackend: {
        if (kcm.nightColorSettings.mode === NightColorMode.Automatic || kcm.nightColorSettings.mode === NightColorMode.Location) {
            var latitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.latitude : kcm.nightColorSettings.latitudeFixed;
            var longitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.longitude : kcm.nightColorSettings.longitudeFixed;
            var t = sunCalc.getMorningTimings(latitude, longitude).begin;
            return t.getHours() * 60 + t.getMinutes();
        } else {
            var backend = kcm.nightColorSettings.morningBeginFixed;
            var hours = parseInt(backend.slice(0, 2), 10);
            var minutes = parseInt(backend.slice(2, 4), 10);
            return hours * 60 + minutes;
        }
    }

    property int startTimeBackend: {
        if (kcm.nightColorSettings.mode === NightColorMode.Automatic || kcm.nightColorSettings.mode === NightColorMode.Location) {
            var latitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.latitude : kcm.nightColorSettings.latitudeFixed;
            var longitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.longitude : kcm.nightColorSettings.longitudeFixed;
            var t = sunCalc.getEveningTimings(latitude, longitude).begin;
            return t.getHours() * 60 + t.getMinutes();
        } else {
            var backend = kcm.nightColorSettings.eveningBeginFixed;
            var hours = parseInt(backend.slice(0, 2), 10);
            var minutes = parseInt(backend.slice(2, 4), 10);
            return hours * 60 + minutes;
        }
    }

    onStartTimeBackendChanged: {
        startTime = startTimeBackend
    }
    onEndTimeBackendChanged: {
        endTime = endTimeBackend
    }

    property int startFinishTimeBackend: {
        if (kcm.nightColorSettings.mode === NightColorMode.Automatic || kcm.nightColorSettings.mode === NightColorMode.Location) {
            var latitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.latitude : kcm.nightColorSettings.latitudeFixed;
            var longitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.longitude : kcm.nightColorSettings.longitudeFixed;
            var t = sunCalc.getEveningTimings(latitude, longitude).end;
            return t.getHours() * 60 + t.getMinutes();
        } else {
            var backend = kcm.nightColorSettings.eveningBeginFixed;
            var hours = parseInt(backend.slice(0, 2), 10);
            var minutes = parseInt(backend.slice(2, 4), 10);
            return hours * 60 + minutes + kcm.nightColorSettings.transitionTime;
        }
    }

    onStartFinishTimeBackendChanged: {
        startFinishTime = startFinishTimeBackend
    }

    onStartFinishTimeChanged: {
        if (kcm.nightColorSettings.mode === NightColorMode.Timings) {
            var startTimeBackend = kcm.nightColorSettings.eveningBeginFixed;
            var hours = parseInt(startTimeBackend.slice(0, 2), 10);
            var minutes = parseInt(startTimeBackend.slice(2, 4), 10);
            kcm.nightColorSettings.transitionTime = startFinishTime - (hours * 60 + minutes);
        }
    }

    property int endFinishTimeBackend: {
        if (kcm.nightColorSettings.mode === NightColorMode.Automatic || kcm.nightColorSettings.mode === NightColorMode.Location) {
            var latitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.latitude : kcm.nightColorSettings.latitudeFixed;
            var longitude = kcm.nightColorSettings.mode === NightColorMode.Automatic && (locator !== undefined) ? locator.longitude : kcm.nightColorSettings.longitudeFixed;
            var t = sunCalc.getMorningTimings(latitude, longitude).end;
            return t.getHours() * 60 + t.getMinutes();
        } else {
            var backend = kcm.nightColorSettings.morningBeginFixed;
            var hours = parseInt(backend.slice(0, 2), 10);
            var minutes = parseInt(backend.slice(2, 4), 10);
            return hours * 60 + minutes + kcm.nightColorSettings.transitionTime;
        }
    }

    onEndFinishTimeBackendChanged: {
        endFinishTime = endFinishTimeBackend
    }

    onEndFinishTimeChanged: {
        if (kcm.nightColorSettings.mode === NightColorMode.Timings) {
            var endTimeBackend = kcm.nightColorSettings.morningBeginFixed;
            var hours = parseInt(endTimeBackend.slice(0, 2), 10);
            var minutes = parseInt(endTimeBackend.slice(2, 4), 10);
            kcm.nightColorSettings.transitionTime = endFinishTime - (hours * 60 + minutes);
        }
    }

    signal userChangedStartTime(value: int)
    signal userChangedEndTime(value: int)

    function changeStartTime(value) {
        startTimeSlider.changeValue(value)
    }
    function changeEndTime(value) {
        endTimeSlider.changeValue(value)
    }

    function prettyTime(minutes) {
        var d = new Date();
        d.setHours(Math.trunc(minutes/60));
        d.setMinutes(minutes%60);
        return d.toLocaleString(Qt.locale(), "hh:mm");
    }

    Accessible.description: i18nc("@info Night Color starting, ending, and transition times in hh:mm format",
        "Night Color begins changing at %1 and is fully changed by %2. Night Color begins changing back at %3 and ends at %4.",
        prettyTime(startTime), prettyTime(startFinishTime),
        prettyTime(endTime), prettyTime(endFinishTime))

    HandleOnlySlider {
        id: startTimeSlider
        from: 0
        to: 1440 // 24h in min
        interactive: root.interactive
        value: -1
        pointerLabel: i18nc("@info night color starts to take effect", "Color starts changing at %1", prettyTime(value))
        handleToolTip: "When Night Color starts to take effect"
        stepSize: 1
        live: true
        onUserChangedValue: {
            var hours = Math.trunc(value/60);
            var minutes = value%60;
            kcm.nightColorSettings.eveningBeginFixed = String(hours).padStart(2, "0") + String(minutes).padStart(2, "0")
        }
        pointerOnBottom: false
        width: sliderWidth
    }
    HandleOnlySlider {
        id: endTimeSlider
        from: 0
        to: 1440 // 24h in min
        value: -1
        interactive: root.interactive
        onUserChangedValue: {
            var hours = Math.trunc(value/60);
            var minutes = value%60;
            kcm.nightColorSettings.morningBeginFixed = String(hours).padStart(2, "0") + String(minutes).padStart(2, "0")
        }
        pointerLabel: i18nc("@info night color starts to end", "Color starts changing back at %1", prettyTime(value))
        handleToolTip: "When Night Color starts ending"
        stepSize: 1
        live: true
        pointerOnBottom: false
        width: sliderWidth
    }
    HandleOnlySlider {
        id: startFinTimeSlider
        from: 0
        to: 1440 // 24h in min
        interactive: root.interactive
        minDrag: (value - startTimeSlider.value >= 0) ? startTimeSlider.visualPosition : 0.0
        pointerLabel: i18nc("@info night color has fully taken effect", "Color fully changed at %1", prettyTime(value))
        onUserChangedValue: {
            startFinTimeSlider.value = value
        }
        handleToolTip: "When Night Color is completely applied"
        stepSize: 1
        live: true
        width: sliderWidth
    }
    HandleOnlySlider {
        id: endFinTimeSlider
        from: 0
        to: 1440 // 24h in min
        interactive: root.interactive
        minDrag: (value - endTimeSlider.value >= 0) ? endTimeSlider.visualPosition : 0.0
        pointerLabel: i18nc("@info night color has fully taken effect", "Color fully changed back at %1", prettyTime(value))
        onUserChangedValue: {
            endFinTimeSlider.value = value
        }
        handleToolTip: "When Night Color completely ends"
        stepSize: 1
        live: true
        width: sliderWidth
    }

    Rectangle {
        id: visualizer
        width: sliderWidth
        height: 10
        radius: 5
        opacity: 0.7

        LinearGradient {
            anchors.fill: parent
            source: visualizer
            start: Qt.point(0, 0)
            end: Qt.point(sliderWidth, 0)
            gradient: Gradient {
                GradientStop { position: endTimeSlider.visualPosition; color: orange }
                GradientStop { position: endFinTimeSlider.visualPosition + 0.01; color: blue }
                GradientStop { position: startTimeSlider.visualPosition; color: blue }
                GradientStop { position: startFinTimeSlider.visualPosition + 0.01; color: orange }
                GradientStop { position: 1.0; color: (startTimeSlider.visualPosition > endTimeSlider.visualPosition) ? orange : blue }
            }
        }
    }
}
