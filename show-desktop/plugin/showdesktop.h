#pragma once

#include <QObject>
#include <QDBusInterface>

class ShowDesktop : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool showingDesktop READ showingDesktop NOTIFY showingDesktopChanged)

public:
    explicit ShowDesktop(QObject *parent = nullptr);

    bool showingDesktop() const;
    Q_INVOKABLE void setShowingDesktop(bool showing);
    Q_INVOKABLE void toggle();

Q_SIGNALS:
    void showingDesktopChanged();

private Q_SLOTS:
    void onShowingDesktopChanged(bool showing);

private:
    void refresh();

    QDBusInterface m_iface;
    bool m_showing = false;
};
