debImport "-f" "tb.f"
verdiDockWidgetDisplay -dock widgetDock_WelcomePage
verdiDockWidgetHide -dock widgetDock_WelcomePage
srcHBSelect "testbench" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench" -delim "."
srcHBSelect "testbench.bus" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.bus" -delim "."
debExit
