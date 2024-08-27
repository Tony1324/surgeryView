# Surgery View: an OpenIGTLink 3d Viewer on Apple Vision Pro 

# Overview

## Purpose
We provide a user friendly way to show and interact with 3d anatomy in an augmented reality environment through Apple Vision Pro. Surgery View aims to offer patients a more intuitive and to-scale 3d visualization of surgical operations compared as an Education Tool. This tool also allows doctors to inspect and label constructed meshes from CT and MRI results in real time.

## General Usage
Some setup is necessary to configure eye and hand tracking on Vision Pro. This can be done following [Apple Support](https://support.apple.com/guide/apple-vision-pro/turn-on-and-set-up-devd5d9e3a52/visionos) SurgeryView must be installed and can be opened from the home view.

### Front-End Application
By default, the interface is configured for use via OpenIGTLink (see OpenIGTLink Integration below), with a minimal UI. The main interface features a volume, or 3d window, where multiple models and images can be displayed and interacted with. A more complex UI can be enabled that allows loading of other models, and more direct manipulation and display of information. 

This complex UI view features a control panel and toolbar.

The control panel positioned to the side of the scene can be used to select a variety of scenes, including a demo scene with 50 anatomical models pre-installed. It also shows a list of all 3d models, and their visibility can be toggled by selecting each item.

A floating toolbar provides two functions:

- reset: returns all objects to original size and scale
- explode: scatters each model for visibility

#### 3d-Viewer Gestures
All gestures on Vision Pro involve looking at a target using your eyes and performing either a tap or drag gesture with your hand. 

**Dragging**
Each image can be inspected by looking at it and pinching the index and thumb fingers, dragging it in 3d.

To move the entire scene, look and drag the white bar at the bottom front of the volume, similarly to a normal window in Apple Vision Pro 

### Slicer and OpenIGTLink Integration

Surgery View acts as a client to receive messages from an appropriate OpenIGTLink server (3D Slicer running on another computer, for example). Refer to [3D Slicer Documentation](https://slicer.readthedocs.io/en/latest/user_guide/getting_started.html), and the [OpenIGTLink Protocol Description](https://github.com/openigtlink/OpenIGTLink/blob/master/Documents/Protocol/index.md) for more details. 

In short, OpenIGTLink is a set of message formats along with a network communication interface provided through the [SDKs in C/C++, Python, and Java](http://openigtlink.org/developers/). 

Surgery View currently supports the following message types:
- POLYDATA: 3d models as a mesh 
- IMAGE: 3d DICOM that features CT or MRI scans, displaying them as slices
- TRANSFORM: 4x4 matrix for scale, rotation, and position data

# For Developers

## Install and running the program

If not already installed, download XCode 16 or later, then simply clone this repository and open it with XCode. You must set a valid development team in the project file first before running the code. You can connect to the Apple Vision Pro wirelessly, ensuring you are on the same network, or run the program inside the simulator.

Also install 3D Slicer and load the [corresponding module](https://github.com/Tony1324/surgeryViewSlicerModule) to transfer 3D data.

## Program Structure

Entry point is *surgeryViewApp.swift*, from here a MVVM like model is used, ModelData, using which the declarative views observe for changes.
**ModelData** controls all display of models and images, arranging views, layout functionality, and interaction with OpenIGTLink.
ModelManager.swift contains a RealityView which displays the models and images from ModelData, and responds to user gestures.
CommunicationsManager is initialized on program start, creating a TCP server that listens for messages from slicer. These messages are processed and again handed over to the ModelData class (a delegate).

