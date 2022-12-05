set(LOGOUT_GREETER_SRCS main.cpp greeter.cpp shutdowndlg.cpp)
ecm_qt_declare_logging_category(LOGOUT_GREETER_SRCS HEADER debug.h
                                IDENTIFIER LOGOUT_GREETER
                                CATEGORY_NAME kde.logout_greeter
                                DEFAULT_SEVERITY Info)


qt_add_dbus_adaptor( LOGOUT_GREETER_SRCS ../ksmserver/org.kde.LogoutPrompt.xml greeter.h Greeter)
qt_add_dbus_interface( LOGOUT_GREETER_SRCS ../ksmserver/org.kde.KSMServerInterface.xml ksmserveriface)

add_executable(ksmserver-logout-greeter ${LOGOUT_GREETER_SRCS})
target_link_libraries(ksmserver-logout-greeter
    PW::KWorkspace
    Qt::Widgets
    Qt::Quick
    Qt::DBus
    Qt::WaylandClient
    Qt::WaylandClientPrivate
    KF5::I18n
    KF5::Package
    KF5::QuickAddons
    KF5::WindowSystem
    KF5::ConfigCore
    X11::X11
    LayerShellQt::Interface
    Wayland::Client
)
if (QT_MAJOR_VERSION EQUAL "5")
    ecm_add_qtwayland_client_protocol(ksmserver-logout-greeter
        PROTOCOL ${PLASMA_WAYLAND_PROTOCOLS_DIR}/kde-lockscreen-overlay-v1.xml
        BASENAME kde-lockscreen-overlay-v1
    )
    
    target_link_libraries(ksmserver-logout-greeter Qt::X11Extras)
else()
    qt6_generate_wayland_protocol_client_sources(ksmserver-logout-greeter FILES
        ${PLASMA_WAYLAND_PROTOCOLS_DIR}/kde-lockscreen-overlay-v1.xml
    )
        
    target_link_libraries(ksmserver-logout-greeter Qt::GuiPrivate)
endif()

install(TARGETS ksmserver-logout-greeter DESTINATION ${KDE_INSTALL_LIBEXECDIR})
kdbusaddons_generate_dbus_service_file(ksmserver-logout-greeter org.kde.LogoutPrompt ${KDE_INSTALL_FULL_LIBEXECDIR})

if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
