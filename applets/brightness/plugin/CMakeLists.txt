ecm_add_qml_module(nightcolorcontrolplugin URI org.kde.plasma.private.nightcolorcontrol)
target_sources(nightcolorcontrolplugin PRIVATE
    nightcolorinhibitor.cpp
    nightcolormonitor.cpp
    nightcolorplugin.cpp
)
target_link_libraries(nightcolorcontrolplugin PRIVATE
    Qt::Core
    Qt::DBus
    Qt::Qml
)
ecm_finalize_qml_module(nightcolorcontrolplugin)
