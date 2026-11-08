#include "showdesktop.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusVariant>

ShowDesktop::ShowDesktop(QObject *parent)
    : QObject(parent)
    , m_iface(QStringLiteral("org.kde.KWin"),
              QStringLiteral("/KWin"),
              QStringLiteral("org.kde.KWin"),
              QDBusConnection::sessionBus(),
              this)
{
    QDBusConnection::sessionBus().connect(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/KWin"),
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("showingDesktopChanged"),
        this,
        SLOT(onShowingDesktopChanged(bool)));

    refresh();
}

bool ShowDesktop::showingDesktop() const
{
    return m_showing;
}

void ShowDesktop::setShowingDesktop(bool showing)
{
    m_iface.call(QStringLiteral("showDesktop"), showing);
    if (m_showing != showing) {
        m_showing = showing;
        Q_EMIT showingDesktopChanged();
    }
}

void ShowDesktop::toggle()
{
    setShowingDesktop(!m_showing);
}

void ShowDesktop::refresh()
{
    const QVariant value = m_iface.property("showingDesktop");
    if (value.isValid() && value.toBool() != m_showing) {
        m_showing = value.toBool();
        Q_EMIT showingDesktopChanged();
    }
}

void ShowDesktop::onShowingDesktopChanged(bool showing)
{
    if (m_showing != showing) {
        m_showing = showing;
        Q_EMIT showingDesktopChanged();
    }
}
