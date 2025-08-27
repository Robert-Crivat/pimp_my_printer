# Pimp My Printer 🖨️

A cross-platform Flutter application for advanced control and management of 3D printers. Monitor and control your 3D printers from any device, prepare your models for printing, and view the printing process in real-time.

## 🌟 Key Features

- **Unified Dashboard** - Control multiple printers from a single interface
- **Advanced 3D Viewer** - View STL models with support for rotation, zoom, and manipulation
- **Integrated Slicer** - Prepare your 3D models for printing directly in the app
- **Real-time Monitoring** - Check temperatures, progress, and printer status
- **Remote Control** - Send commands and manage your printer from anywhere
- **Cross-platform Compatibility** - Works on Android, iOS, Web, Windows, macOS, and Linux

## 📱 Screenshots

*Screenshots will be added soon*

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (version 3.9.0 or higher)
- An Android/iOS device/emulator or a web browser

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/Robert-Crivat/pimp_my_printer.git
   ```

2. Navigate to the project directory:
   ```bash
   cd pimp_my_printer
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## 📋 App Components

### Main Screen

The application includes several screens accessible from the side menu:

- **Dashboard** - General overview of printer status
- **Temperature** - Control and monitoring of hotend and bed temperatures
- **Controls** - Manual axis movement and other operations
- **Webcam** - Real-time visualization of the printer
- **Slicer** - Preparation of 3D models for printing
- **G-Code Files** - Management of print files
- **Macros** - Custom commands for frequent operations
- **Settings** - Application configuration

### 3D Viewer

The `STL3DViewer` component allows you to:

- Load and view STL models
- Rotate, zoom, and manipulate the model
- View the model with realistic lighting
- Works in both mobile and web environments

### Slicer

The integrated Slicer allows you to:

- Load STL, OBJ, 3MF, or AMF models
- Configure print parameters (layer height, temperature, speed)
- Preview the model
- Generate print-ready G-code

## 🛠️ Technologies Used

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Custom Painters** - Advanced rendering for the 3D viewer
- **WebSockets** - Real-time communication with the printer
- **File Picker** - Selection of 3D models

## 🔄 Architecture

The application is structured following a component-based architecture:

- **Providers** - Manage the application state (theme, connection, etc.)
- **Screens** - Main user interfaces of the application
- **Widgets** - Reusable components (3D viewer, controls, etc.)
- **Utils** - Utility functions and helpers
- **Models** - Data structures to represent entities like printers, files, etc.

## 🤝 Contributing

Contributions are welcome! If you would like to contribute:

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add an amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Roadmap

- [ ] Support for multiple printer protocols (OctoPrint, Klipper, Marlin)
- [ ] Integrated G-code editor
- [ ] Support for multiple cameras
- [ ] Push notifications for printer events
- [ ] Support for multi-material printing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- Thanks to all contributors who have invested time and effort in this project
- Thanks to the Flutter community for support and shared resources

---

Made with ❤️ for the 3D printing community.
