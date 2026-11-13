# Dore

**See what your Mac is doing, right from the menu bar.**

Dore is a native macOS system monitor built with SwiftUI. It brings processor activity, memory usage, network traffic, storage, power draw, and temperatures into one app, with a compact menu bar view for quick checks and a full dashboard for a closer look.

Whether you are watching resource usage during a build, checking network activity during a download, or exploring how a workload affects temperature and power consumption, Dore keeps the relevant readings within reach.

## A quick glance or a closer look

Keep your preferred metrics visible in the menu bar: a CPU activity graph, memory usage, system power draw, or a combined CPU, memory, and temperature display. An icon-only option keeps the menu bar minimal.

Click the menu bar item to open a compact overview with live readings and recent activity. Open the dashboard to explore dedicated views for the processor, memory, network, storage, power, and thermals. CPU, memory, and network charts offer one-minute and five-minute views, and monitoring can be paused and resumed from either the dashboard or the popover.

## What you can monitor

| Area | Readings |
| --- | --- |
| Processor and GPU | CPU activity and GPU utilization |
| Memory | Memory usage and its breakdown |
| Network | Upload and download rates with recent history |
| Storage | Used and available disk space |
| Power | CPU and GPU power draw, total system power, battery level, and charging status |
| Thermals | Temperature sensors, fan speeds, and the system thermal state |

Hardware readings depend on the Mac model and the interfaces exposed by macOS. Some metrics may be unavailable on a particular machine. The project has been tested on Apple M5 Max with macOS 27.2.

## Made for everyday use

- Choose a refresh interval of one, two, or five seconds.
- Use the system appearance or select a light or dark theme.
- Review recent activity locally; monitoring history is cleared when Dore quits.
- Read hardware metrics through a bundled, read-only XPC service while the main app remains sandboxed.

## Build and run

1. Clone this repository and open `Dore.xcodeproj` in Xcode.
2. Select the **Dore** scheme and **My Mac** as the run destination.
3. Build and run.

The project includes two main parts:

- **Dore** — The SwiftUI app, menu bar interface, dashboard, and monitoring state.
- **DoreHelper** — The embedded XPC service used to read hardware sensor and energy data.

## Project history

Dore began as a menu bar network speed monitor and has evolved into a broader native system monitoring app. Development of the current app lives on `main`; the earlier implementation is preserved on the `legacy` branch.

Previous published versions are available on the [Releases page](https://github.com/weihas/Dore/releases).

## License

Dore is open source under the [MIT License](LICENSE).
