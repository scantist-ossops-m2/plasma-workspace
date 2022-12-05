/*
    ksmserver - the KDE session management server

    SPDX-FileCopyrightText: 2016 Martin Graesslin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2018 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: MIT
*/

#include "greeter.h"

#include <QApplication>
#include <QDebug>
#include <QScreen>
#include <QWaylandClientExtensionTemplate>
#include <qpa/qplatformnativeinterface.h>

#include "shutdowndlg.h"

#include "ksmserveriface.h"
#include "logoutpromptadaptor.h"

#include <KQuickAddons/QtQuickSettings>
#include <KWindowSystem>
#include <LayerShellQt/Shell>

#include "qwayland-kde-lockscreen-overlay-v1.h"

class WaylandAboveLockscreen : public QWaylandClientExtensionTemplate<WaylandAboveLockscreen>, public QtWayland::kde_lockscreen_overlay_v1
{
public:
    WaylandAboveLockscreen()
        : QWaylandClientExtensionTemplate<WaylandAboveLockscreen>(1)
    {
        QMetaObject::invokeMethod(this, "addRegistryListener");
    }

    void allowWindow(QWindow *window)
    {
        QPlatformNativeInterface *native = qGuiApp->platformNativeInterface();
        wl_surface *surface = reinterpret_cast<wl_surface *>(native->nativeResourceForWindow(QByteArrayLiteral("surface"), window));

        Q_ASSERT(surface);
        allow(surface);
    }
};

Greeter::Greeter(const KPackage::Package &package)
    : QObject()
    , m_package(package)
{
    new LogoutPromptAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/LogoutPrompt"), this);
    QDBusConnection::sessionBus().registerService(QStringLiteral("org.kde.LogoutPrompt"));
}

Greeter::~Greeter()
{
    qDeleteAll(m_dialogs);
}

void Greeter::setupWaylandIntegration()
{
    if (!KWindowSystem::isPlatformWayland() || m_windowed) {
        return;
    }
    LayerShellQt::Shell::useLayerShell();
}

void Greeter::init()
{
    setupWaylandIntegration();
    const auto screens = qApp->screens();
    for (QScreen *screen : screens) {
        adoptScreen(screen);
    }
    connect(qApp, &QGuiApplication::screenAdded, this, &Greeter::adoptScreen);
    m_running = true;
}

void Greeter::enableWindowed()
{
    m_windowed = true;
    promptLogout();
}

void Greeter::adoptScreen(QScreen *screen)
{
    if (screen->geometry().isNull()) {
        return;
    }
    // TODO: last argument is the theme, maybe add command line option for it?
    KSMShutdownDlg *w = new KSMShutdownDlg(nullptr, m_shutdownType, screen);
    w->setWindowed(m_windowed);
    w->installEventFilter(this);
    m_dialogs << w;

    QObject::connect(screen, &QObject::destroyed, w, [w, this] {
        m_dialogs.removeOne(w);
        w->deleteLater();
    });
    connect(w, &KSMShutdownDlg::rejected, this, &Greeter::rejected);
    connect(w, &KSMShutdownDlg::accepted, this, []() {
        QApplication::exit(1);
    });
    w->setGeometry(screen->geometry());
    w->init(m_package);
    
    // lockscreen overlay
    if (KWindowSystem::isPlatformWayland()) {
        // get lockscreen state
        QDBusMessage request = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.ScreenSaver"),
                                                              QStringLiteral("/ScreenSaver"),
                                                              QStringLiteral("org.freedesktop.ScreenSaver"),
                                                              QStringLiteral("GetActive"));
        const QDBusReply<bool> response = QDBusConnection::sessionBus().call(request);

        bool lockscreenShown = response.isValid() ? response.value() : false;
        
        if (lockscreenShown) {
            // allow window over lockscreen
            WaylandAboveLockscreen aboveLockscreen;
            Q_ASSERT(aboveLockscreen.isInitialized());
            aboveLockscreen.allowWindow(w);
            
            // put window over lockscreen
            KWindowSystem::requestXdgActivationToken(w, 0, QStringLiteral("org.kde.plasmashell.desktop"));

            QObject::connect(KWindowSystem::self(), &KWindowSystem::xdgActivationTokenArrived, w, [w](int, const QString &token) {
                KWindowSystem::setCurrentXdgActivationToken(token);
                KWindowSystem::activateWindow(w);
            });
        }
    }
}

void Greeter::rejected()
{
    QApplication::exit(1);
}

bool Greeter::eventFilter(QObject *watched, QEvent *event)
{
    if (qobject_cast<KSMShutdownDlg *>(watched)) {
        if (event->type() == QEvent::MouseButtonPress) {
            // check that the position is on no window
            QMouseEvent *me = static_cast<QMouseEvent *>(event);
            for (auto it = m_dialogs.constBegin(); it != m_dialogs.constEnd(); ++it) {
                if ((*it)->geometry().contains(me->globalPos())) {
                    return false;
                }
            }
            // click outside, close
            rejected();
        }
    }
    return false;
}

void Greeter::promptLogout()
{
    if (m_running) {
        return;
    }
    m_shutdownType = KWorkSpace::ShutdownTypeNone;
    init();
}

void Greeter::promptShutDown()
{
    if (m_running) {
        return;
    }
    m_shutdownType = KWorkSpace::ShutdownTypeHalt;
    init();
}

void Greeter::promptReboot()
{
    if (m_running) {
        return;
    }
    m_shutdownType = KWorkSpace::ShutdownTypeReboot;
    init();
}
