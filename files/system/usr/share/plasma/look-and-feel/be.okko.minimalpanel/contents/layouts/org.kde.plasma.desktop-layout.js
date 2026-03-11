var panel = new Panel
panel.height = 2 * Math.floor(gridUnit * 2.5 / 2)
panel.location = "bottom"

var shutdown = panel.addWidget("org.kde.plasma.lock_logout")
shutdown.currentConfigGroup = ["General"]
shutdown.writeConfig("show_lockScreen", "false")
shutdown.writeConfig("show_requestLogoutScreen", "false")
shutdown.writeConfig("show_requestShutDown", "true")

var tasks = panel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["General"]
tasks.writeConfig("launchers", [
    "applications:org.kde.krdc.desktop"
])

panel.addWidget("org.kde.plasma.marginsseparator")
var systray = panel.addWidget("org.kde.plasma.systemtray")
systray.currentConfigGroup = ["General"]
systray.writeConfig("shownItems", ["org.kde.plasma.keyboardlayout"])
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")
