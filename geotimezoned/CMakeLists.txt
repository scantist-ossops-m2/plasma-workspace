# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2023 Kai Uwe Broulik <kde@broulik.de>

set(geotimezoned_SRCS
    geotimezonemodule.cpp
    geotimezonemodule.h
)
qt_add_dbus_interface(geotimezoned_SRCS org.freedesktop.timedated1.xml timedated_interface)

kcoreaddons_add_plugin(geotimezoned
    SOURCES
    ${geotimezoned_SRCS}
    INSTALL_NAMESPACE "kf6/kded"
)

ecm_qt_declare_logging_category(geotimezoned
    HEADER geotimezoned_debug.h
    IDENTIFIER GEOTIMEZONED_DEBUG
    CATEGORY_NAME org.kde.plasma.geotimezoned
    DESCRIPTION "Location-based System Time Zone"
)

target_link_libraries(geotimezoned
    Qt6::DBus
    Qt6::Network
    KF6::DBusAddons
    KF6::CoreAddons
    KF6::NetworkManagerQt
)
