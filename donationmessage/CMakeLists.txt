include_directories (${CMAKE_CURRENT_BINARY_DIR}/..)

kcoreaddons_add_plugin(donationmessage SOURCES donationmessage.cpp donationmessage.h INSTALL_NAMESPACE "kf6/kded")

target_link_libraries(donationmessage
                        KF6::ConfigCore
                        KF6::CoreAddons
                        KF6::DBusAddons
                        KF6::I18n
                        KF6::KIOCore
                        KF6::Notifications
                     )

install(FILES donationmessage.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
